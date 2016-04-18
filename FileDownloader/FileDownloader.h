//
//  FileDownloader.h
//  XLFileDownloader
//
//  Created by Jason on 16/1/26.
//  Copyright © 2016年 Jason. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileDownloader : NSObject

/** 正在缓存的文件队列 */
@property (nonatomic, strong, readonly) NSMutableArray *downLoadFileCachePathQueue;

+ (instancetype)sharedInstance;
/**
 *  开始下载文件
 *
 *  @param fileUrl   文件url
 *  @param cacheDesc 文件缓存路径
 */
- (void)startDownloadFileWithUrl:(NSString *)fileUrl cacheDesc:(NSString *)cacheDesc;
/**
 *  取消下载
 *
 *  @param videoId 文件id
 */
- (void)cancelDownLoadWithVideoId:(NSString *)videoId;
/**
 *  根据文件名获取文件缓存路径
 *
 *  @param fileName 文件名
 */
- (NSString *)cacheDescWithFileName:(NSString *)fileName;

- (BOOL)isDownLoadingWithVideoId:(NSString *)videoId;

@end
