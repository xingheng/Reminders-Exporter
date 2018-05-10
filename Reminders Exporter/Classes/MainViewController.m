//
//  MainViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 10/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "MainViewController.h"
#import <EventKit/EventKit.h>

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
    NSPredicate *predicate = [self.store predicateForIncompleteRemindersWithDueDateStarting:nil ending:nil calendars:nil];

    [self.store fetchRemindersMatchingPredicate:predicate
                                     completion:^(NSArray *reminders) {
        reminders = [reminders sortedArrayUsingComparator:^NSComparisonResult (EKReminder *obj1, EKReminder *obj2) {
            return [obj1.calendar.calendarIdentifier compare:obj2.calendar.calendarIdentifier];
        }];
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
                                       completion:^(BOOL granted, NSError *_Nullable error) {
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
