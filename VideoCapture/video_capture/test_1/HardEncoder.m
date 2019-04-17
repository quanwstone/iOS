//
//  HardEncoder.m
//  Hard_Encoder
//
//  Created by gg on 19/4/16.
//  Copyright © 2019年 gg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import"HardEncoder.h"

void didCompressH264(void * outputCallbackRefCon,
                     void * ourceFrameRefCon,
                     OSStatus status,
                     VTEncodeInfoFlags infoFlags,
                     CMSampleBufferRef sampleBuffer)
{
    //判断编码返回值是否成功
    if(status != noErr)
    {
        NSLog(@"didCompressH264::staus=%d.\n",status);
        return;
    }
    //判断是否是完整帧
    if(!CMSampleBufferDataIsReady(sampleBuffer))
    {
        NSLog(@"didCompressH264::CMSampleBufferDataIsReady failed.\n");
        return;
    }
    HardEncoder *p = (__bridge HardEncoder *)outputCallbackRefCon;
    
    const char StatCode[]="\x00\x00\x00\x01";
    //判断是否是关键帧，如果是则需要添加sps和pps.
    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    const void *value = CFArrayGetValueAtIndex(array, 0);
    bool bKey = !CFDictionaryContainsKey(value, kCMSampleAttachmentKey_NotSync);
    
    int iLenSize = 0;
    if(bKey)//关键帧
    {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        //sps
        size_t spsSize =0,spsCount =0;
        const uint8_t *psps = NULL;
        
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,
                                                           0,
                                                           &psps,
                                                           &spsSize,
                                                           &spsCount,
                                                           0);
        memcpy(p.m_pChData + iLenSize,StatCode,4);
        iLenSize += 4;
        memcpy(p.m_pChData+ iLenSize,psps,spsSize);
        iLenSize += spsSize;
        
        //pps
        size_t ppsSize = 0,ppsCount = 0;
        const uint8_t* pps = NULL;
        
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,
                                                           1,
                                                           &pps,
                                                           &ppsCount,
                                                           &ppsSize,
                                                           0);
        memcpy(p.m_pChData+iLenSize,StatCode,4);
        iLenSize += 4;
        memcpy(p.m_pChData+iLenSize,pps,ppsSize);
        iLenSize += ppsSize;
    }
    
    size_t length =0,TotalLength =0;
    size_t bufferoffset = 0;
    
    char *dataPointer = NULL;

    //获取数据 ,返回的数据前四个字节是数据真实长度,为大端模式
    CMBlockBufferRef srcBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    
    CMBlockBufferGetDataPointer(srcBuffer, 0, &length, &TotalLength, &dataPointer);
    
    while(bufferoffset < TotalLength)
    {
        uint32_t NaluLen = 0;
        
        memcpy(&NaluLen,dataPointer + bufferoffset,4);//获取前四个字节
        NaluLen = CFSwapInt32BigToHost(NaluLen);//转换字节,获取真实数据长度
        
        char *pTemp = dataPointer + 4 + bufferoffset;
        
        memcpy(p.m_pChData + iLenSize,StatCode,4);
        iLenSize += 4;
        memcpy(p.m_pChData + iLenSize,pTemp,NaluLen);
        iLenSize += NaluLen;
       
        bufferoffset += 4 + NaluLen;
    }
    //保存data
    
}
@implementation HardEncoder

