//
//  MainViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 10/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <EventKit/EventKit.h>
#import "MainViewController.h"
#import "RepositoryViewController.h"
#import "EKGroup.h"
#import "PathUtility.h"
#import "Repo.h"

@interface MainViewController ()

@property (nonatomic, strong) EKEventStore *store;

@property (nonatomic, strong) Repo *repository;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Reminders";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(rightBarButtonTapped:)];
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

- (Repo *)repository
{
    if (!_repository) {
        NSError *error = nil;
        _repository = [[Repo alloc] initWithURL:GetReminderRepoRootDirectoryPath()
                               createIfNotExist:YES
                                          error:&error];

        if (error) {
            DDLogError(@"Initialize the repo failed with error: %@", error.localizedDescription);
        }
    }

    return _repository;
}

#pragma mark - Actions

- (void)rightBarButtonTapped:(id)sender
{
    RepositoryViewController *repoVC = [RepositoryViewController new];

    repoVC.repository = self.repository;
    [self pushViewController:repoVC];
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

        NSURL *repoURL = self.repository.fileURL;

        for (EKGroup *group in groups) {
            if (![group serializeToFile:repoURL]) {
                NSAssert(NO, @"Fatal!");
            }
        }

        DDLogVerbose(@"Serialized reminders data to files to %@.", repoURL);
        [self.repository indexStatus];
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
