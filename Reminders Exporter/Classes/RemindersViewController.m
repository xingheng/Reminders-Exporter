//
//  RemindersViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 10/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <EventKit/EventKit.h>
#import "RemindersViewController.h"
#import "RepositoryViewController.h"
#import "EKGroup.h"
#import "PathUtility.h"
#import "Repo+UserActions.h"
#import "UserPreferences.h"
#import "RemindersTableView.h"

#pragma mark - Functions

static NSString * GetTimeDistance(NSDate *date1, NSDate *date2)
{
    NSTimeInterval interval = fabs(date1.timeIntervalSince1970 - date2.timeIntervalSince1970);

    if (interval < 60) {
        return [NSString stringWithFormat:@"%.0f second(s) ago", interval];
    } else if (interval < 60 * 60) {
        return [NSString stringWithFormat:@"%.0f minute(s) ago", interval  / 60];
    } else if (interval < 60 * 60 * 24) {
        return [NSString stringWithFormat:@"%.0f hour(s) ago", interval  / 60 / 60];
    } else if (interval < 60 * 60 * 24 * 30) {
        return [NSString stringWithFormat:@"%.0f day(s) ago", interval  / 60 / 60 / 24];
    } else if (interval < 60 * 60 * 24 * 30 * 12) {
        return [NSString stringWithFormat:@"%.0f month(s) ago", interval  / 60 / 60 / 24 / 30];
    } else {
        return [NSString stringWithFormat:@"%.0f year(s) ago", interval  / 60 / 60 / 24 / 30 / 12];
    }
}

#pragma mark - RemindersViewController

@interface RemindersViewController ()

@property (nonatomic, strong) EKEventStore *store;
@property (nonatomic, strong) Repo *repository;

@property (nonatomic, strong) RemindersTableView *tableView;

@end

@implementation RemindersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Reminders";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(editBarButtonTapped:)];
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

- (void)editBarButtonTapped:(id)sender
{
    RepositoryViewController *repoVC = [RepositoryViewController new];

    repoVC.repository = self.repository;
    [self pushViewController:repoVC];
}

#pragma mark - Private

- (void)_fetchReminders:(void (^)(void))completion
{
    DDLogVerbose(@"Fetching reminders...");
    NSPredicate *predicate = [self.store predicateForIncompleteRemindersWithDueDateStarting:nil ending:nil calendars:nil];

    @weakify(self);

    [self.store fetchRemindersMatchingPredicate:predicate
                                     completion:^(NSArray *reminders) {
        @strongify(self);
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

        self.tableView.dataItems = groups;
        SetLastUpdateDate(NSDate.date);

        NSURL *repoURL = self.repository.fileURL;

        for (EKGroup *group in groups) {
            if (![group serializeToFile:repoURL]) {
                NSAssert(NO, @"Fatal!");
            }
        }

        DDLogVerbose(@"Serialized reminders data to files to %@.", repoURL);

        if ([self.repository commitWorkingFiles]) {
            [self.repository pushToRemotes];
        }

        if (completion) {
            completion();
        }
    }];
}

#pragma mark - BuildViewDelegate

- (void)buildSubview:(UIView *)containerView controller:(BaseViewController *)viewController
{
    RemindersTableView *tableView = [RemindersTableView new];

    @weakify(self);

    tableView.refreshBlock = ^void (UIRefreshControl *refreshControl) {
        @strongify(self);

        NSString *title = [NSString stringWithFormat:@"Last Updated At %@", GetTimeDistance(GetLastUpdateDate(), NSDate.date)];
        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:title ? : @"" attributes:@{ NSForegroundColorAttributeName: [UIColor grayColor] }];

        [self _fetchReminders:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [refreshControl endRefreshing];
            });
        }];
    };

    self.tableView = tableView;
    [containerView addSubview:tableView];

    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(containerView);
    }];
}

- (void)loadDataForController:(BaseViewController *)viewController
{
    switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder]) {
        case EKAuthorizationStatusAuthorized:
            DDLogDebug(@"Authorized!");
            [self _fetchReminders:nil];
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
                [self _fetchReminders:nil];
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