-(BOOL)initSession
{
    NSLog(@"InitSession.\n");
    
    _m_iWidth = 640;
    _m_iHeight = 480;
    _m_pChData = malloc(_m_iWidth*_m_iHeight*3);//存放编码后数据
    memset(_m_pChData,0,_m_iWidth*_m_iHeight*3);

    CMVideoCodecType codetype = kCMVideoCodecType_H264;
    
    //FourCharCode
    _m_Format = kCVPixelFormatType_420YpCbCr8PlanarFullRange;//yuv420p
    
    //设置原图像属性
    CFMutableDictionaryRef source_attrs = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    CFNumberRef number;
    
    number = CFNumberCreate(NULL, kCFNumberSInt16Type, &_m_iWidth);
    CFDictionarySetValue(source_attrs, kCVPixelBufferWidthKey, number);
    CFRelease(number);
    
    number = CFNumberCreate(NULL, kCFNumberSInt16Type, &_m_iHeight);
    CFDictionarySetValue(source_attrs, kCVPixelBufferHeightKey, number);
    CFRelease(number);
    
    
    number = CFNumberCreate(NULL, kCFNumberSInt16Type, &_m_Format);
    CFDictionarySetValue(source_attrs, kCVPixelBufferPixelFormatTypeKey, number);
    CFRelease(number);
    
    CFDictionarySetValue(source_attrs, kCVPixelBufferOpenGLESCompatibilityKey, kCFBooleanTrue);
    //创建编码器session
    
    OSStatus  status = VTCompressionSessionCreate(NULL,
                                                  _m_iWidth,
                                                  _m_iHeight,
                                                  codetype,
                                                  NULL,
                                                  source_attrs,
                                                  NULL,
                                                  didCompressH264,
                                                  (__bridge void * _Nullable)(self),
                                                  &_m_pCompression);
    if(status != noErr)
    {
        NSLog(@"VTCompressionCreate Failed.\n");
        return FALSE;
    }
    
    
    return TRUE;
}
-(BOOL)Close
{
    VTCompressionSessionCompleteFrames(_m_pCompression, kCMTimeInvalid);
    
    VTCompressionSessionInvalidate(_m_pCompression);
    
    free(_m_pChData);
    _m_pChData = NULL;
    
    
    return TRUE;
}
-(BOOL)SetPramater
{
    NSLog(@"SetPramater.\n");
    
    int nFPS = 15;
    
    //FPS
    
    CFNumberRef fpsRef = CFNumberCreate(NULL, kCFNumberIntType, &nFPS);
    VTSessionSetProperty(self.m_pCompression,
                         kVTCompressionPropertyKey_ExpectedFrameRate,
                         fpsRef);
    CFRelease(fpsRef);
    
    //rate
    int bitRate = _m_iWidth * _m_iHeight * 3;
    CFNumberRef rate = CFNumberCreate(NULL, kCFNumberSInt32Type, &bitRate);
    VTSessionSetProperty(self.m_pCompression,
                         kVTCompressionPropertyKey_AverageBitRate,
                         rate);
    CFRelease(rate);
    
    //流配置
    VTSessionSetProperty(self.m_pCompression,
                         kVTCompressionPropertyKey_ProfileLevel,
                         kVTProfileLevel_H264_High_AutoLevel);
    
//    VTSessionSetProperty(self.m_pCompression,
//                         kVTCompressionPropertyKey_Depth,
//                         kCMPixelFormat_24RGB);
    
    VTSessionSetProperty(self.m_pCompression,
                         kVTCompressionPropertyKey_H264EntropyMode,
                         kVTH264EntropyMode_CABAC);
    //
    VTSessionSetProperty(self.m_pCompression, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    //帧相关
    //是否启用帧重新排序.
    VTSessionSetProperty(self.m_pCompression, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    //关键帧之间最大间隔，也称为关键帧速率
    int iGop = 30;
    CFNumberRef igop = CFNumberCreate(NULL, kCFNumberIntType, &igop);
    
    VTSessionSetProperty(self.m_pCompression,
                         kVTCompressionPropertyKey_MaxKeyFrameInterval,
                         igop);
    CFRelease(igop);
    //提示当前帧是否被强制成关键帧该参数可在编码时实时插入.
    //kVTEncodeFrameOptionKey_ForceKeyFrame
    
    
    //启用设置参数
    OSStatus status = VTCompressionSessionPrepareToEncodeFrames(self.m_pCompression);
    if(status != noErr)
    {
        NSLog(@"VTCompressionSessionPrepareEncodeFrame Failed.\n");
        return FALSE;
    }
    
    
    return TRUE;
}
-(BOOL)StartEncode:(char *)pSrc Len:(int)iSrcLen
{
    NSLog(@"StartEncode.\n");
    
    BOOL bre_Key = TRUE;
    OSStatus status = noErr;
    
    CVPixelBufferRef imageBuffer = NULL;
    CMTime presentationts;
    VTEncodeInfoFlags flags;
    //创建关键帧
    CFMutableDictionaryRef frame_property = CFDictionaryCreateMutable(NULL,
                                                               0,
                                                               &kCFTypeDictionaryKeyCallBacks,
                                                               &kCFTypeDictionaryValueCallBacks);
    if(bre_Key)
    {
        CFDictionaryAddValue(frame_property,
                             kVTEncodeFrameOptionKey_ForceKeyFrame,
                             kCFBooleanTrue);
    }else{
        CFDictionaryAddValue(frame_property,
                             kVTEncodeFrameOptionKey_ForceKeyFrame,
                             kCFBooleanFalse);
    }
    //设置sample关联的时间
    _m_i64FrameCount += 1;
    presentationts = CMTimeMake(self.m_i64FrameCount, 1000);
    
    //设置输入数据创建用于cpu和gpu之间的共享内存cvpixelbufferref
    NSDictionary *pixelio = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
    
    CVReturn reslut = CVPixelBufferCreate(kCFAllocatorDefault,
                                          _m_iWidth,
                                          _m_iHeight,
                                          _m_Format,
                                          (__bridge CFDictionaryRef _Nullable)(pixelio),
                                          &imageBuffer);
    if(reslut != kCVReturnSuccess)
    {
        NSLog(@"CVPixelBufferCreate Failed.\n");
        //return
    }
    //数据拷贝 yuv420p
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    uint8_t *y = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    uint8_t *u = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    uint8_t *v = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 2);
    
    memcpy(y,pSrc,_m_iHeight * _m_iWidth);
    memcpy(u,pSrc + _m_iHeight * _m_iWidth,_m_iHeight * _m_iWidth / 4);
    memcpy(v,pSrc + _m_iHeight * _m_iWidth * 5 / 4,_m_iHeight * _m_iWidth / 4);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    
    //编码
    status = VTCompressionSessionEncodeFrame(self.m_pCompression,
                                             imageBuffer,
                                             presentationts,
                                             kCMTimeInvalid,
                                             frame_property,
                                             NULL,
                                             &flags);
    if(status == noErr)
    {
        NSLog(@"VTCompressionSessionEncodeFrame Success.\n");
    }else{
        NSLog(@"VTCompressionSessionEncodeFrame Failed.\n");
    }
    
    CFRelease(frame_property);
    
    return TRUE;
}
-(BOOL)WriteFile:(char *)pData Len:(int)iLen
{
    return TRUE;
}
@end



















