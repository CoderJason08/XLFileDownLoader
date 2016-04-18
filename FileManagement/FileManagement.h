//
//  FileManagement.h
//  XLFileDownloader
//
//  Created by Jason on 16/1/26.
//  Copyright © 2016年 Jason. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FileClarityGrade) {
    /** 标清 */
    FileClarityGradeStandard = 0,
    /** 高清 */
    FileClarityGradeHigh,
    /** 超清 */
    FileClarityGradeUltra
};

@interface FileManagement : NSObject

/** 磁盘总容量 */
+ (NSString *)totalDiskSpace;
/** 剩余容量 */
+ (NSString *)freeDiskSpace;
/** 下载容量 */
+ (NSString *)usedDiskSpace;

/**
 *  取消下载
 *
 *  @param videoId 想取消下载的视频id
 */
+ (void)cancelDownLoadWithVideoId:(NSString *)videoId;

/**
 *  下载文件
 *
 *  @param CourseId    关卡ID
 *  @param CourseName  关卡名称
 *  @param ChapterId   章节ID
 *  @param ChapterName 章节名称
 *  @param VideoId     视频ID
 *  @param VideoName   视频名称
 *  @param VideoUrl    视频URL
 */
+ (void)downLoadFileWithCourseId:(NSString *)CourseId
                      CourseName:(NSString *)CourseName
                       ChapterId:(NSString *)ChapterId
                     ChapterName:(NSString *)ChapterName
                         VideoId:(NSString *)VideoId
                       VideoName:(NSString *)VideoName
                        VideoUrl:(NSString *)VideoUrl;

/**
 *  根据章节ID删除一章视频
 *
 *  @param ChapterId 章节id
 */
+ (void)removeVideoWithChapterId:(NSString *)ChapterId;

/**
 *  根据视频id去获取视频缓存的路径
 *
 *  @param videoId 视频id
 *
 *  @return 视频路径,已下载完成则返回路径,否则返回空
 */
+ (NSString *)videoCachePathWithVideoId:(NSString *)videoId;

/**
 *  根据章节id获取本地缓存文件的大小
 *
 *  @param ChapterId 章节ID
 *
 */
+ (long long)videoCacheSizeWithChapterId:(NSString *)ChapterId;

/**
 *  获取本地缓存文件结构
 */
+ (NSMutableArray *)downLoadFileStructure;

/**
 *  根据章节详情字典获取当前章节下载状态
 *
 *  @param ChapterId 章节详情
 *  
 *  @param status : 未下载 下载中 暂停中 已完成
 */
+ (id)chapterStatusWithChapterInfo:(NSDictionary *)chapterInfo videoClarityGrade:(FileClarityGrade)clarityGrade;


/**
 *  修改视频下载状态
 *
 *  @param status  视频状态
 *  @param VideoId 视频id
 */
+ (void)changeVideoDownLoadStatus:(BOOL)status
                          VideoId:(NSString *)VideoId;
@end
