//
//  FileManagement.m
//  XLFileDownloader
//
//  Created by Jason on 16/1/26.
//  Copyright © 2016年 Jason. All rights reserved.
//

#import "FileManagement.h"
#import "FileDownloader.h"


@implementation FileManagement

+ (NSString *)totalDiskSpace {
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    NSNumber *total = [fattributes objectForKey:NSFileSystemSize];
    return [NSString stringWithFormat:@"%.2lf",[total floatValue] / 1024 / 1024 / 1024];
    
}

+ (NSString *)freeDiskSpace {
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    NSNumber *free = [fattributes objectForKey:NSFileSystemFreeSize];
    return [NSString stringWithFormat:@"%.2lf",[free floatValue] / 1024 / 1024 / 1024];
}

+ (NSString *)usedDiskSpace {
    return [NSString stringWithFormat:@"%.2lf",[self totalDiskSpace].floatValue - [self freeDiskSpace].floatValue];
}

+ (void)cancelDownLoadWithVideoId:(NSString *)videoId {
    [[FileDownloader sharedInstance] cancelDownLoadWithVideoId:videoId];
}

+ (id)chapterStatusWithChapterInfo:(NSDictionary *)chapterInfo videoClarityGrade:(FileClarityGrade)clarityGrade; {
    /** 获取视频数组 */
    NSArray *tmpArray = chapterInfo[@"extra"];
    NSMutableArray *videoArray = @[].mutableCopy;
    for (id obj in tmpArray) {
        if ([obj[@"type"] integerValue] == 1) {
            [videoArray addObject:obj];
        }
    }
    /** 获取视频总大小 */
    long long totalSize = 0;
    NSMutableArray *isDownloadingArray = @[].mutableCopy;
    for (NSDictionary *video in videoArray) {

        if (![video[@"objectSizes"] isKindOfClass:[NSNull class]]) {
            totalSize += [[video[@"objectSizes"] objectAtIndex:clarityGrade] longLongValue];
        }
        [isDownloadingArray addObject:@([[FileDownloader sharedInstance] isDownLoadingWithVideoId:video[@"id"]])];
    }
    /** 获取本地缓存大小 */
    NSString *chapterId = chapterInfo[@"id"];
    long long localSize = [self videoCacheSizeWithChapterId:chapterId];
    

    NSString *status = nil;
    CGFloat progress = 0.0f;
    if (localSize == 0) {
        status = @"未下载";
        progress = 0.0f;
    }else if (localSize > 0 && localSize < totalSize) {
        progress = (double)localSize / totalSize;
        status = @"下载中";
        for (NSNumber *number in isDownloadingArray) {
            if ([number boolValue] == NO) {
                status = @"暂停中";
            }
        }
    }else if (localSize >= totalSize) {
        status = @"已完成";
        progress = 1.0f;
    }
    NSLog(@"%@  %f  %lld",status,progress,localSize);
    return @{@"status" : status,
             @"progress" : @(progress),
             };
}

+ (void)removeVideoWithChapterId:(NSString *)ChapterId {
    NSString *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *downLoadFileFolder = [cache stringByAppendingPathComponent:@"DownLoadFile"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:downLoadFileFolder]) {
        NSLog(@"没有缓存文件");
        return;
    }
    NSArray *fileStructure = [self downLoadFileStructure];
    NSMutableArray *delVideos = @[].mutableCopy;
    for (NSDictionary *course in fileStructure) {
        NSDictionary *targetChapter = nil;
        for (NSDictionary *chapter in course[@"Chapters"]) {
            if ([chapter[@"ChapterId"] integerValue] == [ChapterId integerValue]) {
                targetChapter = chapter;
                for (NSDictionary *video in chapter[@"Videos"]) {
                    [delVideos addObject:video[@"VideoId"]];
                }
            }
        }
        if (targetChapter) {
            [course[@"Chapters"] removeObject:targetChapter];
        }
    }
    /** 下载列表存至本地 */
    [fileStructure writeToFile:[self downLoadFileStructeCachePath] atomically:YES];
    /** 删除视频文件 */
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *videoId in delVideos) {
        NSString *filePath = [[FileDownloader sharedInstance] cacheDescWithFileName:videoId];
        if ([fileManager fileExistsAtPath:filePath]) {
            [fileManager removeItemAtPath:filePath error:nil];
        }
    }
}

