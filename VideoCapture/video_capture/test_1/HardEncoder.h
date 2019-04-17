//
//  HardEncoder.h
//  Hard_Encoder
//
//  Created by gg on 19/4/16.
//  Copyright © 2019年 gg. All rights reserved.
//

#ifndef HardEncoder_h
#define HardEncoder_h

#import<Foundation/Foundation.h>
#import<VideoToolbox/VideoToolbox.h>

@interface HardEncoder:NSObject

-(BOOL)initSession;
-(BOOL)SetPramater;
-(BOOL)StartEncode:(char *)pSrc
               Len:(int)iSrcLen;
-(BOOL)Close;
-(BOOL)WriteFile:(char *)pData
             Len:(int)iLen;

@property VTCompressionSessionRef m_pCompression;
@property int32_t m_iWidth;
@property int32_t m_iHeight;
@property OSType  m_Format;
@property char*   m_pChData;
@property int64_t m_i64FrameCount;

@end


#endif /* HardEncoder_h */
