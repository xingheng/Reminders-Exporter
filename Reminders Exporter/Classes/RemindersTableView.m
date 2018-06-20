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

        [self registerClass:[UITableViewCell class] forCellReuseIdentifier:kRemindersTableCellID];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kRemindersTableCellID];
    EKReminder *reminder = self.dataItems[indexPath.section].reminders[indexPath.row];

    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.textLabel.text = reminder.title;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
