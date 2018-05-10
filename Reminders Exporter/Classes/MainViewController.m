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

    switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder]) {
        case EKAuthorizationStatusAuthorized:
            NSLog(@"Authorized!");
            [self _fetchReminders];
            break;

        case EKAuthorizationStatusDenied:
        case EKAuthorizationStatusRestricted:
            NSLog(@"Failed!");
            break;

        case EKAuthorizationStatusNotDetermined:
            NSLog(@"Not Yet!");

            [self.store requestAccessToEntityType:EKEntityTypeReminder
                                       completion:^(BOOL granted, NSError *_Nullable error) {
            if (granted) {
                [self _fetchReminders];
            } else {
                NSLog(@"%s: %@", __func__, error);
            }
        }];
            break;
    }
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
    NSPredicate *predicate = [self.store predicateForRemindersInCalendars:nil];

    [self.store fetchRemindersMatchingPredicate:predicate
                                     completion:^(NSArray *reminders) {
        for (EKReminder *reminder in reminders) {
            NSLog(@"%@", reminder);
        }
    }];
}

@end
