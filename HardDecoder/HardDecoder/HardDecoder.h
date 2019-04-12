//
//  HardDecoder.h
//  HardDecoder
//
//  Created by gg on 19/4/11.
//  Copyright © 2019年 gg. All rights reserved.
//

#ifndef HardDecoder_h
#define HardDecoder_h

#import<VideoToolbox/VideoToolbox.h>

@interface HardDecoder:NSObject

-(BOOL)Init;

-(BOOL)Decode:(char *)psrc//原始数据
       SrcLen:(int)iSrc//原始数据长度
    DestDataL:(char *)pdest//解码后数据
      DestLen:(int)iDest;//解码后数据长度
                        

-(BOOL)GetNalu:(char *)psrc//数据首地址
        SrcLen:(int)iSrc//数据的总长度
       StartLen:(int*)iStart//起始位置
         pDest:(char **)pDest//找到的nalu起始位置
       NaluLen:(int*)iNalu;//找到的nalu长度

-(void)CloseDecode;

@property(nonatomic)VTDecompressionSessionRef m_pDecoderSession;
@property(nonatomic)CMVideoFormatDescriptionRef m_pDecodeFormatDescription;
@property(nonatomic)uint8_t *m_psps;
@property(nonatomic)uint8_t *m_ppps;
@property(nonatomic)size_t m_sps;
@property(nonatomic)size_t m_pps;
@property(nonatomic)char *m_pDataBuffer;
@end


#endif /* HardDecoder_h */
