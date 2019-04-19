//
//  ModeThread.h
//  nscopy
//
//  Created by gg on 19/4/18.
//  Copyright © 2019年 gg. All rights reserved.
//

#ifndef ModeThread_h
#define ModeThread_h

//pthread NSThread GCD NSOpreation
@interface Mode_Thread:NSObject

-(BOOL)StartThread;
-(BOOL)StartThead_Operation;
-(BOOL)StartThread_gcd;


-(void)dosomsing:(id)p;
-(void)dosomsing2;
-(void)dosomsing3;

@end

@interface Thread_Operation:NSOperation
-(void)main;
-(void) OnCallBack2;
@end

#endif /* ModeThread_h */
