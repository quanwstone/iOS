//
//  HardDecoder.cpp
//  HardDecoder
//
//  Created by gg on 19/4/12.
//  Copyright © 2019年 gg. All rights reserved.
//

#include "HardDecodercplus.h"

CHardDecoder::CHardDecoder()
{
    m_ppps = nullptr;
    m_psps = nullptr;
    
    m_pDataBuffer = new char[DEF_BUF_LEN];
    memset(m_pDataBuffer,0,DEF_BUF_LEN);
    
    
}

CHardDecoder::~CHardDecoder()
{
    
}

int CHardDecoder::Decode(
                          char *psrc,//原始数据
                          int iSrc,//原始数据长度
                          char *pDest,//解码后数据
                          int iDest//解码后数据长度
)
{
    
    int iStartLen = 0,iNalu = 0,iDataLen = 0;
    char *pDestTemp = NULL;
    //查找nalu
    while( GetNalu(psrc,iSrc,iStartLen,pDestTemp,iNalu))
    {
        //ios解码，解码器需要接收的是mp4格式，每个包的头4个字节需要是big－endian的size，不是起始字符.
        int nalType = pDest[0] & 0x1F;
        char *pNaluLen = (char *)&iNalu;
        
        switch(nalType)
        {
            case 0x05://I
                
                m_pDataBuffer[iDataLen] = *(pNaluLen + 3);
                m_pDataBuffer[iDataLen+ 1] = *(pNaluLen + 2);
                m_pDataBuffer[iDataLen + 2] = *(pNaluLen + 1);
                m_pDataBuffer[iDataLen + 3] = *(pNaluLen);
                
                memcpy(m_pDataBuffer+iDataLen, pDest, iNalu);
                
                iDataLen = iDataLen+ 4+ iNalu;
                
                if(CreateSession())//根据获取的sps和pps创建decodersession
                {
                    
                }
                break;
            case 0x07://SPS
                
                m_sps = iNalu;
                
                if(m_psps)
                {
                    free(m_psps);
                }
                m_psps = new uint8_t[m_sps];
                
                memcpy(m_psps, pDest, iNalu);
                
                break;
            case 0x08://pps
                
                m_pps = iNalu;
                
                if(m_ppps)
                {
                    free(m_ppps);
                }
                m_ppps = new uint8_t[m_pps];
                
                memcpy(m_ppps, pDest, iNalu);
                break;
            default:
                break;
        }
    }
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    
    //构造cmblockbuffer
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, (void *)m_pDataBuffer, iDataLen, kCFAllocatorNull, NULL, 0, iDataLen, 0, &blockBuffer);
    if(status == kCMBlockBufferNoErr)
    {
        CMSampleBufferRef sampleBuffer = NULL;
        
        const size_t sampleSizeArray[]={static_cast<size_t>(iDataLen)};
        
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           m_pDecodeFormatDescription,
                                           1,
                                           0,
                                           NULL,
                                           1,
                                           sampleSizeArray,
                                           &sampleBuffer);
        if(status == kCMBlockBufferNoErr &&sampleBuffer)
        {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            
            status = VTDecompressionSessionDecodeFrame(m_pDecoderSession,
                                                       sampleBuffer,
                                                       flags,
                                                       &outputPixelBuffer,
                                                       &flagOut);
            
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    
    //解析outputpixbuf数据获取yuv.
    if(outputPixelBuffer)
    {
        CVPixelBufferLockBaseAddress(outputPixelBuffer, 0);
        int apWidth = (int)CVPixelBufferGetWidth(outputPixelBuffer);
        int apHeight = (int)CVPixelBufferGetHeight(outputPixelBuffer);
        
        char *yuv420pData = (char *)CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 0);
        memcpy(pDest, yuv420pData, apWidth * apHeight);
        
        char *yuv420pDataR = (char *)CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 1);
        memcpy(pDest + apWidth * apHeight, yuv420pDataR, apWidth * apHeight/4);
        
        char *yuv420pDataB = (char *)CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 2);
        memcpy(pDest + apWidth * apHeight + apWidth * apHeight/4, yuv420pDataB, apWidth * apHeight/4);
        
        CVPixelBufferUnlockBaseAddress(outputPixelBuffer, 0);
        CVPixelBufferRelease(outputPixelBuffer);
        
    }

    return 0;
}
int CHardDecoder::CreateSession()
{
    
    return 0;
}
int CHardDecoder::GetNalu(char *psrc,
                          int iSrc,
                          int iStart,
                          char *pDest,
                          int iNalu)
{
 
    const uint8_t kStartCode[4]={0,0,0,1};
    const uint8_t kStartCode2[3]={0,0,1};
    
    int iStartcode = 0;
    int iNaluLen = 0;
    
    //判断是否超过最大长度
    if(iStart==iSrc || iStart>iSrc)
    {
        return FALSE;
    }
    //判断起始字节
    if(memcmp(psrc, kStartCode, 4) == 0)
    {
        iStartcode = 4;
    }
    if(memcmp(psrc, kStartCode2, 3) == 0)
    {
        iStartcode = 3;
    }
    
    if(!iStartcode)
    {
        return FALSE;
    }
    
    //获得开始查找位置
    char *pSrcTemp = psrc + iStart + iStartcode;
    char *pSrcNaluBegin = pSrcTemp;
    
    //查找下一个起始字节的位置
    while(iStart < iSrc)
    {
        if((pSrcTemp[iStart]) == 0x01)
        {
            if(memcmp(pSrcTemp - 3, kStartCode2, 3) == 0)
            {
                
                break;
            }
            if(memcmp(pSrcTemp - 4, kStartCode, 4) == 0)
            {
                break;
            }
            
        }
        
        iStart++;
        iNaluLen++;
    }
    
    iNalu = iNaluLen;
    pDest = pSrcNaluBegin;

    return 0;
}
