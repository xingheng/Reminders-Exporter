//
//  Repo.m
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "Repo.h"

@implementation Repo

- (instancetype)initWithURL:(NSURL *)localFileURL createIfNotExist:(BOOL)flag error:(NSError * _Nullable __autoreleasing *)error
{
    if (self = [super initWithURL:localFileURL error:error]) {

    } else if (flag) {
        self = [Repo initializeEmptyRepositoryAtFileURL:localFileURL options:nil error:error];
    }

    return self;
}

- (void)indexStatus
{
    NSError *error = nil;
    GTIndex *index = [GTIndex inMemoryIndexWithRepository:self error:&error];

    for (NSString *filepath in  [self allFiles]) {
        BOOL success;
        GTFileStatusFlags flag = [self statusForFile:filepath success:&success error:&error];

        if (!success) {
            DDLogError(@"%s: error: %@", __func__, error);
        }

        switch (flag) {
            case GTFileStatusNewInWorktree: {
                if (![index addFile:filepath error:&error]) {
                    DDLogError(@"%@", error);
                }
                break;
            }

            default:
                break;
        }

    }

    DDLogDebug(@"%@", [index entries]);
}

#pragma mark - Private

- (NSArray<NSString *> *)allFiles
{
    NSMutableArray<NSString *> *allFiles = [NSMutableArray new];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:self.fileURL.path];

    NSString *path = nil;
    while ((path = [enumerator nextObject])) {
        DDLogVerbose(@"Found %@", path);

        if ([path hasPrefix:@"."]) {
            [enumerator skipDescendants]; // Skip the hidden files.
            continue;
        }

        [allFiles addObject:path];
    }

    return allFiles;
}

@end
