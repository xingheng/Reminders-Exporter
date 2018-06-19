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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(rightBarButtonTapped:)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Property

#pragma mark - Actions

- (void)rightBarButtonTapped:(id)sender
{
    [self _reloadTable];
}

- (void)addRemoteButtonTapped:(id)sender
{
    AlertHelper *alert = [AlertHelper alertControllerWithTitle:@"Add a new remote entry"
                                                       message:@"git remote add <origin>"
                                                preferredStyle:UIAlertControllerStyleAlert];

    @weakify(alert);

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"origin";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"https://github.com/username/reminders-data.git";
    }];

    [alert addDefaultAction:@"Add"
                    handler:^(UIAlertAction *action) {
        @strongify(alert);
        NSString *strName = alert.textFields[0].text;
        NSString *strURL = alert.textFields[1].text;

        if (IsNullString(strName)) {
            strName = alert.textFields[0].placeholder;
        }

        NSError *error = nil;
        GTRemote *remote = [GTRemote createRemoteWithName:strName
                                                URLString:strURL
                                             inRepository:self.repository
                                                    error:&error];

        if (!remote || error) {
            HUDToast(self.view).title(@"Failed to add remote").subTitle(error.description).delay(5).show();
        } else {
            [self _reloadTable];
        }
    }];
    [alert addCancelAction:@"Cancel"
                   handler:nil];
    [alert presentInViewController:self];
}

#pragma mark - Private

- (void)_reloadTable
{
    [self.tableManager.sections makeObjectsPerformSelector:@selector(removeAllItems)];
    [self.tableManager removeAllSections];

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
        [self.tableManager addSection:[self _sectionForRemote:remote]];
    }

    section = [RETableViewSection section];

    if (section) {
        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Add Remote"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];
            [self addRemoteButtonTapped:item];
        }];
        item.style = UITableViewCellStyleDefault;
        item.textAlignment = NSTextAlignmentCenter;
        [section addItem:item];

        [self.tableManager addSection:section];
    }

    [self.tableManager.tableView reloadData];
}

- (RETableViewSection *)_sectionForRemote:(GTRemote *)remote
{
    RETableViewSection *section = [RETableViewSection section];

    @weakify(self);

    if (section) {
        section.headerTitle = @"Remote Info";

        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Remote Name"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = remote.name;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"URL"
                                accessoryType:UITableViewCellAccessoryDetailButton
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.accessoryButtonTapHandler = ^(id item) {
            [UIPasteboard generalPasteboard].string = remote.URLString;
            HUDToast(self.view).title(@"Copied!").show();
        };
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = remote.URLString;
        [section addItem:item];

        GTBranch *remoteBranch = [[self.repository remoteBranchesWithError:nil] bk_match:^BOOL (GTBranch *obj) {
            return [obj.remoteName isEqualToString:remote.name];
        }];

        item = [RETableViewItem itemWithTitle:@"Push"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = [remoteBranch targetCommitWithError:nil].commitDate.description;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Delete"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
            @strongify(self);

            AlertHelper *alert = [AlertHelper alertControllerWithTitle:@"Deleting this remote?"
                                                               message:@"git remote remove <origin>"
                                                        preferredStyle:UIAlertControllerStyleActionSheet];
            [alert addDestructiveAction:@"Delete"
                                handler:^(UIAlertAction *action) {
                [self _removeRemote:remote];
            }];
            [alert addCancelAction:@"Cancel"
                           handler:nil];
            [alert presentInViewController:self];
        }];
        item.style = UITableViewCellStyleDefault;
        [section addItem:item];
    }

    return section;
}

- (void)_removeRemote:(GTRemote *)remote
{
    NSError *error = nil;
    NSString *prefix = [NSString stringWithFormat:@"remote.%@", remote.name];
    GTConfiguration *config = [self.repository configurationWithError:&error];

    for (NSString *key in config.configurationKeys) {
        if ([key hasPrefix:prefix]) {
            [config deleteValueForKey:key
                                error:&error];
            DDLogError(@"%@", error);
        }
    }

    if (error) {
        HUDToast(self.view).title(@"Remove the remote failed!").subTitle(error.description).delay(5).show();
    }

    [self _reloadTable];
}

#pragma mark - BuildViewDelegate

- (void)buildSubview:(UIView *)containerView controller:(BaseViewController *)viewController
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];

    tableView.estimatedSectionHeaderHeight = 0;
    tableView.estimatedSectionFooterHeight = 0;
    self.tableManager = [[RETableViewManager alloc] initWithTableView:tableView delegate:self];

    [self _reloadTable];
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
