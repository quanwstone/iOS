//
//  ViewController.m
//  audiocapture
//
//  Created by gg on 19/4/10.
//  Copyright © 2019年 gg. All rights reserved.
//

#import "ViewController.h"
#import<AVFoundation/AVFoundation.h>

@interface ViewController ()

@property(nonatomic) AudioQueueRef m_pAudioQueue;
@property(nonatomic)AudioQueueBufferRef m_pAudioBuffer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(BOOL)InitAudioCapture
{
    NSLog(@"InitAudioCapture Begin.\n");
    
    AudioStreamBasicDescription loAudioFormat;
    memset(&loAudioFormat,0,sizeof(AudioStreamBasicDescription));
    
    //采样格式pcm
    loAudioFormat.mFormatID = kAudioFormatLinearPCM;
    loAudioFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger;
    
    //采样率
    loAudioFormat.mSampleRate = 44100;
    //通道数
    loAudioFormat.mChannelsPerFrame = 2;
    //量化参数
    loAudioFormat.mBitsPerChannel = 16;
    //每帧字节数
    loAudioFormat.mBytesPerFrame = (loAudioFormat.mBitsPerChannel / 8)*loAudioFormat.mChannelsPerFrame;
    //设置每包有多少帧
    loAudioFormat.mFramesPerPacket = 1;
    
    loAudioFormat.mBytesPerPacket = loAudioFormat.mBytesPerFrame * loAudioFormat.mFramesPerPacket;
    
    //设置audiosession执行类型并激活
    AVAudioSession *lpSession = [AVAudioSession sharedInstance];
    
    [lpSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [lpSession setActive:TRUE error:nil];
    
    //设置回调函数，创建音频队列对象
    AudioQueueRef lpAudioQueue = NULL;
    
    int iR = AudioQueueNewInput(&loAudioFormat, AudioInputCallBack,(__bridge void * )(self) , nil, kCFRunLoopCommonModes, 0, &lpAudioQueue);
    if(0 != iR || NULL == lpAudioQueue)
    {
        NSLog(@"AudioQueueNewInput Failed.\n");
    }
    self.m_pAudioQueue = lpAudioQueue;
    
    AudioQueueAllocateBuffer(lpAudioQueue, 8192, &_m_pAudioBuffer);//
    AudioQueueEnqueueBuffer(lpAudioQueue, _m_pAudioBuffer, 0, NULL);
    
    
    
    return TRUE;
}
-(BOOL)StartAudioCapture
{
    NSLog(@"StartAudioCapture.\n");
    
    AudioQueueStart(self.m_pAudioQueue, nil);
    
    return TRUE;
}
static void AudioInputCallBack(
                               void *                inUserData,
                               AudioQueueRef                   inAQ,
                               AudioQueueBufferRef             inBuffer,
                               const AudioTimeStamp *          inStartTime,
                               UInt32                          inNumberPacketDescriptions,
                               const AudioStreamPacketDescription *  inPacketDescs)
{
    int iDataSize = inBuffer->mAudioDataByteSize;
    if(0 == iDataSize)
    {
        //添加buffer到音频队列，用于下次录音
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil);
        
        NSLog(@"AudioInputCallBack:: DataSis ==0.\n");
        
        return ;
    }
    if(NULL == inUserData)
    {
        NSLog(@"AudioInputCallBack::inUserData is NULL.\n");
        return ;
    }
    
    ViewController *p = (__bridge ViewController *)inUserData;
    
    [p DealAudioBuf:inBuffer];
    
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil);
    
}
-(BOOL) DealAudioBuf:(AudioQueueBufferRef )pBuffer
{
    
    NSLog(@"DealAudiBuff Len=%d.\n",pBuffer->mAudioDataByteSize);
    
    //读取的路径是path
    NSArray * lpPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * lpDocumentsDirectory = [lpPaths objectAtIndex:0];
    
    NSMutableString * lpFilePath = [[NSMutableString alloc]initWithString:lpDocumentsDirectory];
    [lpFilePath appendString:@"/Audio.wav"];
    
    NSLog(@"Path=%@\n",lpFilePath);
    
    NSMutableData * lpWriterFile = [[NSMutableData alloc] initWithContentsOfFile:lpFilePath options:NSDataReadingUncached error:nil];
    if (nil == lpWriterFile)
    {
        lpWriterFile = [[NSMutableData alloc] init];
    }
    
    //写入音频数据，直接写入，不需要转换
    [lpWriterFile appendBytes:pBuffer->mAudioData length:pBuffer->mAudioDataByteSize];
    [lpWriterFile writeToFile:lpFilePath atomically:YES];

    
    return TRUE;
}
-(IBAction)OnButton:(id)sender
{
    NSLog(@"OnButton Begin.\n");
//    
    [self InitAudioCapture];
    [self StartAudioCapture];
    
}
@end