+ (long long)videoCacheSizeWithChapterId:(NSString *)ChapterId {
    NSString *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *downLoadFileFolder = [cache stringByAppendingPathComponent:@"DownLoadFile"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:downLoadFileFolder]) {
        return 0;
    }
    NSArray *fileStructure = [self downLoadFileStructure];
    NSMutableArray *targetVideos = @[].mutableCopy;
    for (NSDictionary *course in fileStructure) {
        for (NSDictionary *chapter in course[@"Chapters"]) {
            if ([chapter[@"ChapterId"] integerValue] == [ChapterId integerValue]) {
                for (NSDictionary *video in chapter[@"Videos"]) {
                    [targetVideos addObject:video[@"VideoId"]];
                }
            }
        }
    }
    long long totalSize = 0;
    for (NSString *videoId in targetVideos) {
        NSDictionary *fileAttribute = [[NSFileManager defaultManager] attributesOfItemAtPath:[self videoCachePathWithVideoId:videoId] error:nil];
        long long fileSize = [[fileAttribute objectForKey:NSFileSize] longLongValue];
        totalSize += fileSize;
    }
    /** 转换为mb为单位 */
//    return [NSString stringWithFormat:@"%.2lldM",totalSize / 1024 / 1024];
    return totalSize;
}

+ (NSString *)videoCachePathWithVideoId:(NSString *)videoId {
    NSArray *fileStructure = [self downLoadFileStructure];
    for (NSDictionary *course in fileStructure) {
        for (NSDictionary *chapter in course[@"Chapters"]) {
            for (NSDictionary *video in chapter[@"Videos"]) {
                if (([video[@"VideoId"] integerValue] == [videoId integerValue]) && video[@"VideoDownloadStatus"]) {
                    return [[FileDownloader sharedInstance] cacheDescWithFileName:videoId];
                }
            }
        }
    }
    return nil;
}

/**
 *  获取配置文件路径
 */
+ (NSString *)downLoadFileStructeCachePath {
    NSString *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *structurePath = [cache stringByAppendingPathComponent:@"DownLoadFile"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:structurePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:structurePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [structurePath stringByAppendingPathComponent:@"DownLoadFileList.plist"];
    return filePath;
}

+ (NSMutableArray *)downLoadFileStructure {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self downLoadFileStructeCachePath]]) {
        return @[].mutableCopy;
    }
    NSMutableArray *fileStructe = [NSMutableArray arrayWithContentsOfFile:[self downLoadFileStructeCachePath]];
    return fileStructe;
}

