//
//  SettingsViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/19.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <RETableViewManager/RETableViewManager.h>
#import <DSUtility/AlertHelper.h>
#import <DSUtility/NSString+ValueValidation.h>
#import <DSUtility/NSString+Date.h>
#import "SettingsViewController.h"
#import "LogListViewController.h"
#import "AboutViewController.h"
#import "UserPreferences.h"

typedef NS_OPTIONS (NSUInteger, CredentialType) {
    CredentialTypeNone    = 0,
    CredentialTypeHTTPS   = 1 << 0,
        CredentialTypeSSH = 1 << 1
};

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

@interface SettingsViewController () <RETableViewManagerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) RETableViewManager *tableManager;

@property (nonatomic, assign) CredentialType credentialType;

@end

@implementation SettingsViewController

+ (void)load
{
    GenerateKeyPair();
}

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

#pragma mark - Property

- (void)setCredentialType:(CredentialType)credentialType
{
    if (_credentialType != credentialType) {
        _credentialType = credentialType;
        [self _reloadTable];
    }
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

    if (self.credentialType & CredentialTypeHTTPS) {
        [self.tableManager addSection:[self _sectionForNewCredentialForHTTPS]];
    }

    if (self.credentialType & CredentialTypeSSH) {
        [self.tableManager addSection:[self _sectionForNewCredentialForSSH]];
    }

    section = [RETableViewSection sectionWithHeaderTitle:strHeader footerTitle:@"Notes: The credential you filled will be saved to local storage ONLY without any encryptions, please keep it in safe by yourself for the app sandbox!"];

    if (section) {
        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Add a New Credential"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];

            AlertHelper *alert = [AlertHelper alertControllerWithTitle:@"Choose a credential type"
                                                               message:@""
                                                        preferredStyle:UIAlertControllerStyleActionSheet];

            [alert addDefaultAction:@"HTTPS"
                            handler:^(UIAlertAction *_Nullable action) {
                self.credentialType |= CredentialKeyTypeHTTPS;
            }];
            [alert addDefaultAction:@"SSH"
                            handler:^(UIAlertAction *_Nullable action) {
                self.credentialType |= CredentialKeyTypeSSH;
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

        NSUInteger type = [value[CredentialKeyType] unsignedIntegerValue];

        if (type == CredentialKeyTypeHTTPS) {
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
        } else if (type == CredentialKeyTypeSSH) {
            NSString *filePrefix = value[CredentialKeySSHKey];

            item = [RETableViewItem itemWithTitle:@"SSH Key"
                                    accessoryType:UITableViewCellAccessoryDisclosureIndicator
                                 selectionHandler:^(RETableViewItem *item) {
                @strongify(self);
                [item deselectRowAnimated:YES];

                NSString *publicFilePath = GetSSHKeyFullPath(kSSHKeyPublicFileName(filePrefix)).path;
                NSString *privateFilePath = GetSSHKeyFullPath(kSSHKeyPrivateFileName(filePrefix)).path;

                [self _sendMail:[NSString stringWithFormat:@"My SSH RSA Key - %@", site]
                           body:@"Check out your ssh key pair in the attachment, feel free to send it to the target code hosting server."
                    attachments:@[publicFilePath, privateFilePath]];
            }];
            item.style = UITableViewCellStyleValue1;
            item.detailLabelText = filePrefix;
            [section addItem:item];
        }

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
                if (type == CredentialKeyTypeSSH) {
                    NSString *strName = value[CredentialKeySSHKey];
                    NSString *publicFilePath = GetSSHKeyFullPath(kSSHKeyPublicFileName(strName)).path;
                    NSString *privateFilePath = GetSSHKeyFullPath(kSSHKeyPrivateFileName(strName)).path;
                    DeleteFile(publicFilePath, nil);
                    DeleteFile(privateFilePath, nil);
                }

                SetCredential(site, nil);
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

- (RETableViewSection *)_sectionForNewCredentialForHTTPS
{
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"New HTTPS Credential Info"];

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

            SetCredential(strSite, @{ CredentialKeyUsername: strUsername,
                                      CredentialKeyPassword: strPassword,
                                      CredentialKeyType: @(CredentialKeyTypeHTTPS) });

            self.credentialType ^= CredentialTypeHTTPS;
        }];
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Cancel"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];
            self.credentialType ^= CredentialTypeHTTPS;
        }];
        [section addItem:item];
    }

    return section;
}

