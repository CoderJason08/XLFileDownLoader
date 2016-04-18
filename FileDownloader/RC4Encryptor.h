//
//  RC4Encryptor.h
//  XLFileDownloader
//
//  Created by Jason on 16/1/26.
//  Copyright © 2016年 Jason. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RC4Encryptor : NSObject
+ (NSData *)encryptorData:(NSData *)data withKey:(NSString *)key;
@end
