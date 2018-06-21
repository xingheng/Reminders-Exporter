//
//  Repo+UserActions.h
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/19.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "Repo.h"

@interface Repo (UserActions)

- (BOOL)commitWorkingFiles;

- (BOOL)pullFromRemote:(NSString *)remoteName merge:(BOOL (^)(void))conflictBlock error:(NSError **)outError;

- (BOOL)pushToRemotes:(NSError **)error;

@end
