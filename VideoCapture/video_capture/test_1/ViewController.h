//
//  ViewController.h
//  test_1
//
//  Created by gg on 19/4/4.
//  Copyright © 2019年 gg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import"VideoCapture.h"

@interface ViewController : UIViewController

-(IBAction)OnButton:(id)obj;

-(BOOL)GetVideoAuthorization;

@property (nonatomic)VideoCapture *m_pVideoCapture;

@property(nonatomic,strong)UIImageView *m_pView;

@end

