//
//  EKGroup.h
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

@interface EKGroup : NSObject

@property (nonatomic, strong, readonly) EKCalendar *calendar;

@property (nonatomic, strong, readonly) NSArray<EKReminder *> *reminders;

- (instancetype)initWithCalendar:(EKCalendar *)calendar;

- (void)addReminder:(EKReminder *)reminder;

- (NSURL *)serializeToFile:(NSURL *)directory;

@end