- (RETableViewSection *)_sectionForNewCredentialForSSH
{
    RETableViewSection *section = [RETableViewSection sectionWithHeaderTitle:@"New SSH Credential Info" footerTitle:@"ssh-keygen -f <filename>"];

    @weakify(self);

    if (section) {
        RETextItem *textItemSite = [RETextItem itemWithTitle:@"Site"
                                                       value:@""
                                                 placeholder:@"github.com"];
        textItemSite.style = UITableViewCellStyleValue1;
        textItemSite.autocorrectionType = UITextAutocorrectionTypeNo;
        [section addItem:textItemSite];

        RETextItem *textItemNamePrefix = [RETextItem itemWithTitle:@"Filename Prefix"
                                                             value:@""
                                                       placeholder:@"id_rsa"];
        textItemNamePrefix.style = UITableViewCellStyleValue1;
        textItemNamePrefix.autocorrectionType = UITextAutocorrectionTypeNo;
        [section addItem:textItemNamePrefix];

        @weakify(textItemSite);
        @weakify(textItemNamePrefix);

        RETableViewItem *item = [RETableViewItem itemWithTitle:@"Generate"
                                                 accessoryType:UITableViewCellAccessoryNone
                                              selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            @strongify(textItemSite);
            @strongify(textItemNamePrefix);
            [item deselectRowAnimated:YES];

            NSString *strSite = [textItemSite.value trimEmptySpace];
            NSString *strName = [textItemNamePrefix.value trimEmptySpace];

            if (strSite.length <= 0) {
                return;
            }

            if (IsNullString(strName)) {
                NSString *strDate = [NSDate.date stringFromDateFormat:kDateFormat_Date_Time_Second];
                strName = [NSString stringWithFormat:@"%@-%@", strSite, strDate];
            }

            NSString *publicFilePath = GetSSHKeyFullPath(kSSHKeyPublicFileName(strName)).path;
            NSString *privateFilePath = GetSSHKeyFullPath(kSSHKeyPrivateFileName(strName)).path;

            if (IsFileExist(publicFilePath) || IsFileExist(privateFilePath)) {
                HUDToast(self.view).title(@"Key files exist!").show();
            }

            if (![self _generateRSAKeys:strName]) {
                HUDToast(self.view).title(@"Failed to generate rsa key files.").show();
                return;
            }

            SetCredential(strSite, @{ CredentialKeySSHKey: strName,
                                      CredentialKeyType: @(CredentialKeyTypeSSH) });

            self.credentialType ^= CredentialTypeSSH;
        }];
        [section addItem:item];

        item = [RETableViewItem itemWithTitle:@"Cancel"
                                accessoryType:UITableViewCellAccessoryNone
                             selectionHandler:^(RETableViewItem *item) {
            @strongify(self);
            [item deselectRowAnimated:YES];
            self.credentialType ^= CredentialTypeSSH;
        }];
        [section addItem:item];
    }

    return section;
}

- (BOOL)_generateRSAKeys:(NSString *)prefix
{
    NSString *publicFilePath = GetSSHKeyFullPath(kSSHKeyPublicFileName(prefix)).path;
    NSString *privateFilePath = GetSSHKeyFullPath(kSSHKeyPrivateFileName(prefix)).path;

    void (^ cleanup)(void) = ^{
        DeleteFile(publicFilePath, nil);
        DeleteFile(privateFilePath, nil);
    };

    cleanup();

    if (!generate_key(publicFilePath.UTF8String, privateFilePath.UTF8String)) {
        cleanup();
        DDLogError(@"Failed to generate rsa key files: %@", publicFilePath);
        return NO;
    }

    return YES;
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

- (void)_sendMail:(NSString *)title body:(NSString *)body attachments:(NSArray<NSString *> *)paths
{
    if (![MFMailComposeViewController canSendMail]) {
        DDLogError(@"Cannot send mail for this device!");
        return;
    }

    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];

    mc.mailComposeDelegate = self;
    [mc setSubject:title];
    [mc setMessageBody:body isHTML:NO];

    for (NSString *path in paths) {
        NSData *fileData = [[NSData alloc] initWithContentsOfFile:path];
        [mc addAttachmentData:fileData mimeType:@"text/plain" fileName:path.lastPathComponent];
    }

    [self presentViewController:mc animated:YES completion:nil];
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

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error
{
    if (error) {
        DDLogError(@"%s: error: %@", __func__, error);
        HUDToast(controller.view).title(@"Failed to send mail!").subTitle(error.description).delay(5).show();
        return;
    }

    [controller dismissViewControllerAnimated:YES
                                   completion:^{
        NSString *strTitle = nil;

        switch (result) {
            case MFMailComposeResultSent:
                strTitle = @"Sent!";
                break;

            case MFMailComposeResultSaved:
                strTitle = @"Saved!";
                break;

            case MFMailComposeResultCancelled:
                strTitle = @"Cancelled!";
                break;

            default:
                break;
        }

        HUDToastInWindow().title(strTitle).show();
    }];
}

@end
