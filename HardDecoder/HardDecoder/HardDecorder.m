//
//  HardDecorder.m
//  HardDecoder
//
//  Created by gg on 19/4/11.
//  Copyright © 2019年 gg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import"HardDecoder.h"

@implementation HardDecoder
static void didDecompress(void *  decompressionOutputRefCon,
                          void *  sourceFrameRefCon,
                          OSStatus status,
                          VTDecodeInfoFlags infoFlags,
                          CVImageBufferRef imageBuffer,
                          CMTime presentationTimeStamp, 
                          CMTime presentationDuration )
{
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(imageBuffer);
}
-(BOOL)Init
{
    NSLog(@"HardDecoder::Init.\n");
    
    if(_m_pDecodeFormatDescription != NULL)
    {
        NSLog(@"Init Success again.\n");
        return 0;
    }
    //
    _m_pDataBuffer = malloc(1920 *1080);
    memset(_m_pDataBuffer,0,1920*1080);
    
    //初始化硬解参数，提取sps和pps，
    const uint8_t *const parameterSetPointer[2]={_m_psps,_m_ppps};
    size_t parameterSetSize[2]={_m_sps,_m_pps};
    
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2,
                                                                          parameterSetPointer,
                                                                          parameterSetSize,
                                                                          4, &_m_pDecodeFormatDescription);
    if(status == noErr)
    {
        
        //创建session
        CFDictionaryRef attrs = NULL;
        
        const void *key[]={kCVPixelBufferPixelFormatTypeKey};
        uint32_t v = kCVPixelFormatType_420YpCbCr8Planar;
        
        const void *values[] ={CFNumberCreate(NULL, kCFNumberSInt32Type, &v)};
        
        attrs = CFDictionaryCreate(NULL, key, values, 1, NULL, NULL);
        
        //设置回调函数.在解码时会调用该回调函数.
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputRefCon = NULL;
        callBackRecord.decompressionOutputCallback = didDecompress;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _m_pDecodeFormatDescription,
                                              NULL,
                                              attrs,
                                              &callBackRecord,
                                              &_m_pDecoderSession);
        CFRelease(attrs);
        if(status == noErr)
        {
            NSLog(@"VTDecompressionSessionCreate Success.\n");
            
        }
        
    }else{
        NSLog(@"CMVideoFormatDescriptionCreateFromH264ParameterSets Failed.\n");
        return FALSE;
    }
    return TRUE;
}
-(BOOL)Decode:(char *)psrc//原始数据
       SrcLen:(int)iSrc//原始数据长度
    DestDataL:(char *)pdest//解码后数据
      DestLen:(int)iDest//解码后数据长度
{
    NSLog(@"Decoder\n");
    
    int iStartLen = 0,iNalu = 0,iDataLen = 0;
    char *pDest = NULL;
    //查找nalu
    while([self GetNalu:psrc SrcLen:iSrc StartLen:&iStartLen pDest:&pDest NaluLen:&iNalu])
    {
        //ios解码，解码器需要接收的是mp4格式，每个包的头4个字节需要是big－endian的size，不是起始字符.
        int nalType = pDest[0] & 0x1F;
        char *pNaluLen = (char *)&iNalu;
        
        switch(nalType)
        {
            case 0x05://I
                
                _m_pDataBuffer[iDataLen] = *(pNaluLen + 3);
                _m_pDataBuffer[iDataLen+ 1] = *(pNaluLen + 2);
                _m_pDataBuffer[iDataLen + 2] = *(pNaluLen + 1);
                _m_pDataBuffer[iDataLen + 3] = *(pNaluLen);
                
                memcpy(_m_pDataBuffer+iDataLen, pDest, iNalu);
                
                iDataLen = iDataLen+ 4+ iNalu;
                
                if([self Init])//根据获取的sps和pps创建decodersession
                {
                    
                }
                break;
            case 0x07://SPS
                
                _m_sps = iNalu;
                
                if(_m_psps)
                {
                    free(_m_psps);
                }
                _m_psps = malloc(_m_sps);
                
                memcpy(_m_psps, pDest, iNalu);
                
                break;
            case 0x08://pps
                
                _m_pps = iNalu;
                
                if(_m_ppps)
                {
                    free(_m_ppps);
                }
                _m_ppps = malloc(_m_pps);
                
                memcpy(_m_ppps, pDest, iNalu);
                break;
            default:
                break;
        }
    }
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    
    //构造cmblockbuffer
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, (void *)_m_pDataBuffer, iDataLen, kCFAllocatorNull, NULL, 0, iDataLen, 0, &blockBuffer);
    if(status == kCMBlockBufferNoErr)
    {
        CMSampleBufferRef sampleBuffer = NULL;
        
        const size_t sampleSizeArray[]={iDataLen};
        
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _m_pDecodeFormatDescription,
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
            //解码,传递回调函数参数,frameflags不设置，则在回调结束后该decodeframe方法才会返回.
            status = VTDecompressionSessionDecodeFrame(_m_pDecoderSession,
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
    return TRUE;
}
-(void)CloseDecode
{
    if(_m_pDecoderSession)
    {
        VTDecompressionSessionInvalidate(_m_pDecoderSession);
        CFRelease(_m_pDecoderSession);
        _m_pDecoderSession = NULL;
    }
    if(_m_pDecodeFormatDescription)
    {
        CFRelease(_m_pDecodeFormatDescription);
        _m_pDecodeFormatDescription = NULL;
    }
    
    if(_m_pDataBuffer != NULL)
        free(_m_pDataBuffer);
    
    if(_m_ppps != NULL)
        free(_m_ppps);
    
    if(_m_psps != NULL)
        free(_m_psps);
    
}
-(BOOL)GetNalu:(char *)psrc
        SrcLen:(int)iSrc    //原始数据总长
      StartLen:(int*)iStart//起始位置
         pDest:(char **)pDest//找到的nalu起始位置
       NaluLen:(int*)iNalu;//找到的nalu长度
{
    NSLog(@"GetNalu.\n");
    
    const uint8_t kStartCode[4]={0,0,0,1};
    const uint8_t kStartCode2[3]={0,0,1};
    
    int iStartcode = 0;
    int iNaluLen = 0;
    int iBegin = *iStart;
    int iEnd = iSrc;

    //判断是否超过最大长度
    if(iBegin==iEnd || iBegin>iEnd)
    {
        NSLog(@"GetNalu::iStart>iSrc.\n");
        return FALSE;
    }
    //判断起始字节
    if(memcmp(psrc + iBegin, kStartCode, 4) == 0)
    {
        iStartcode = 4;
    }
    if(memcmp(psrc + iBegin, kStartCode2, 3) == 0)
    {
        iStartcode = 3;
    }
    
    if(!iStartcode)
    {
        NSLog(@"GetNalu::Header not startCode.\n");
        return FALSE;
    }
   
    //获得开始查找位置
    char *pSrcTemp = psrc + iBegin + iStartcode;
    char *pSrcNaluBegin = pSrcTemp;
    
    //查找下一个起始字节的位置
    while(iNaluLen < iEnd - iBegin - iStartcode)
    {
        if((pSrcTemp[iNaluLen]) == 0x01)
        {
            if(memcmp(pSrcTemp - 3, kStartCode2, 3) == 0)
            {
                iNaluLen -= 3;
                
                break;
            }
            if(memcmp(pSrcTemp - 4, kStartCode, 4) == 0)
            {
                iNaluLen -= 4;
                
                break;
            }
        
        }
        NSLog(@"Buf = %x.\n",pSrcTemp[iBegin]);
        
        iNaluLen++;
    }
    
    *iNalu = iNaluLen;
    *pDest = pSrcNaluBegin;
    *iStart = iBegin + iStartcode + iNaluLen;
    
    return TRUE;
}






































@end
