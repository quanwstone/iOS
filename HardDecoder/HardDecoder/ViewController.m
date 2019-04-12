//
//  ViewController.m
//  HardDecoder
//
//  Created by gg on 19/4/11.
//  Copyright © 2019年 gg. All rights reserved.
//

#import "ViewController.h"
#import"HardDecoder.h"

@interface ViewController ()

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

-(IBAction)OnButton:(id)sender
{
    FILE *pFile = NULL;
    
    HardDecoder *p = [[HardDecoder alloc]init ];
    
    
    pFile = fopen("/Users/gg/Documents/project_/test_2/1.264","r");
    if(NULL == pFile)
    {
        NSLog(@"fopen falied.\n");
    }
    char *buf = malloc(320*240);
    char *dest = malloc(320*240*3 / 2);
    int iDestLen = 0;
    
    int ire = fread(buf,1, 320*240, pFile);
    
    [p Decode:buf SrcLen:ire DestDataL:dest DestLen:iDestLen];
}
@end
