//
//  RepositoryViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/15.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <RETableViewManager/RETableViewManager.h>
#import <DSUtility/AlertHelper.h>
#import "RepositoryViewController.h"

@interface RepositoryViewController () <RETableViewManagerDelegate>

@property (nonatomic, strong) RETableViewManager *tableManager;

@end

@implementation RepositoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Repository";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Property

#pragma mark - BuildViewDelegate

- (void)buildSubview:(UIView *)containerView controller:(BaseViewController *)viewController
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];

    tableView.estimatedSectionHeaderHeight = 0;
    tableView.estimatedSectionFooterHeight = 0;
    self.tableManager = [[RETableViewManager alloc] initWithTableView:tableView delegate:self];

    RETableViewSection *section = [RETableViewSection section];
    @weakify(self);

    if (section) {
        section.headerTitle = @"Local Info";
        GTBranch *currentBranch = [self.repository currentBranchWithError:nil];

        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Repository Name"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = self.repository.fileURL.path.lastPathComponent;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Current Branch"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = currentBranch.name;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Latest commit"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = [NSString stringWithFormat:@"%@", [currentBranch targetCommitWithError:nil].commitDate];
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Signature"
                                accessoryType:UITableViewCellAccessoryDisclosureIndicator
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = [self.repository userSignatureForNow].name;
        [section addItem:item];
    }

    [self.tableManager addSection:section];
    NSArray<NSString *> *remoteNames = [self.repository remoteNamesWithError:nil];

    for (NSString *remoteName in remoteNames) {
        GTRemote *remote = [GTRemote remoteWithName:remoteName inRepository:self.repository error:nil];
        section = [RETableViewSection section];

        if (section) {
            section.headerTitle = @"Remotes";

            RETableViewItem *item = [RETableViewItem itemWithTitle:@"Remote Name"
                                                     accessoryType:UITableViewCellAccessoryNone
                                                  selectionHandler:^(RETableViewItem *item) {
                [item deselectRowAnimated:YES];
            }];
            item.style = UITableViewCellStyleValue1;
            item.detailLabelText = remote.name;
            [section addItem:item];

            item = [RETableViewItem itemWithTitle:@"URL"
                                    accessoryType:UITableViewCellAccessoryNone
                                 selectionHandler:^(RETableViewItem *item) {
                [item deselectRowAnimated:YES];
            }];
            item.style = UITableViewCellStyleValue1;
            item.detailLabelText = remote.URLString;
            [section addItem:item];

            item = [RETableViewItem itemWithTitle:@"Connected"
                                    accessoryType:UITableViewCellAccessoryNone
                                 selectionHandler:^(RETableViewItem *item) {
                [item deselectRowAnimated:YES];
            }];
            item.style = UITableViewCellStyleValue1;
            item.detailLabelText = remote.connected ? @"Yes" : @"No";
            [section addItem:item];

            [self.tableManager addSection:section];
        }
    }

    section = [RETableViewSection section];

    if (section) {
        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Add Remote"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];

            AlertHelper *alert = [AlertHelper alertControllerWithTitle:@"Add a new remote entry"
                                                               message:@"git remote add <origin>"
                                                        preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"origin";
            }];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"https://github.com/username/reminders-data.git";
            }];

            [alert addDefaultAction:@"Add"
                            handler:^(UIAlertAction *action) {
            }];
            [alert addCancelAction:@"Cancel"
                           handler:nil];
            [alert presentInViewController:self];
        }];
        item.style = UITableViewCellStyleDefault;
        item.textAlignment = NSTextAlignmentCenter;
        [section addItem:item];

        [self.tableManager addSection:section];
    }

    [containerView addSubviews:tableView, nil];

    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(containerView);
    }];
}

- (void)loadDataForController:(BaseViewController *)viewController
{
}

- (void)tearDown:(BaseViewController *)viewController
{
}

- (BOOL)shouldInvalidateDataForController:(BaseViewController *)viewController
{
    return NO;
}

#pragma mark - RETableViewManagerDelegate

- (void)tableView:(UITableView *)tableView willLayoutCellSubviews:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect originFrame = cell.textLabel.frame;

    cell.textLabel.frame = CGRectMake(originFrame.origin.x, originFrame.origin.y, originFrame.size.width + 100, originFrame.size.height);
}

- (void)tableView:(UITableView *)tableView willLoadCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.preservesSuperviewLayoutMargins = NO;
    cell.layoutMargins = UIEdgeInsetsZero;
    cell.separatorInset = UIEdgeInsetsZero;

    cell.textLabel.textColor = THEME_BLACK_COLOR;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
}

@end
