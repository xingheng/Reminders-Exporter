//
//  RemindersTableView.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/20.
//  Copyright © 2018 WillHan. All rights reserved.
//

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

        self.rowHeight = 50;
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.dataItems[section].calendar.title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataItems[section].reminders.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kRemindersTableCellID];
    EKReminder *reminder = self.dataItems[indexPath.section].reminders[indexPath.row];

    cell.textLabel.text = reminder.title;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
