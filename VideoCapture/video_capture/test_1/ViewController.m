//
//  ViewController.m
//  test_1
//
//  Created by gg on 19/4/4.
//  Copyright © 2019年 gg. All rights reserved.
//
//
//  ViewController.m
//  test2
//
//  Created by gg on 19/4/8.
//  Copyright © 2019年 gg. All rights reserved.
//


#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)GetVideoAuthorization
{
    NSString *mediaType = AVMediaTypeVideo;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusAuthorized)
    {
        NSLog(@"GetVideoAuthorization Success.\n");
        
        return TRUE;
    }
    
    if(authStatus == AVAuthorizationStatusDenied)
    {
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if(granted)
            {
                NSLog(@"GetVideoAuthorization::requestAccessForMedia Success.\n");
            }else{
                NSLog(@"GetVideoAuthorization::requestAccessForMedia failed.\n");
            }
        }];
    }
    
    return TRUE;
}
-(IBAction)onClose:(id)sender
{
    [self.m_pVideoCapture StopCaputre];
    [self.m_pVideoCapture Close];
    
}
//
-(IBAction) OnButton:(id)obj
{
    NSLog(@"OnButton check Begin.\n");
    
//    dispatch_queue_t MainQueue = dispatch_get_main_queue();
//    
//    dispatch_async(MainQueue,^(void){
//        
//        NSLog(@"OnButton:: in dispatch_async\n");
//        
//        BOOL bre = [self GetVideoAuthorization];
//        if(TRUE == bre)
//        {
//            NSLog(@"GetViedoAuthorization success.\n");
//        }
//    });
    
    self.m_pView = [[UIImageView alloc]init];
    self.m_pView.frame = CGRectMake(0,400, 100, 100);
    [self.view addSubview:self.m_pView];
    
    self.m_pVideoCapture = [[VideoCapture alloc] Init];
    
    [self.m_pVideoCapture InitVideoCapture:self.m_pView];
    
    AVCaptureVideoPreviewLayer *preLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.m_pVideoCapture.m_pCaptureSession];
    
    preLayer.frame = CGRectMake(0, 0, 400, 400);
    preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.view.layer addSublayer:preLayer];
    
    [self.m_pVideoCapture StartCapture];
    
    NSLog(@"OnButton check End.\n");
}
@end
