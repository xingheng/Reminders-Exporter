//
//  MainViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 10/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <EventKit/EventKit.h>
#import "MainViewController.h"
#import "EKGroup.h"
#import "PathUtility.h"
#import "Repo.h"

@interface MainViewController ()

@property (nonatomic, strong) EKEventStore *store;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Property

- (EKEventStore *)store
{
    if (!_store) {
        _store = [EKEventStore new];
    }

    return _store;
}

#pragma mark - Private

- (void)_fetchReminders
{
    DDLogVerbose(@"Fetching reminders...");
    NSPredicate *predicate = [self.store predicateForIncompleteRemindersWithDueDateStarting:nil ending:nil calendars:nil];

    [self.store fetchRemindersMatchingPredicate:predicate
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

        NSURL *repoURL = GetReminderRepoRootDirectoryPath();

        for (EKGroup *group in groups) {
            if (![group serializeToFile:repoURL]) {
                NSAssert(NO, @"Fatal!");
            }
        }

        DDLogVerbose(@"Serialized reminders data to files to %@.", repoURL);

        NSError *error = nil;
        Repo *reminderRepo = [[Repo alloc] initWithURL:repoURL
                                      createIfNotExist:YES
                                                 error:&error];

        if (error) {
            DDLogError(@"Initialize the repo %@ failed with error: %@", repoURL, error.localizedDescription);
        }

        (void)reminderRepo; // ToDo
    }];
}

#pragma mark - BuildViewDelegate

- (void)buildSubview:(UIView *)containerView controller:(BaseViewController *)viewController
{
}

- (void)loadDataForController:(BaseViewController *)viewController
{
    switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder]) {
        case EKAuthorizationStatusAuthorized:
            DDLogDebug(@"Authorized!");
            [self _fetchReminders];
            break;

        case EKAuthorizationStatusDenied:
        case EKAuthorizationStatusRestricted:
            DDLogError(@"Failed!");
            break;

        case EKAuthorizationStatusNotDetermined:
            DDLogDebug(@"Not Yet!");

            [self.store requestAccessToEntityType:EKEntityTypeReminder
                                       completion:^(BOOL granted, NSError *error) {
            if (granted) {
                [self _fetchReminders];
            } else {
                DDLogError(@"%s: %@", __func__, error);
            }
        }];
            break;
    }
}

- (void)tearDown:(BaseViewController *)viewController
{
}

- (BOOL)shouldInvalidateDataForController:(BaseViewController *)viewController
{
    return NO;
}

@end
