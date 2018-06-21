//
//  Repo.h
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

@interface Repo : GTRepository

- (instancetype)initWithURL:(NSURL *)localFileURL createIfNotExist:(BOOL)flag error:(NSError *_Nullable __autoreleasing *)error;

- (BOOL)commitWorkingFiles:(GTSignature *)signature;

- (BOOL)fetchRemote:(NSString *)remoteName credentialProvider:(GTCredentialProvider *)provider error:(NSError **)outError;

- (BOOL)pushToRemote:(GTCredentialProvider *)provider error:(NSError **)outError;

@end
