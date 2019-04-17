//
//  VideoCapture.m
//  test_1
//
//  Created by gg on 19/4/4.
//  Copyright © 2019年 gg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import"VideoCapture.h"

@implementation VideoCapture

-(VideoCapture *)Init
{
    NSLog(@"VideoCapture Init:: Begin\n");
    
    VideoCapture *p = [VideoCapture new];
    
    return p;
}
-(BOOL)InitVideoCapture:(UIImageView *)p
{
    NSLog(@"VideoCapture::InitVideoCapture Begin.\n");
    
    self.m_pViewController = p;
    self.m_pNV12Data = NULL;
    
    self.m_pEncoder = [[HardEncoder alloc]init];
    
    [self.m_pEncoder initSession];
    [self.m_pEncoder SetPramater];
    
    //创建session，avcapturesession是用于链接input和output
    AVCaptureSession *lpCaptureSession = [[AVCaptureSession alloc]init];
    if(nil == lpCaptureSession)
    {
        NSLog(@"InitVideoCapture::Session Failed.\n");
        return FALSE;
    }
    
    self.m_pCaptureSession = lpCaptureSession;
    
    //创建output,基类为avcaptureoutput,接收采集的数据并进行处理
    AVCaptureVideoDataOutput *lpOutput = [[AVCaptureVideoDataOutput alloc]init];
    if(nil == lpOutput)
    {
        NSLog(@"InitVideoCapture::Output Failed.\n");
        return FALSE;
    }
    
    if(FALSE == [lpCaptureSession canAddOutput:lpOutput])
    {
        NSLog(@"InitVideoCapture::AddOutput Failed.\n");
        return FALSE;
    }
    //设备默认采集的是nv12[y..uv uv],设置yuv420采集失败
    
//    NSMutableDictionary *lpSettings = [[NSMutableDictionary alloc]init];
//    
//    [lpSettings setObject:[NSNumber numberWithUnsignedInteger:kCVPixelFormatType_32BGRA]
//                   forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//    
//    lpOutput.videoSettings = lpSettings;
    
    [lpCaptureSession addOutput:lpOutput];
    
    self.m_pOutput = lpOutput;
    
    dispatch_queue_t VideoQueue = dispatch_queue_create("VideoCapture",NULL);
    
    [lpOutput setSampleBufferDelegate:self queue:VideoQueue];
    
    [self SetCameraPosition];
    
    return TRUE;
}
//关闭之前需要先停止采集
-(BOOL)Close
{
    NSLog(@"Close.\n");
    
    NSArray *lpDeviceInput = [self.m_pCaptureSession inputs];
    //移除输入设备
    for(AVCaptureDeviceInput *lpInput in lpDeviceInput)
    {
        [self.m_pCaptureSession removeInput:lpInput];
    }
    
    return TRUE;
}
-(BOOL)SetCameraPosition
{
    NSLog(@"SetCameraPosition::Begin.\n");
    
    //获取一个采集设备，前置后置摄像头
    AVCaptureDevice *lpCaptureDevice = NULL;
    
    NSArray *lpDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    for(AVCaptureDevice *pDevice in lpDevices)
    {
        if([pDevice position] == AVCaptureDevicePositionFront)
        {
            lpCaptureDevice = pDevice;
            break;
        }
        if([pDevice position] == AVCaptureDevicePositionBack)
        {
            lpCaptureDevice = pDevice;
            break;
        }
    }
    //
    AVCaptureDeviceInput *pCaptureInput = [AVCaptureDeviceInput deviceInputWithDevice:lpCaptureDevice error:nil];
    if(pCaptureInput == nil)
    {
        NSLog(@"SetCameraPosition::CaptureInput Faile.\n");
    }
    if(NO == [self.m_pCaptureSession canAddInput:pCaptureInput])
    {
        NSLog(@"SetCameraPosition::AddInput Failed.\n");
    }
    
    [self.m_pCaptureSession addInput:pCaptureInput];
    //综上采集设备和输出设备都已经添加到session内部，接下来设置采集参数即可
    
    [self SetCaptureSize:640 Height:480 AVCaptureDevice:lpCaptureDevice];
    
    [self SetCaptureFPS:15 AVCaptureDevice:lpCaptureDevice];
    
    
    return TRUE;
}
-(BOOL)SetCaptureSize:(int)W Height:(int)H AVCaptureDevice:(AVCaptureDevice *)lpDevice
{
    NSLog(@"SetCaptureSize::width=%d,height=%d\n",W,H);
    
    AVCaptureDeviceFormat *lpFormat = NULL;
    
    for(AVCaptureDeviceFormat *pF in lpDevice.formats)
    {
        CMVideoDimensions lDimesions = CMVideoFormatDescriptionGetDimensions(pF.formatDescription);
        if(lDimesions.width == W &&lDimesions.height == H)
        {
            NSLog(@"SetCaptureSize::GetDimensions.\n");
            lpFormat = pF;
            break;
        }
        
        NSLog(@"SetCaptureSize::Dimensions width=%d height=%d\n",lDimesions.width,lDimesions.height);
    }
    
    [lpDevice lockForConfiguration:nil];
    [lpDevice setActiveFormat:lpFormat];
    [lpDevice unlockForConfiguration];
    
    return TRUE;
}
-(BOOL)SetCaptureFPS:(int)Fps AVCaptureDevice:(AVCaptureDevice *)lpDevice
{
    NSLog(@"SetCapture FPS=%d.\n",Fps);
    
    AVFrameRateRange *lpRate = [lpDevice.activeFormat.videoSupportedFrameRateRanges firstObject];
    NSLog(@"SetCaptureFPS::AVFrameRateRange FPS=%d,minRate=%f,maxRate=%f\n",Fps,lpRate.minFrameRate,lpRate.maxFrameRate);
    
    CMTime loFrameTime = lpRate.minFrameDuration;
    loFrameTime.timescale = Fps;
    
    [lpDevice lockForConfiguration:nil];
    [lpDevice setActiveVideoMinFrameDuration:loFrameTime];
    [lpDevice setActiveVideoMaxFrameDuration:loFrameTime];
    [lpDevice unlockForConfiguration];
    
    return TRUE;
}
-(BOOL) StartCapture
{
    NSLog(@"StartCapture.\n");
    
    [self.m_pCaptureSession startRunning];
    
    return TRUE;
}
-(BOOL) StopCaputre
{
    NSLog(@"StopCapture.\n");
    
    [self.m_pCaptureSession stopRunning];
    
    return TRUE;
}
//
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef lpPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if(NO == CVPixelBufferIsPlanar(lpPixelBuffer))
    {
        NSLog(@"BGRA.\n");
        
        UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.m_pViewController.image = image;
        });

    }else//解析nv12
    {
        [self DealNv12:lpPixelBuffer];
    }
}
-(BOOL)DealNv12:(CVPixelBufferRef)srcBuf
{
    //获取planar个数
    size_t PlanarCount = CVPixelBufferGetPlaneCount(srcBuf);
    if(PlanarCount != 2)
    {
        NSLog(@"CVPixelBufferGetPlaneCount Failed=%d.\n",(int)PlanarCount);
        return FALSE;
    }
    //读取数据
    CVPixelBufferLockBaseAddress(srcBuf, 0);
    

    size_t H = CVPixelBufferGetHeightOfPlane(srcBuf, 0);
    size_t W = CVPixelBufferGetWidthOfPlane(srcBuf, 0);
    
    if(self.m_pNV12Data == NULL)
    {
        _m_iNV12Len = H * W * 3/2;
        
        self.m_pNV12Data = malloc(_m_iNV12Len);
    }
    
    char *py = CVPixelBufferGetBaseAddressOfPlane(srcBuf, 0);//y
    char *puv = CVPixelBufferGetBaseAddressOfPlane(srcBuf, 1);//uv
    
    memcpy(self.m_pNV12Data,py,H*W);
    memcpy(self.m_pNV12Data + H*W,puv,H*W / 2);
    
    CVPixelBufferUnlockBaseAddress(srcBuf, 0);
    
    [self.m_pEncoder StartEncode:self.m_pNV12Data Len:_m_iNV12Len];
    
    return TRUE;
}
-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    return (image);

}
@end
