//
//  EKGroup+Reminders.h
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/20.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <EventKit/EventKit.h>
#import "EKGroup.h"
#import "Repo.h"

@interface EKGroup (Reminders)

+ (void)fetchReminders:(void (^)(NSArray<EKGroup *> *))completion;

+ (void)fetchRemindersToRepo:(Repo *)repository completion:(void (^)(BOOL, NSArray<EKGroup *> *))completion;

@end
