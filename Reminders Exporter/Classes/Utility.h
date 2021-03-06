//
//  Utility.h
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSSHKeyPublicFileName(__prefix__)  [NSString stringWithFormat: @"%@.pub", __prefix__]
#define kSSHKeyPrivateFileName(__prefix__) [NSString stringWithFormat:@"%@.pem", __prefix__]


BOOL IsFileExist(NSString *strFilePath);

BOOL DeleteFile(NSString *strFilePath, NSError **outError);

BOOL MoveFile(NSString *strFilePath, NSString *strDestPath, NSError **outError);

BOOL CopyFile(NSString *strFilePath, NSString *strDestPath, NSError **outError);

NSURL * CreateDirectoryIfNotExist(NSURL *sourceURL);

NSURL * GetRepoRootDirectoryPath(void);

NSURL * GetReminderRepoRootDirectoryPath(void);

NSURL * GetSSHKeysRootDirectoryPath(void);

NSURL * GetSSHKeyFullPath(NSString *filename);

void GenerateKeyPair();

bool generate_key(const char *public_key_file, const char *private_key_file);


#pragma mark - Functions

@interface NSDate (Descriptions)

- (NSString *)descriptionForCurrentLocale;

@end
