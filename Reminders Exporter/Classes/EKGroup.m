//
//  EKGroup.m
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "EKGroup.h"

static BOOL ExportDictionaryToJSONFile(NSDictionary *dict, NSURL *path)
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];

    if (!jsonData) {
        NSLog(@"%s: error: %@", __func__, error.localizedDescription);
        return NO;
    }

    [[NSFileManager defaultManager] removeItemAtURL:path error:nil];

    NSString *content = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    if (![content writeToURL:path atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        NSLog(@"%s: error: %@", __func__, error.localizedDescription);
        return NO;
    }

    return YES;
}


#pragma mark - EKGroup

@interface EKGroup ()

@property (nonatomic, strong) EKCalendar *calendar;

@property (nonatomic, strong) NSMutableArray<EKReminder *> *allReminders;

@end

@implementation EKGroup

#pragma mark - Public

- (instancetype)initWithCalendar:(EKCalendar *)calendar
{
    if (self = [super init]) {
        self.calendar = calendar;
    }

    return self;
}

- (void)addReminder:(EKReminder *)reminder
{
    [self.allReminders addObject:reminder];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        EKGroup *group = object;
        return [group.calendar.calendarIdentifier isEqualToString:self.calendar.calendarIdentifier];
    }

    return [super isEqual:object];
}

- (NSURL *)serializeToFile:(NSURL *)directory
{
    NSMutableDictionary *dict = [[self class] _entityForCalendar:self.calendar];
    NSArray *arrDict = [self.allReminders bk_map:^id (EKReminder *obj) {
        return [[self class] _entityForReminder:obj];
    }];

    dict[@"reminders"] = arrDict;

    NSString *filename = [NSString stringWithFormat:@"%@-%@.json", self.calendar.title, [self _calendarType]];
    NSURL *fileURL = [directory URLByAppendingPathComponent:filename];

    if (!ExportDictionaryToJSONFile(dict, fileURL)) {
        NSAssert(NO, @"Failed to serialize the entity to file!");
        return nil;
    }

    return fileURL;
}

#pragma mark - Property

- (NSArray<EKReminder *> *)reminders
{
    return self.allReminders;
}

- (NSMutableArray<EKReminder *> *)allReminders
{
    if (!_allReminders) {
        _allReminders = [NSMutableArray new];
    }

    return _allReminders;
}

#pragma mark - Private

- (NSString *)_calendarType
{
    switch (self.calendar.type) {
        case EKCalendarTypeLocal:
            return @"Local";
        case EKCalendarTypeCalDAV:
            return @"CalDAV";
        case EKCalendarTypeExchange:
            return @"Exchange";
        case EKCalendarTypeSubscription:
            return @"Subscription";
        case EKCalendarTypeBirthday:
            return @"Birthday";
    }
}

+ (NSMutableDictionary *)_entityForCalendar:(EKCalendar *)calendar
{
    NSMutableDictionary *dict = [NSMutableDictionary new];

    dict[@"id"] = calendar.calendarIdentifier;
    dict[@"title"] = calendar.title;
    dict[@"type"] = @(calendar.type);
    dict[@"source"] = @{
        @"id": calendar.source.sourceIdentifier,
        @"name": calendar.source.title,
        @"type": @(calendar.source.sourceType)
    };

    return dict;
}

+ (NSMutableDictionary *)_entityForReminder:(EKReminder *)reminder
{
    NSMutableDictionary *dict = [NSMutableDictionary new];

    dict[@"id"] = reminder.calendarItemIdentifier;
    dict[@"server_id"] = reminder.calendarItemExternalIdentifier;
    dict[@"title"] = reminder.title;
    dict[@"location"] = reminder.location;
    dict[@"notes"] = reminder.notes;
    dict[@"URL"] = reminder.URL;
    dict[@"lastModifiedDate"] = @(reminder.lastModifiedDate.timeIntervalSince1970);
    dict[@"creationDate"] = @(reminder.creationDate.timeIntervalSince1970);
    dict[@"timeZone"] = reminder.timeZone.name;
    dict[@"alarms"] = [reminder.alarms bk_map:^id (EKAlarm *obj) {
        return @{ @"absoluteDate": @(obj.absoluteDate.timeIntervalSince1970) };
    }];

    return dict;
}

@end
