//
//  EKGroup+Reminders.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/20.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "EKGroup+Reminders.h"
#import "UserPreferences.h"
#import "Repo+UserActions.h"

@implementation EKGroup (Reminders)

+ (void)fetchReminders:(void (^)(NSArray<EKGroup *> *))completion
{
    DDLogVerbose(@"Fetching reminders...");

    EKEventStore *store = [[EKEventStore alloc] init];
    NSPredicate *predicate = [store predicateForIncompleteRemindersWithDueDateStarting:nil ending:nil calendars:nil];

    [store fetchRemindersMatchingPredicate:predicate
                                completion:^(NSArray *reminders) {
        DDLogVerbose(@"Finish fetching...");

        NSMutableArray<EKGroup *> *groups = [NSMutableArray new];

        for (EKReminder *reminder in reminders) {
            EKGroup *group = [groups bk_match:^BOOL (EKGroup *obj) {
                return [obj.calendar.calendarIdentifier isEqualToString:reminder.calendar.calendarIdentifier];
            }];

            if (!group) {
                group = [[EKGroup alloc] initWithCalendar:reminder.calendar];
                [groups addObject:group];
            }

            [group addReminder:reminder];
        }

        SetLastUpdateDate(NSDate.date);

        if (completion) {
            completion(groups);
        }
    }];
}

+ (void)fetchRemindersToRepo:(Repo *)repository completion:(void (^)(BOOL, NSArray<EKGroup *> *))completion
{
    [self fetchReminders:^(NSArray<EKGroup *> *groups) {
        BOOL result = NO;

        if (repository) {
            NSURL *repoURL = repository.fileURL;

            for (EKGroup *group in groups) {
                if (![group serializeToFile:repoURL]) {
                    NSAssert(NO, @"Fatal!");
                }
            }

            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                DDLogVerbose(@"Serialized reminders data to files to %@.", repoURL);
            });

            if ([repository commitWorkingFiles]) {
                result = [repository pushToRemotes:nil];
            }
        }

        if (completion) {
            if ([NSThread isMainThread]) {
                completion(result, groups);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(result, groups);
                });
            }
        }
    }];
}

@end
