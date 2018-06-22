//
//  RepositoryViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/15.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <RETableViewManager/RETableViewManager.h>
#import <RETableViewManager/RETableViewOptionsController.h>
#import <DSUtility/AlertHelper.h>
#import "RepositoryViewController.h"
#import "UserPreferences.h"
#import "Repo+UserActions.h"
#import "EKGroup+Reminders.h"

@interface RepositoryViewController () <RETableViewManagerDelegate>

@property (nonatomic, strong) RETableViewManager *tableManager;

@property (nonatomic, assign) BOOL showReservedNewRemote;

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

#pragma mark - Private

- (void)_reloadTable
{
    [self.tableManager.sections makeObjectsPerformSelector:@selector(removeAllItems)];
    [self.tableManager removeAllSections];

    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"Local Info"];
    @weakify(self);

    if (section) {
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

        item = [RETableViewItem itemWithTitle:@"Latest Commit"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = [NSString stringWithFormat:@"%@", [currentBranch targetCommitWithError:nil].commitDate];
        [section addItem:item];

        NSDictionary *signatureDict = GetSignature();

        item = [RETableViewItem itemWithTitle:@"Signature"
                                accessoryType:UITableViewCellAccessoryDetailButton
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.accessoryButtonTapHandler = ^(id item) {
            NSString *strMessage = [NSString stringWithFormat:@"Name: %@\nEmail: %@", signatureDict[SignatureUsername], signatureDict[SignatureEmail]];
            HUDToast(self.view).title(@"Signature").subTitle(strMessage).delay(2).show();
        };
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = signatureDict[SignatureUsername];
        [section addItem:item];
    }

    [self.tableManager addSection:section];
    NSArray<NSString *> *remoteNames = [self.repository remoteNamesWithError:nil];

    for (NSString *remoteName in remoteNames) {
        GTRemote *remote = [GTRemote remoteWithName:remoteName inRepository:self.repository error:nil];
        [self.tableManager addSection:[self _sectionForRemote:remote]];
    }

    if (self.showReservedNewRemote) {
        [self.tableManager addSection:[self _sectionForNewRemote]];
    }

    section = [RETableViewSection section];

    if (section) {
        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Add Remote"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];
            self.showReservedNewRemote = YES;
            [self _reloadTable];
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
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"Remote Info"];

    @weakify(self);

    if (section) {
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

        NSString *urlHost = [NSURL URLWithString:remote.URLString].host;
        NSDictionary *credentialDict = GetCredentials()[urlHost];

        item = [RETableViewItem itemWithTitle:@"Credential"
                                accessoryType:UITableViewCellAccessoryDetailButton
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.accessoryButtonTapHandler = ^(id item) {
            NSString *strMessage = [NSString stringWithFormat:@"Site: %@\nUsername: %@", urlHost, credentialDict[CredentialKeyUsername]];
            HUDToast(self.view).title(@"Credential").subTitle(strMessage).delay(2).show();
        };
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = credentialDict[CredentialKeyUsername] ? : @"None";
        [section addItem:item];

        GTBranch *remoteBranch = [[self.repository remoteBranchesWithError:nil] bk_match:^BOOL (GTBranch *obj) {
            return [obj.remoteName isEqualToString:remote.name];
        }];

        item = [RETableViewItem itemWithTitle:@"Pull"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];

            @weakify(self);
            NSError *error = nil;

            if (![self.repository pullFromRemote:remote.name
                                           merge:^BOOL {
                @strongify(self);
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);

                [EKGroup fetchRemindersToRepo:self.repository
                                   completion:^(BOOL result, NSArray<EKGroup *> *groups) {
                    dispatch_semaphore_signal(semaphore);
                }];

                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                return NO;
            }
                                           error:&error]) {
                HUDToast(self.view).title(@"Pull changes failed!").subTitle(error.description).delay(5).show();
            }
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = [remoteBranch targetCommitWithError:nil].commitDate.descriptionForCurrentLocale;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Push"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];
            [self.repository pushToRemotes:nil];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = [remoteBranch targetCommitWithError:nil].commitDate.descriptionForCurrentLocale;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Delete"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
            @strongify(self);

            AlertHelper *alert = [AlertHelper alertControllerWithTitle:@"Deleting this remote?"
                                                               message:[NSString stringWithFormat:@"git remote remove %@", remote.name]
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

- (RETableViewSection *)_sectionForNewRemote
{
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"New Remote Info"];

    @weakify(self);

    if (section) {
        RETextItem *textItemName = [RETextItem itemWithTitle:@"Remote Name"
                                                       value:@""
                                                 placeholder:@"origin"];
        textItemName.style = UITableViewCellStyleValue1;
        textItemName.autocorrectionType = UITextAutocorrectionTypeNo;
        [section addItem:textItemName];

        RETextItem *textItemURL = [RETextItem itemWithTitle:@"URL"
                                                      value:@""
                                                placeholder:@"https://github.com/username/reminders-data.git"];
        textItemURL.style = UITableViewCellStyleValue1;
        textItemURL.autocorrectionType = UITextAutocorrectionTypeNo;
        [section addItem:textItemURL];

        @weakify(textItemName);
        @weakify(textItemURL);

        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Save"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            @strongify(textItemName);
            @strongify(textItemURL);

            [item deselectRowAnimated:YES];
            NSString *strName = textItemName.value;
            NSString *strURL = textItemURL.value;

            if (IsNullString(strName)) {
                strName = textItemName.placeholder;
            }

            NSError *error = nil;
            GTRemote *remote = [GTRemote createRemoteWithName:strName
                                                    URLString:strURL
                                                 inRepository:self.repository
                                                        error:&error];

            if (!remote || error) {
                HUDToast(self.view).title(@"Failed to add remote").subTitle(error.description).delay(5).show();
                return;
            }

            self.showReservedNewRemote = NO;
            [self _reloadTable];
        }];
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Cancel"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];
            self.showReservedNewRemote = NO;
            [self _reloadTable];
        }];
        [section addItem:item];
    }

    return section;
}

- (void)_removeRemote:(GTRemote *)remote
{
    int err = git_remote_delete(self.repository.git_repository, remote.name.UTF8String);

    if (err != 0) {
        DDLogError(@"%s: error code: %d", __func__, err);
        HUDToast(self.view).title(@"Remove the remote failed!").delay(5).show();
        return;
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
