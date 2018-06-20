//
//  Repo+Reminders.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/20.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "Repo+Reminders.h"
#import "PathUtility.h"

@implementation Repo (Reminders)

+ (Repo *)reminderRepo
{
    static Repo *repo = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        repo = [[Repo alloc] initWithURL:GetReminderRepoRootDirectoryPath()
                        createIfNotExist:YES
                                   error:&error];

        if (error) {
            DDLogError(@"Initialize the repo failed with error: %@", error.localizedDescription);
        }
    });

    return repo;
}

@end
