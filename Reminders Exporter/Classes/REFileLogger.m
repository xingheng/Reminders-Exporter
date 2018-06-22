//
//  REFileLogger.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/22.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "REFileLogger.h"

@implementation REFileLogger

- (instancetype)initWithLogFileManager:(id<DDLogFileManager>)logFileManager
{
    if (self = [super initWithLogFileManager:logFileManager]) {
        self.rollingFrequency = 60 * 60 * 24;
        self.logFileManager.maximumNumberOfLogFiles = 30;
    }

    return self;
}

#pragma mark - Public

+ (instancetype)sharedInstance
{
    static REFileLogger *gFileLogger = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        gFileLogger = [REFileLogger new];
    });

    return gFileLogger;
}

#pragma mark - Private

@end