+ (void)downLoadFileWithCourseId:(NSString *)CourseId CourseName:(NSString *)CourseName ChapterId:(NSString *)ChapterId ChapterName:(NSString *)ChapterName VideoId:(NSString *)VideoId VideoName:(NSString *)VideoName VideoUrl:(NSString *)VideoUrl {
    NSMutableArray *fileStructure = [self downLoadFileStructure];
    if (fileStructure.count == 0) {
        /** 创建关卡 */
        NSMutableDictionary *course = @{}.mutableCopy;
        [course setObject:CourseId forKey:@"CourseId"];
        [course setObject:CourseName forKey:@"CourseName"];
        [course setObject:@[].mutableCopy forKey:@"Chapters"];
        [fileStructure addObject:course];
        /** 创建章节 */
        NSMutableDictionary *chapter = @{}.mutableCopy;
        [chapter setObject:ChapterId forKey:@"ChapterId"];
        [chapter setObject:ChapterName forKey:@"ChapterName"];
        [chapter setObject:@[].mutableCopy forKey:@"Videos"];
        [course[@"Chapters"] addObject:chapter];
        /** 创建视频 */
        NSMutableDictionary *video = @{}.mutableCopy;
        [video setObject:VideoId forKey:@"VideoId"];
        [video setObject:VideoName forKey:@"VideoName"];
        [video setValue:@(NO) forKey:@"VideoDownloadStatus"];
        [chapter[@"Videos"] addObject:video];
        /** 下载列表存至本地 */
        [fileStructure writeToFile:[self downLoadFileStructeCachePath] atomically:YES];
        /** 开启下载 */
        [[FileDownloader sharedInstance] startDownloadFileWithUrl:VideoUrl cacheDesc:[[FileDownloader sharedInstance] cacheDescWithFileName:VideoId]];
    }else {
        NSMutableArray *courseIds = @[].mutableCopy;
        for (NSDictionary *course in fileStructure) {
            [courseIds addObject:course[@"CourseId"]];
        }
        /** 判断是否存在该课程号 */
        if ([courseIds containsObject:CourseId]) {
            /** 获取目标课程 */
            NSDictionary *targetCourse = [fileStructure objectAtIndex:[courseIds indexOfObject:CourseId]];
            NSMutableArray *chapterIds = @[].mutableCopy;
            for (NSDictionary *chapter in targetCourse[@"Chapters"]) {
                [chapterIds addObject:chapter[@"ChapterId"]];
            }
            /** 判断是否存在该章节 */
            if ([chapterIds containsObject:ChapterId]) {
                /** 获取目标章节 */
                NSDictionary *targetChapter = [targetCourse[@"Chapters"] objectAtIndex:[chapterIds indexOfObject:ChapterId]];
                NSMutableArray *videoIds = @[].mutableCopy;
                for (NSDictionary *video in targetChapter[@"Videos"]) {
                    [videoIds addObject:video[@"VideoId"]];
                }
                /** 判断是否存在视频 */
                if ([videoIds containsObject:VideoId]) {
                    /** 下载列表存至本地 */
                    [fileStructure writeToFile:[self downLoadFileStructeCachePath] atomically:YES];
                    /** 开启下载 */
                    [[FileDownloader sharedInstance] startDownloadFileWithUrl:VideoUrl cacheDesc:[[FileDownloader sharedInstance] cacheDescWithFileName:VideoId]];
                }else {
                    /** 创建视频 */
                    NSMutableDictionary *video = @{}.mutableCopy;
                    [video setObject:VideoId forKey:@"VideoId"];
                    [video setObject:VideoName forKey:@"VideoName"];
                    [video setValue:@(NO) forKey:@"VideoDownloadStatus"];
                    [targetChapter[@"Videos"] addObject:video];
                    /** 下载列表存至本地 */
                    [fileStructure writeToFile:[self downLoadFileStructeCachePath] atomically:YES];
                    /** 开启下载 */
                    [[FileDownloader sharedInstance] startDownloadFileWithUrl:VideoUrl cacheDesc:[[FileDownloader sharedInstance] cacheDescWithFileName:VideoId]];
                }
            }else {
                /** 创建章节 */
                NSMutableDictionary *chapter = @{}.mutableCopy;
                [chapter setObject:ChapterId forKey:@"ChapterId"];
                [chapter setObject:ChapterName forKey:@"ChapterName"];
                [chapter setObject:@[].mutableCopy forKey:@"Videos"];
                [targetCourse[@"Chapters"] addObject:chapter];
                /** 创建视频 */
                NSMutableDictionary *video = @{}.mutableCopy;
                [video setObject:VideoId forKey:@"VideoId"];
                [video setObject:VideoName forKey:@"VideoName"];
                [video setValue:@(NO) forKey:@"VideoDownloadStatus"];
                [chapter[@"Videos"] addObject:video];
                /** 下载列表存至本地 */
                [fileStructure writeToFile:[self downLoadFileStructeCachePath] atomically:YES];
                /** 开启下载 */
                [[FileDownloader sharedInstance] startDownloadFileWithUrl:VideoUrl cacheDesc:[[FileDownloader sharedInstance] cacheDescWithFileName:VideoId]];
            }
        }else {
            /** 创建关卡 */
            NSMutableDictionary *course = @{}.mutableCopy;
            [course setObject:CourseId forKey:@"CourseId"];
            [course setObject:CourseName forKey:@"CourseName"];
            [course setObject:@[].mutableCopy forKey:@"Chapters"];
            [fileStructure addObject:course];
            /** 创建章节 */
            NSMutableDictionary *chapter = @{}.mutableCopy;
            [chapter setObject:ChapterId forKey:@"ChapterId"];
            [chapter setObject:ChapterName forKey:@"ChapterName"];
            [chapter setObject:@[].mutableCopy forKey:@"Videos"];
            [course[@"Chapters"] addObject:chapter];
            /** 创建视频 */
            NSMutableDictionary *video = @{}.mutableCopy;
            [video setObject:VideoId forKey:@"VideoId"];
            [video setObject:VideoName forKey:@"VideoName"];
            [video setValue:@(NO) forKey:@"VideoDownloadStatus"];
            [chapter[@"Videos"] addObject:video];
            /** 下载列表存至本地 */
            [fileStructure writeToFile:[self downLoadFileStructeCachePath] atomically:YES];
            /** 开启下载 */
            [[FileDownloader sharedInstance] startDownloadFileWithUrl:VideoUrl cacheDesc:[[FileDownloader sharedInstance] cacheDescWithFileName:VideoId]];
        }
    }
}

+ (void)changeVideoDownLoadStatus:(BOOL)status VideoId:(NSString *)VideoId {
    NSMutableArray *fileStructure = [self downLoadFileStructure];
    if (fileStructure.count == 0) {
        
        return;
    }
    for (NSDictionary *course in fileStructure) {
        for (NSDictionary *chapter in [course objectForKey:@"Chapters"]) {
            for (NSDictionary *video in [chapter objectForKey:@"Videos"]) {
                NSString *targetVideoId = [video objectForKey:@"VideoId"];
                if ([targetVideoId integerValue] == [VideoId integerValue]) {
                    [video setValue:@(status) forKey:@"VideoDownloadStatus"];
                    [fileStructure writeToFile:[self downLoadFileStructeCachePath] atomically:YES];
                    return;
                }
            }
        }
    }
}

@end
