//
//  HardDecoder.hpp
//  HardDecoder
//
//  Created by gg on 19/4/12.
//  Copyright © 2019年 gg. All rights reserved.
//

#ifndef HardDecodercplus_h
#define HardDecodercplus_h

#include <stdio.h>
#include<VideoToolbox/VideoToolbox.h>

#define DEF_BUF_LEN     4*1024

class CHardDecoder
{
public:
    CHardDecoder();
    ~CHardDecoder();
    
public:
    int Decode(
    char *psrc,//原始数据
    int iSrc,//原始数据长度
    char *pDest,//解码后数据
    int iDest//解码后数据长度
    );
    
    int GetNalu(
    char *psrc,//数据首地址
    int iSrc,//数据的总长度
    int iStart,//起始位置
    char *pDest,//找到的nalu起始位置
    int iNalu //找到的nalu长度
    );
    
    int CreateSession();
    
    VTDecompressionSessionRef m_pDecoderSession;
    CMVideoFormatDescriptionRef m_pDecodeFormatDescription;
    uint8_t *m_psps;
    uint8_t *m_ppps;
    size_t m_sps;
    size_t m_pps;
    char *m_pDataBuffer;
};
#endif /* HardDecoder_hpp */
