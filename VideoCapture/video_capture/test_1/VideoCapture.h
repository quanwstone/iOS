//
//  VideoCapture.h
//  test_1
//
//  Created by gg on 19/4/4.
//  Copyright © 2019年 gg. All rights reserved.
//

#ifndef VideoCapture_h
#define VideoCapture_h

#import<UIKit/UIKit.h>
#import<AVFoundation/AVFoundation.h>

@interface VideoCapture:NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>

-(BOOL)InitVideoCapture:(UIImageView *)pView;

-(BOOL)StartCapture;

-(BOOL)StopCaputre;

-(BOOL)SetCameraPosition;

-(BOOL)SetCaptureSize:(int)W Height:(int)H AVCaptureDevice:(AVCaptureDevice *)lpDevice;

-(BOOL)SetCaptureFPS:(int)Fps AVCaptureDevice:(AVCaptureDevice*)lpDevice;

-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

-(VideoCapture*)Init;

@property(nonatomic)UIImageView *m_pViewController;

@property(nonatomic) AVCaptureSession *m_pCaptureSession;

@property(nonatomic)AVCaptureVideoDataOutput *m_pOutput;

@end

#endif /* VideoCapture_h */
