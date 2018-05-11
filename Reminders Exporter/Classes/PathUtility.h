//
//  PathUtility.h
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <Foundation/Foundation.h>

BOOL IsFileExist(NSString *strFilePath);

BOOL DeleteFile(NSString *strFilePath, NSError **outError);

BOOL MoveFile(NSString *strFilePath, NSString *strDestPath, NSError **outError);

BOOL CopyFile(NSString *strFilePath, NSString *strDestPath, NSError **outError);

NSURL * CreateDirectoryIfNotExist(NSURL *sourceURL);

NSURL * GetRepoRootDirectoryPath(void);

NSURL * GetReminderRepoRootDirectoryPath(void);
