//
//  RC4Encryptor.m
//  XLFileDownloader
//
//  Created by Jason on 16/1/26.
//  Copyright © 2016年 Jason. All rights reserved.
//

#import "RC4Encryptor.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation RC4Encryptor
+ (NSData *)encryptorData:(NSData *)data withKey:(NSString *)key {
    NSData *inputData = [data mutableCopy];
    NSString *inputKey = [key mutableCopy];
    int blockSize = kCCBlockSizeRC2;
    
    uint8_t *bufferPtr1 = NULL;
    size_t bufferPtrSize1 = 0;
    size_t movedBytes1 = 0;
    unsigned char iv[8];
    memset(iv, 0, 8);
    bufferPtrSize1 = [inputData length] + blockSize;
    bufferPtr1 = malloc(bufferPtrSize1);
    memset((void *)bufferPtr1, 0, bufferPtrSize1);
    
    CCCryptorStatus ccStatus = CCCrypt(
                                       kCCEncrypt,
                                       kCCAlgorithmRC4,
                                       kCCOptionECBMode | kCCOptionPKCS7Padding ,
                                       (__bridge const void *)(inputKey),
                                       [inputKey  length],
                                       iv,
                                       [inputData bytes],
                                       [inputData length],
                                       (void *)bufferPtr1,
                                       bufferPtrSize1,
                                       &movedBytes1);
    if (ccStatus == kCCSuccess) {
        NSData *result = [NSData dataWithBytes:bufferPtr1 length:movedBytes1];
        free(bufferPtr1);
        return result;
    }
    free(bufferPtr1);
    return nil;
}
@end
