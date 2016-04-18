//
//  FileDownloader.m
//  XLFileDownloader
//
//  Created by Jason on 16/1/26.
//  Copyright © 2016年 Jason. All rights reserved.
//

#import "FileDownloader.h"
#import "FileManagement.h"
#import "RC4Encryptor.h"


typedef long long FileSize;

@interface FileDownloader () <NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSMutableArray *downLoadQueue;
@property (nonatomic, strong) NSMutableArray *downLoadFileHandlerQueue;
@property (nonatomic, strong) NSMutableArray *downLoadFileCachePathQueue;
@end

@implementation FileDownloader

+ (instancetype)sharedInstance {
    static FileDownloader *fileDownloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileDownloader = [FileDownloader new];
    });
    return fileDownloader;
}

/**
 *  添加下载任务
 *
 *  @param fileUrl   下载文件url
 *  @param cacheDesc 下载文件缓存路径
 */
- (void)createConnectionWithFileUrl:(NSString *)fileUrl cacheDesc:(NSString *)cacheDesc {
    if ([self.downLoadFileCachePathQueue containsObject:cacheDesc]) {
        NSLog(@"正在下载,不要猛击");
        return;
    }
    NSURL *downloadUrl = [NSURL URLWithString:fileUrl];
    NSMutableURLRequest *downloadRequest = [NSMutableURLRequest requestWithURL:downloadUrl];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    FileSize currentSize = 0;
    /** 检测文件是否存在,存在的话获取文件大小 */
    BOOL isExist = [fileManager fileExistsAtPath:cacheDesc];
    if (isExist) {
        NSError *error = nil;
        NSDictionary *fileAttribute = [fileManager attributesOfItemAtPath:cacheDesc error:&error];
        if (fileAttribute && !error) {
            NSNumber *fileSize = [fileAttribute objectForKey:NSFileSize];
            currentSize = fileSize.longLongValue;
        }
    }else {
        /** 不存在的文件,创建文件 */
        [fileManager createFileAtPath:cacheDesc contents:nil attributes:nil];
    }
    /** 添加Range请求头进行断点续传 */
    [downloadRequest setValue:[NSString stringWithFormat:@"bytes=%lld-",currentSize] forHTTPHeaderField:@"Range"];
    /** 创建句柄关联文件 */
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForWritingAtPath:cacheDesc];
    [self.downLoadFileHandlerQueue addObject:fileHandler];
    /** 添加下载任务 */
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:downloadRequest delegate:self];
    [self.downLoadQueue addObject:connection];
    /** 缓存文件路径 */
    [self.downLoadFileCachePathQueue addObject:cacheDesc];
}

/**
 *  开启下载任务
 *
 *  @param fileUrl   文件url
 *  @param cacheDesc 文件缓存路径
 */
- (void)startDownloadFileWithUrl:(NSString *)fileUrl cacheDesc:(NSString *)cacheDesc {
    [self createConnectionWithFileUrl:fileUrl cacheDesc:cacheDesc];
}

- (void)cancelDownLoadWithVideoId:(NSString *)videoId {
    NSString *cachePath = [self cacheDescWithFileName:videoId];
    NSInteger index = [self.downLoadFileCachePathQueue indexOfObject:cachePath];
    NSURLConnection *connection = [self.downLoadQueue objectAtIndex:index];
    [connection cancel];
    [self.downLoadQueue removeObjectAtIndex:index];
    [self.downLoadFileCachePathQueue removeObjectAtIndex:index];
    [self.downLoadFileHandlerQueue removeObjectAtIndex:index];
}

/**
 *  根据文件名称获取文件缓存路径
 *
 *  @param fileName 文件名
 *
 *  @return 获取的文件缓存路径
 */
- (NSString *)cacheDescWithFileName:(NSString *)fileName {
    NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *downLoadFileFolderPath = [caches stringByAppendingPathComponent:@"DownLoadFile"];
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:downLoadFileFolderPath];
    /** 判断文件夹是否存在 */
    if (!isExist) {
        [[NSFileManager defaultManager] createDirectoryAtPath:downLoadFileFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    /** 将文件名进行base64加密作为缓存路径 */
    fileName = [NSString stringWithFormat:@"%@",fileName];
    NSData *fileNameData = [fileName dataUsingEncoding:NSUTF8StringEncoding];
    NSString *encryptorFileName = [fileNameData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *fileCachePath = [[downLoadFileFolderPath stringByAppendingPathComponent:encryptorFileName] stringByAppendingString:@".mp4"];
    return fileCachePath;
}

- (void)cancelDownLoadConnection:(NSURLConnection *)connection {
    NSInteger index = [self.downLoadQueue indexOfObject:connection];
    [self.downLoadQueue removeObjectAtIndex:index];
    [self.downLoadFileHandlerQueue removeObjectAtIndex:index];
    [self.downLoadFileCachePathQueue removeObjectAtIndex:index];
}

- (BOOL)isDownLoadingWithVideoId:(NSString *)videoId {
    return [self.downLoadFileCachePathQueue containsObject:[[FileDownloader sharedInstance] cacheDescWithFileName:videoId]];
}

#pragma mark - NSURLConnectionDataDelegate

/**
 *  收到服务器响应,可以获得文件总大小
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSInteger index = [self.downLoadQueue indexOfObject:connection];
    NSString *fileCachePath = [self.downLoadFileCachePathQueue objectAtIndex:index];
    NSLog(@"%@开始下载",fileCachePath);
}

/**
 *  接收到服务器返回的数据
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSInteger index = [self.downLoadQueue indexOfObject:connection];
    NSFileHandle *fileHandler = [self.downLoadFileHandlerQueue objectAtIndex:index];
    [fileHandler seekToEndOfFile];
    /** 加密数据 */
//    NSData *encryptedData = [RC4Encryptor encryptorData:data withKey:@"password"];
//    [fileHandler writeData:encryptedData];
    [fileHandler writeData:data];
}
/**
 *  下载完成
 *
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSInteger index = [self.downLoadQueue indexOfObject:connection];
    NSFileHandle *fileHandler = [self.downLoadFileHandlerQueue objectAtIndex:index];
    [fileHandler synchronizeFile];
    [fileHandler closeFile];
    
    NSString *fileCachePath = [self.downLoadFileCachePathQueue objectAtIndex:index];
    NSString *fileId = [fileCachePath lastPathComponent];
    NSData *fileIdData = [[NSData alloc] initWithBase64EncodedString:fileId options:NSDataBase64DecodingIgnoreUnknownCharacters];
    fileId = [[NSString alloc] initWithData:fileIdData encoding:NSUTF8StringEncoding];
    [FileManagement changeVideoDownLoadStatus:YES VideoId:fileId];
    [self cancelDownLoadConnection:connection];
    NSLog(@"%@下载完成",fileCachePath);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%@",error);
    [self cancelDownLoadConnection:connection];
}



#pragma mark - Getter & Setter
- (NSMutableArray *)downLoadQueue {
    if (!_downLoadQueue) {
        self.downLoadQueue = [NSMutableArray array];
    }
    return _downLoadQueue;
}
- (NSMutableArray *)downLoadFileHandlerQueue {
    if (!_downLoadFileHandlerQueue) {
        self.downLoadFileHandlerQueue = [NSMutableArray array];
    }
    return _downLoadFileHandlerQueue;
}
- (NSMutableArray *)downLoadFileCachePathQueue {
    if (!_downLoadFileCachePathQueue) {
        self.downLoadFileCachePathQueue = [NSMutableArray array];
    }
    return _downLoadFileCachePathQueue;
}

@end
