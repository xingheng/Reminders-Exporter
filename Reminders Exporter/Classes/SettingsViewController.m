//
//  SettingsViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/19.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <RETableViewManager/RETableViewManager.h>
#import <DSUtility/AlertHelper.h>
#import <DSUtility/NSString+ValueValidation.h>
#import "SettingsViewController.h"
#import "LogListViewController.h"
#import "AboutViewController.h"
#import "UserPreferences.h"

#pragma mark - Functions

void OpenAppSettings(void (^completion)(BOOL success))
{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    UIApplication *application = [UIApplication sharedApplication];

    if ([application canOpenURL:url]) {
        [application openURL:url options:@{} completionHandler:completion];
    }
}

#pragma mark - SettingsViewController

@interface SettingsViewController () <RETableViewManagerDelegate>

@property (nonatomic, strong) RETableViewManager *tableManager;

@property (nonatomic, assign) BOOL showReservedNewCredential;

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Settings";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

- (void)_reloadTable
{
    [self.tableManager.sections makeObjectsPerformSelector:@selector(removeAllItems)];
    [self.tableManager removeAllSections];

    NSDictionary *signatureDict = GetSignature();

    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"Signature"];
    @weakify(self);

    if (section) {
        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Name"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];

            [self _editField:item.detailLabelText
                 placeholder:@"Name"
                  completion:^(NSString *value) {
                if ([value trimEmptySpace].length > 0) {
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:GetSignature()];
                    [dict setValue:value
                            forKey:SignatureUsername];
                    SetSignature(dict);
                    item.detailLabelText = value;
                    [item reloadRowWithAnimation:UITableViewRowAnimationNone];
                }
            }];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = signatureDict[SignatureUsername];
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Email"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];

            [self _editField:item.detailLabelText
                 placeholder:@"Email"
                  completion:^(NSString *value) {
                if ([value trimEmptySpace].length > 0) {
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:GetSignature()];
                    [dict setValue:value
                            forKey:SignatureEmail];
                    SetSignature(dict);
                    item.detailLabelText = value;
                    [item reloadRowWithAnimation:UITableViewRowAnimationNone];
                }
            }];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = signatureDict[SignatureEmail];
        [section addItem:item];
    }

    [self.tableManager addSection:section];

    NSString *strHeader = nil;
    NSDictionary *credentialDict = GetCredentials();

    if (credentialDict.count >  0) {
        for (NSString *key in credentialDict) {
            [self.tableManager addSection:[self _sectionForCredential:credentialDict[key] site:key]];
        }
    } else {
        strHeader = @"No any credentials yet";
    }

    if (self.showReservedNewCredential) {
        [self.tableManager addSection:[self _sectionForNewCredential]];
    }

    section = [RETableViewSection sectionWithHeaderTitle:strHeader footerTitle:@"Notes: The credential you filled will be saved to local storage ONLY without any encryptions, please keep it in safe by yourself for the app sandbox!"];

    if (section) {
        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Add a New Credential"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];
            self.showReservedNewCredential = YES;
            [self _reloadTable];
        }];
        item.style = UITableViewCellStyleDefault;
        item.textAlignment = NSTextAlignmentCenter;
        [section addItem:item];

        [self.tableManager addSection:section];
    }

    section = [RETableViewSection section];

    if (section) {
        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Preferences"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
            OpenAppSettings(nil);
        }];
        item.style = UITableViewCellStyleDefault;
        item.textAlignment = NSTextAlignmentCenter;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Logs"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];

            [self pushViewController:[LogListViewController new]];
        }];
        item.style = UITableViewCellStyleDefault;
        item.textAlignment = NSTextAlignmentCenter;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"About"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];
            [self pushViewController:[AboutViewController new]];
        }];
        item.style = UITableViewCellStyleDefault;
        item.textAlignment = NSTextAlignmentCenter;
        [section addItem:item];

        [self.tableManager addSection:section];
    }

    [self.tableManager.tableView reloadData];
}

