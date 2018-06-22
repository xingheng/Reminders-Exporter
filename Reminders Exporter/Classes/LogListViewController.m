//
//  LogListViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/22.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <RETableViewManager/RETableViewManager.h>
#import <DSUtility/AlertHelper.h>
#import "LogListViewController.h"
#import "LogReviewViewController.h"

@interface LogListViewController () <RETableViewManagerDelegate>

@property (nonatomic, strong) RETableViewManager *tableManager;

@property (nonatomic, strong) NSArray<DDLogFileInfo *> *logFileInfos;

@end

@implementation LogListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Logs";
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Property

- (void)setLogFileInfos:(NSArray<DDLogFileInfo *> *)logFileInfos
{
    _logFileInfos = logFileInfos;
    [self _reloadTable];
}

#pragma mark - Private

- (void)_reloadTable
{
    [self.tableManager.sections makeObjectsPerformSelector:@selector(removeAllItems)];
    [self.tableManager removeAllSections];

    @weakify(self);

    RETableViewSection *section = nil;

    for (DDLogFileInfo *fileInfo in self.logFileInfos) {
        section = [RETableViewSection sectionWithHeaderTitle:fileInfo.fileName];

        void (^ block)(RETableViewItem *) = ^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];

            LogReviewViewController *reviewVC = [LogReviewViewController new];
            reviewVC.fileInfo = fileInfo;
            [self pushViewController:reviewVC];
        };

        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Create"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:block];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = fileInfo.creationDate.descriptionForCurrentLocale;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Modify"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:block];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = fileInfo.modificationDate.descriptionForCurrentLocale;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Size"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:block];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = [NSString stringWithFormat:@"%.3fKB", fileInfo.fileSize / 1024.0];
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Archived"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:block];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = fileInfo.isArchived ? @"YES" : @"NO";
        [section addItem:item];

        [self.tableManager addSection:section];
    }

    /*
       section = [RETableViewSection section];

       if (section) {
        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Remove All"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];

                                                  [[REFileLogger sharedInstance].logFileManager createNewLogFile];
        }];
        item.style = UITableViewCellStyleDefault;
        item.textAlignment = NSTextAlignmentCenter;
        [section addItem:item];
       }

       [self.tableManager addSection:section];
     */

    [self.tableManager.tableView reloadData];
}

#pragma mark - BuildViewDelegate

- (void)buildSubview:(UIView *)containerView controller:(BaseViewController *)viewController
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];

    tableView.estimatedSectionHeaderHeight = 0;
    tableView.estimatedSectionFooterHeight = 0;
    self.tableManager = [[RETableViewManager alloc] initWithTableView:tableView delegate:self];
    [containerView addSubviews:tableView, nil];

    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(containerView);
    }];
}

- (void)loadDataForController:(BaseViewController *)viewController
{
    self.logFileInfos = [REFileLogger sharedInstance].logFileManager.sortedLogFileInfos;
}

- (void)tearDown:(BaseViewController *)viewController
{
}

- (BOOL)shouldInvalidateDataForController:(BaseViewController *)viewController
{
    return NO;
}

@end
