//
//  Repo.h
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

typedef void (^RepoOperationBlock)(BOOL result, NSError *error);

void RunInMainQueue(RepoOperationBlock block, BOOL result, NSError *error);


@interface Repo : GTRepository

- (instancetype)initWithURL:(NSURL *)localFileURL createIfNotExist:(BOOL)flag error:(NSError *_Nullable __autoreleasing *)error;

- (void)commitWorkingFiles:(GTSignature *)signature completion:(RepoOperationBlock)completion;

- (void)fetchRemote:(NSString *)remoteName credentialProvider:(GTCredentialProvider *)provider completion:(RepoOperationBlock)completion;

- (void)pushToRemote:(GTCredentialProvider *)provider completion:(RepoOperationBlock)completion;

@end