- (RETableViewSection *)_sectionForCredential:(NSDictionary *)value site:(NSString *)site
{
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"Credential"];

    @weakify(self);

    if (section) {
        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Site"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = site;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Username"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = value[CredentialKeyUsername];
        [section addItem:item];

        NSMutableString *password = [NSMutableString new];

        for (NSUInteger idx = 0; idx < ((NSString *)value[CredentialKeyPassword]).length; idx++) {
            [password appendString:@"*"];
        }

        item = [RETableViewItem itemWithTitle:@"Password"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
        }];
        item.style = UITableViewCellStyleValue1;
        item.detailLabelText = password;
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Delete"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            [item deselectRowAnimated:YES];
            @strongify(self);

            AlertHelper *alert = [AlertHelper alertControllerWithTitle:@"Deleting this credential?"
                                                               message:[NSString stringWithFormat:@"Site: %@", site]
                                                        preferredStyle:UIAlertControllerStyleActionSheet];
            [alert addDestructiveAction:@"Delete"
                                handler:^(UIAlertAction *action) {
                NSMutableDictionary *credentialDict = [[NSMutableDictionary alloc] initWithDictionary:GetCredentials()];

                [credentialDict setValue:nil
                                  forKey:site];

                SetCredentials(credentialDict);
                [self _reloadTable];
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

- (RETableViewSection *)_sectionForNewCredential
{
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"New Credential Info"];

    @weakify(self);

    if (section) {
        RETextItem *textItemSite = [RETextItem itemWithTitle:@"Site"
                                                       value:@""
                                                 placeholder:@"github.com"];
        textItemSite.style = UITableViewCellStyleValue1;
        textItemSite.autocorrectionType = UITextAutocorrectionTypeNo;
        [section addItem:textItemSite];

        RETextItem *textItemUsername = [RETextItem itemWithTitle:@"Username"
                                                           value:@""
                                                     placeholder:@"username"];
        textItemUsername.style = UITableViewCellStyleValue1;
        textItemUsername.autocorrectionType = UITextAutocorrectionTypeNo;
        [section addItem:textItemUsername];

        RETextItem *textItemPassword = [RETextItem itemWithTitle:@"Password"
                                                           value:@""
                                                     placeholder:@"password"];
        textItemPassword.style = UITableViewCellStyleValue1;
        textItemPassword.secureTextEntry = YES;
        [section addItem:textItemPassword];

        @weakify(textItemSite);
        @weakify(textItemUsername);
        @weakify(textItemPassword);

        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Save"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            @strongify(textItemSite);
            @strongify(textItemUsername);
            @strongify(textItemPassword);
            [item deselectRowAnimated:YES];

            NSString *strSite = [textItemSite.value trimEmptySpace];
            NSString *strUsername = [textItemUsername.value trimEmptySpace];
            NSString *strPassword = textItemPassword.value;

            if (strSite.length <= 0) {
                return;
            }

            NSMutableDictionary *credentialDict = [[NSMutableDictionary alloc] initWithDictionary:GetCredentials()];

            [credentialDict setValue:@{ CredentialKeyUsername: strUsername,
                                        CredentialKeyPassword: strPassword }
                              forKey:strSite];

            SetCredentials(credentialDict);

            self.showReservedNewCredential = NO;
            [self _reloadTable];
        }];
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Cancel"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];
            self.showReservedNewCredential = NO;
            [self _reloadTable];
        }];
        [section addItem:item];
    }

    return section;
}

- (void)_editField:(NSString *)text placeholder:(NSString *)placeholder completion:(void (^)(NSString *value))completion
{
    AlertHelper *alert = [AlertHelper alertControllerWithTitle:@"Edit" message:@"" preferredStyle:UIAlertControllerStyleAlert];

    @weakify(alert);

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = text;
        textField.placeholder = placeholder;
    }];

    [alert addDefaultAction:@"Done"
                    handler:^(UIAlertAction *action) {
        @strongify(alert);

        if (completion) {
            completion(alert.textFields[0].text);
        }
    }];

    [alert addCancelAction:@"Cancel" handler:nil];
    [alert presentInViewController:self];
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

@end
