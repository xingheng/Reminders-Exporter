//
//  Repo.m
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "Repo.h"

@implementation Repo

- (instancetype)initWithURL:(NSURL *)localFileURL createIfNotExist:(BOOL)flag error:(NSError *_Nullable __autoreleasing *)error
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
    GTIndex *index = [self indexWithError:&error];
    BOOL hasChanges = NO;

    for (NSString *filepath in  [self allFiles]) {
        BOOL success;
        GTFileStatusFlags flag = [self statusForFile:filepath success:&success error:&error];

        if (!success) {
            DDLogError(@"%s: error: %@", __func__, error);
        }

        switch (flag) {
            case GTFileStatusNewInWorktree:

                if (![index addFile:filepath error:&error]) {
                    DDLogError(@"%@", error);
                }

                hasChanges |= YES;
                break;

            case GTFileStatusDeletedInWorktree:

                if (![index removeFile:filepath error:&error]) {
                    DDLogError(@"%@", error);
                }

                hasChanges |= YES;
                break;

            case GTFileStatusModifiedInWorktree:
            case GTFileStatusRenamedInWorktree:

                if (![index updatePathspecs:@[filepath] error:&error passingTest:nil]) {
                    DDLogError(@"%@", error);
                }

                hasChanges |= YES;
                break;

            default:
                break;
        }
    }

    if (!hasChanges) {
        DDLogVerbose(@"Nothing changes.");
//        return;
    }

    GTTree *tree = [index writeTreeToRepository:self error:&error];
    GTReference *reference = [self headReferenceWithError:&error];
    GTBranch *currentBranch = [self currentBranchWithError:&error];
    GTCommit *latestComit = [currentBranch targetCommitWithError:&error];

    GTSignature *signature = [[GTSignature alloc] initWithName:@"iOS" email:@"iOS@apple.com" time:NSDate.date];
    NSString *strMessage = latestComit ? [NSString stringWithFormat:@"Update at %@", NSDate.date] : @"Initial commit.";

    GTCommit *commit = [self createCommitWithTree:tree message:strMessage author:signature committer:signature parents:@[latestComit] updatingReferenceNamed:reference.name error:&error];
    DDLogDebug(@"%@", commit);

    if (commit) {
        [self resetToCommit:commit resetType:GTRepositoryResetTypeHard error:&error];
    }
}

- (void)fetchRemote:(NSString *)remoteName URL:(NSString *)url credentialProvider:(GTCredentialProvider *)provider
{
    NSError *error = nil;

    NSArray<NSString *> *remoteNames = [self remoteNamesWithError:&error];
    BOOL existing = [remoteNames bk_any:^BOOL (NSString *obj) {
        return [obj isEqualToString:remoteName];
    }];

    GTRemote *remote = nil;

    if (existing) {
        remote = [GTRemote remoteWithName:remoteName inRepository:self error:&error];
    } else {
        remote = [GTRemote createRemoteWithName:remoteName URLString:url inRepository:self error:&error];
    }

    [self fetchRemote:remote
          withOptions:@{ GTRepositoryRemoteOptionsCredentialProvider: provider }
                error:&error
             progress:^(const git_transfer_progress *stats, BOOL *stop) {
        DDLogVerbose(@"Receiving objects: %f%% (%d/%d", 1.0 * stats->received_objects / stats->total_objects, stats->received_objects, stats->total_objects);
    }];

    DDLogDebug(@"error: %@", error);
}

#pragma mark - Private

- (NSArray<NSString *> *)allFiles
{
    NSMutableArray<NSString *> *allFiles = [NSMutableArray new];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:self.fileURL.path];

    NSString *path = nil;

    while ((path = [enumerator nextObject])) {
        if ([path hasPrefix:@"."]) {
            [enumerator skipDescendants]; // Skip the hidden files.
            continue;
        }

        // DDLogVerbose(@"Found %@", path);
        [allFiles addObject:path];
    }

    return allFiles;
}

@end
