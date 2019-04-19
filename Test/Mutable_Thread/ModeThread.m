//
//  ModeThread.m
//  nscopy
//
//  Created by gg on 19/4/18.
//  Copyright © 2019年 gg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ModeThread.h"

@implementation Thread_Operation

-(void)main
{
    NSLog(@"Thrad_Opreation=%@.",[NSThread currentThread]);
}

-(void) OnCallBack2
{
    NSLog(@"Thread_Operation::OnCallBack2 %@",[NSThread currentThread]);
    
}
@end


@implementation Mode_Thread

//NSThread
-(void)dosomsing:(id)p
{
    NSLog(@"dosomsing== %@",[NSThread currentThread]);
    
    //在主线程中调用该方法，可用于ui刷新
    [self performSelectorOnMainThread:@selector(OnCallBack) withObject:nil waitUntilDone:FALSE];
    
    //[p OnCallBack2];
    
    //在当前线程中调用该方法.
    [self performSelector:@selector(OnCallBack2)];
}
-(void)OnCallBack
{
    NSLog(@"OnCallBack== %@",[NSThread currentThread]);
}
-(void)OnCallBack2
{
    NSLog(@"OnCallBack2==%@",[NSThread currentThread]);
}
-(void)dosomsing2
{
    while(true)
    {
        NSLog(@"dosomsing2 %@",[NSThread currentThread]);
    }
}
-(void)dosomsing3
{
    while(true)
    {
        NSLog(@"dosomsing3 %@",[NSThread currentThread]);
    }
}
//NSOpreation
-(BOOL)StartThead_Operation
{
    NSLog(@"StartThread_Operation %@.\n",[NSThread currentThread]);
    
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    
    queue.maxConcurrentOperationCount = 3;
    
    //3
    Thread_Operation *p=[[Thread_Operation alloc]init];
    //[p start];
    [queue addOperation:p];
    
    //1
    NSInvocationOperation *opreation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(dosomsing:) object:p];
    //[opreation start];
    [queue addOperation:opreation];
    
    //2
    NSBlockOperation *opreation2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"Block %@.\n",[NSThread currentThread]);
    }];
    //[opreation2 start];
    [queue addOperation:opreation2];
    
    
    return TRUE;
}
//GCD
-(BOOL)StartThread_gcd
{
    NSLog(@"StartThead_gcd=%@.\n",[NSThread currentThread]);
    
    //串行
    //dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);
    
    //并行
    dispatch_queue_t queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
    
//    dispatch_async(queue, ^{
//        for(int i=0;i<10;i++)
//            NSLog(@"dispath_async1 %@",[NSThread currentThread]);
//    });
//    
//    dispatch_async(queue, ^{
//        for(int i=0;i<10;i++)
//            NSLog(@"dispath_async2 %@",[NSThread currentThread]);
//    });
    
    dispatch_sync(queue, ^{
        for(int i=0;i<10;i++)
          NSLog(@"dispatch_sync1 %@",[NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        for(int i=0;i<10;i++)
          NSLog(@"dispatch_sync2 %@",[NSThread currentThread]);
    });
    
    NSLog(@"StartThread_gcd End.\n");
    
    return TRUE;
}
//NSThread
-(BOOL)StartThread
{
    NSLog(@"StartThread NSThead %@.\n",[NSThread currentThread]);
    
    //
    [NSThread detachNewThreadSelector:@selector(dosomsing:) toTarget:self withObject:nil];
    
    //
    [self performSelectorInBackground:@selector(dosomsing3) withObject:nil];
    
    //
    NSThread *m_pThread = [[NSThread alloc] initWithTarget:self selector:@selector(dosomsing2) object:nil];
    
    [m_pThread start];
    
    return TRUE;
}













@end
