//
//  Utility.m
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <DSUtility/NSString+Date.h>
#import "Utility.h"

#pragma mark - Functions

BOOL IsFileExist(NSString *strFilePath)
{
    if (strFilePath.length <= 0) {
        return NO;
    }

    return [[NSFileManager defaultManager] fileExistsAtPath:strFilePath];
}

BOOL DeleteFile(NSString *strFilePath, NSError **outError)
{
    return [[NSFileManager defaultManager] removeItemAtPath:strFilePath error:outError];
}

BOOL MoveFile(NSString *strFilePath, NSString *strDestPath, NSError **outError)
{
    return [[NSFileManager defaultManager] moveItemAtPath:strFilePath toPath:strDestPath error:outError];
}

BOOL CopyFile(NSString *strFilePath, NSString *strDestPath, NSError **outError)
{
    return [[NSFileManager defaultManager] copyItemAtPath:strFilePath toPath:strDestPath error:outError];
}

NSURL * CreateDirectoryIfNotExist(NSURL *sourceURL)
{
    if (IsFileExist(sourceURL.path)) {
        return sourceURL;
    }

    NSError *error = nil;

    if (![[NSFileManager defaultManager] createDirectoryAtURL:sourceURL
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error]) {
        NSLog(@"%@", error);
        return nil;
    }

    return sourceURL;
}

static NSURL * GetDocumentDirectoryPath(void)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentDirURL = [fileManager URLForDirectory:NSDocumentDirectory
                                                inDomain:NSUserDomainMask
                                       appropriateForURL:nil
                                                  create:NO
                                                   error:nil];

    return documentDirURL;
}

NSURL * GetRepoRootDirectoryPath(void)
{
    NSURL *resultURL = [GetDocumentDirectoryPath() URLByAppendingPathComponent:@"repos" isDirectory:YES];

    return CreateDirectoryIfNotExist(resultURL);
}

NSURL * GetReminderRepoRootDirectoryPath(void)
{
    NSURL *resultURL = [GetRepoRootDirectoryPath() URLByAppendingPathComponent:@"reminders" isDirectory:YES];

    return CreateDirectoryIfNotExist(resultURL);
}

#pragma mark - NSDate (Descriptions)

@implementation NSDate (Descriptions)

- (NSString *)descriptionForCurrentLocale
{
    return [self stringFromDateFormat:kDateFormat_Date_Time_Second];
//    return [self descriptionWithLocale:NSLocale.currentLocale];
}

@end
