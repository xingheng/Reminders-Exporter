//
//  RemindersViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 10/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <DSUtility/UIControl+BlockAction.h>
#import "RemindersViewController.h"
#import "RepositoryViewController.h"
#import "EKGroup+Reminders.h"
#import "Repo+UserActions.h"
#import "Repo+Reminders.h"
#import "UserPreferences.h"
#import "RemindersTableView.h"


#pragma mark - RemindersViewController

@interface RemindersViewController ()

@property (nonatomic, strong, readonly) Repo *repository;

@property (nonatomic, strong) RemindersTableView *tableView;

@end

@implementation RemindersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Reminders";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(rewindBarButtonTapped:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(editBarButtonTapped:)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadDataForController:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadDataForController:) name:UIApplicationSignificantTimeChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Property

- (Repo *)repository
{
    return [Repo reminderRepo];
}

#pragma mark - Actions

- (void)rewindBarButtonTapped:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"x-apple-reminder://"] options:@{} completionHandler:nil];
}

- (void)editBarButtonTapped:(id)sender
{
    RepositoryViewController *repoVC = [RepositoryViewController new];

    repoVC.repository = self.repository;
    [self pushViewController:repoVC];
}

#pragma mark - Private

- (void)_fetchReminders:(void (^)(void))completion
{
    @weakify(self);

    [EKGroup fetchRemindersToRepo:self.repository
                       completion:^(BOOL result, NSArray<EKGroup *> *groups) {
        @strongify(self);
        self.tableView.dataItems = groups;

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

        NSString *title = [NSString stringWithFormat:@"Last Updated at %@ ago", GetTimeDistance(GetLastUpdateDate(), NSDate.date)];
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
        case EKAuthorizationStatusRestricted: {
            DDLogError(@"Failed!");
            HUDIndicator(self.view).title(@"Failed to access the reminders data.")
            .subTitle(@"Go to the setting page to check it.")
            .actionButton(^(UIButton *button) {
                [button setTitle:@"OK" forState:UIControlStateNormal];
                [button addEventBlock:^(id sender) {
                    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    UIApplication *application = [UIApplication sharedApplication];

                    if ([application canOpenURL:url]) {
                        [application  openURL:url
                                      options:@{}
                            completionHandler:^(BOOL success) {
                            HUDHide(self.view);
                        }];
                    }
                }
                     forControlEvents:UIControlEventTouchUpInside];
            }).show();
            break;
        }

        case EKAuthorizationStatusNotDetermined:
            DDLogDebug(@"Not Yet!");

            [EKEventStore.new requestAccessToEntityType:EKEntityTypeReminder
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
    return YES;
}

@end
