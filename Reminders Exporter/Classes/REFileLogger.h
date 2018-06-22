//
//  REFileLogger.h
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/22.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <CocoaLumberjack/DDFileLogger.h>

@interface REFileLogger : DDFileLogger

+ (instancetype)sharedInstance;

@end
