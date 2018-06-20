//
//  RemindersTableView.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/20.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <DSUtility/UIImage+ColorHelper.h>
#import "RemindersTableView.h"

#define kRemindersTableCellID @"RemindersTableCellID"

#pragma mark - Functions

NSString * GetTimeDistance(NSDate *date1, NSDate *date2)
{
    if (!(date1 && date2)) {
        return nil;
    }

    NSTimeInterval interval = fabs(date1.timeIntervalSince1970 - date2.timeIntervalSince1970);

    if (interval < 60) {
        return [NSString stringWithFormat:@"%.0f second(s)", interval];
    } else if (interval < 60 * 60) {
        return [NSString stringWithFormat:@"%.0f minute(s)", interval  / 60];
    } else if (interval < 60 * 60 * 24) {
        return [NSString stringWithFormat:@"%.0f hour(s)", interval  / 60 / 60];
    } else if (interval < 60 * 60 * 24 * 30) {
        return [NSString stringWithFormat:@"%.0f day(s)", interval  / 60 / 60 / 24];
    } else if (interval < 60 * 60 * 24 * 30 * 12) {
        return [NSString stringWithFormat:@"%.0f month(s)", interval  / 60 / 60 / 24 / 30];
    } else {
        return [NSString stringWithFormat:@"%.0f year(s)", interval  / 60 / 60 / 24 / 30 / 12];
    }
}

#pragma mark - RemindersTableViewCell

@interface RemindersTableViewCell : UITableViewCell

@end

@implementation RemindersTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier]) {
    }

    return self;
}

@end

#pragma mark - RemindersTableView

@interface RemindersTableView () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation RemindersTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    if (self = [super initWithFrame:frame style:UITableViewStyleGrouped]) {
        self.dataSource = self;
        self.delegate = self;

        self.rowHeight = 46;
        self.refreshControl = [UIRefreshControl new];
        [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

        [self registerClass:[RemindersTableViewCell class] forCellReuseIdentifier:kRemindersTableCellID];
    }

    return self;
}

#pragma mark - Property

- (void)setDataItems:(NSArray<EKGroup *> *)dataItems
{
    _dataItems = dataItems;
    [self reloadData];
}

#pragma mark - Action

- (void)refresh:(id)sender
{
    if (self.refreshBlock) {
        self.refreshBlock(sender);
    } else {
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataItems[section].reminders.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RemindersTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kRemindersTableCellID];
    EKReminder *reminder = self.dataItems[indexPath.section].reminders[indexPath.row];

    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.textLabel.text = reminder.title;

    if (reminder.hasAlarms) {
        EKAlarm *alarm = reminder.alarms.firstObject;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ later", GetTimeDistance(alarm.absoluteDate, NSDate.date)];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [UIView new];
    UIImageView *imageView = [UIImageView new];
    UILabel *label = [UILabel new];

    EKCalendar *calendar = self.dataItems[section].calendar;
    CGFloat radius = 16;

    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = radius / 2;
    imageView.image = [UIImage imageWithColor:[UIColor colorWithCGColor:calendar.CGColor]];
    label.text = calendar.title;
    label.textColor = RGB(40, 40, 40);
    label.font = [UIFont boldSystemFontOfSize:23];
    [header addSubviews:imageView, label, nil];

    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(header.left).offset(10);
        make.centerY.equalTo(label.centerY);
        make.width.height.equalTo(@(radius));
    }];

    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(imageView.right).offset(8);
        make.top.bottom.right.equalTo(header);
        make.height.equalTo(@50);
    }];

    return header;
}

@end
