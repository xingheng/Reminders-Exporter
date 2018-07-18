//
//  Repo.m
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "Repo.h"

void RunInMainQueue(RepoOperationBlock block, BOOL result, NSError *error)
{
    if (!block) {
        return;
    }

    if ([NSThread isMainThread]) {
        block(result, error);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(result, error);
        });
    }
}

static const void *const kDispatchQueueSpecificKey = &kDispatchQueueSpecificKey;

@implementation Repo
{
    dispatch_queue_t workerQueue;
}

- (instancetype)initWithURL:(NSURL *)localFileURL createIfNotExist:(BOOL)flag error:(NSError *_Nullable __autoreleasing *)error
{
    if (self = [super initWithURL:localFileURL error:error]) {
    } else if (flag) {
        self = [Repo initializeEmptyRepositoryAtFileURL:localFileURL options:nil error:error];
    }

    workerQueue = dispatch_queue_create([NSString stringWithFormat:@"repository.%@", self].UTF8String, DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(workerQueue, kDispatchQueueSpecificKey, (__bridge void *)self, NULL);

    return self;
}

- (void)commitWorkingFiles:(GTSignature *)signature completion:(RepoOperationBlock)completion
{
    [self _runInSerialQueue:^{
        BOOL result = YES;
        NSError *error = nil;

        GTIndex *index = [self indexWithError:&error];
        BOOL hasChanges = NO, hasConflict = NO;

        for (NSString *filepath in [self allFiles]) {
            BOOL success;
            GTFileStatusFlags flag = [self statusForFile:filepath
                                                 success:&success
                                                   error:&error];

            if (!success) {
                DDLogError(@"%s: error: %@", __func__, error);
            }

            switch (flag) {
                case GTFileStatusNewInWorktree:

                    if (![index addFile:filepath
                                  error:&error]) {
                        DDLogError(@"%@", error);
                    }

                    hasChanges |= YES;
                    break;

                case GTFileStatusDeletedInWorktree:

                    if (![index removeFile:filepath
                                     error:&error]) {
                        DDLogError(@"%@", error);
                    }

                    hasChanges |= YES;
                    break;

                case GIT_STATUS_CONFLICTED:
                    hasConflict |= YES;

                // break;
                case GTFileStatusModifiedInWorktree:
                case GTFileStatusRenamedInWorktree:

                    if (![index updatePathspecs:@[filepath]
                                          error:&error
                                    passingTest:nil]) {
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
            result = NO;

            RunInMainQueue(completion, NO, nil);
            return;
        }

        GTTree *tree = [index writeTreeToRepository:self
                                              error:&error];
        GTReference *reference = [self headReferenceWithError:&error];
        GTBranch *currentBranch = [self currentBranchWithError:&error];
        GTCommit *latestComit = [currentBranch targetCommitWithError:&error];
        NSString *strMessage = latestComit ? (hasConflict ? @"Merge conflicts" : [NSString stringWithFormat:@"Update at %@", NSDate.date.descriptionForCurrentLocale]) : @"Initial commit.";

        GTCommit *commit = [self createCommitWithTree:tree
                                              message:strMessage
                                               author:signature
                                            committer:signature
                                              parents:latestComit ? @[latestComit] : nil
                               updatingReferenceNamed:reference.name
                                                error:&error];
        DDLogDebug(@"%@", commit);

        if (commit) {
            [self resetToCommit:commit
                      resetType:GTRepositoryResetTypeHard
                          error:&error];
        }

        RunInMainQueue(completion, commit, error);
    }];
}

- (void)fetchRemote:(NSString *)remoteName credentialProvider:(GTCredentialProvider *)provider completion:(RepoOperationBlock)completion
{
    [self _runInSerialQueue:^{
        NSError *error = nil;
        GTRemote *remote = [GTRemote remoteWithName:remoteName
                                       inRepository:self
                                              error:&error];

        if (remote) {
            [self fetchRemote:remote
                  withOptions:@{ GTRepositoryRemoteOptionsCredentialProvider: provider }
                        error:&error
                     progress:^(const git_transfer_progress *stats, BOOL *stop) {
                if (stats->total_objects > 0) {
                    DDLogVerbose(@"Receiving objects: %.2f%% (%d/%d)", 100.0 * stats->received_objects / stats->total_objects, stats->received_objects, stats->total_objects);
                }
            }];
        }

        RunInMainQueue(completion, remote, error);
    }];
}

- (void)pushToRemote:(GTCredentialProvider *)provider completion:(RepoOperationBlock)completion
{
    [self _runInSerialQueue:^{
        BOOL result = YES;
        NSError *error = nil;
        NSArray<NSString *> *remoteNames = [self remoteNamesWithError:&error];

        for (NSString *remoteName in remoteNames) {
            GTRemote *remote = [GTRemote remoteWithName:remoteName
                                           inRepository:self
                                                  error:&error];
            GTBranch *branch = [self currentBranchWithError:&error];

            result &= [self pushBranch:branch
                              toRemote:remote
                           withOptions:@{ GTRepositoryRemoteOptionsCredentialProvider: provider }
                                 error:&error
                              progress:^(unsigned int current, unsigned int total, size_t bytes, BOOL *stop) {
                if (total > 0) {
                    DDLogVerbose(@"Writing objects: %.2f%% (%d/%d)", 100.0 * current / total, current, total);
                }
            }];
        }

        RunInMainQueue(completion, result, error);
    }];
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

- (void)_runInSerialQueue:(dispatch_block_t)block
{
    BOOL isInternalQueue = self == dispatch_get_specific(kDispatchQueueSpecificKey);

    if (isInternalQueue) {
        block();
    } else {
        dispatch_async(workerQueue, block);
    }
}

@end
