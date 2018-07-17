//
//  Repo+UserActions.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/19.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "Repo+UserActions.h"
#import "UserPreferences.h"

@implementation Repo (UserActions)

- (BOOL)commitWorkingFiles
{
    NSDictionary *dict = GetSignature();
    GTSignature *signature = [[GTSignature alloc] initWithName:dict[SignatureUsername]
                                                         email:dict[SignatureEmail]
                                                          time:NSDate.date];

    return [self commitWorkingFiles:signature];
}

- (BOOL)pullFromRemote:(NSString *)remoteName merge:(BOOL (^)(void))conflictBlock error:(NSError **)outError
{
    BOOL result = YES;
    NSError *error = nil;

    result = [self fetchRemote:remoteName
            credentialProvider:[self _credentialProvider]
                         error:&error];

    if (result) {
        NSArray<GTBranch *> *remoteBranches = [[self remoteBranchesWithError:&error] bk_select:^BOOL (GTBranch *obj) {
            return [obj.remoteName isEqualToString:remoteName];
        }];

        GTBranch *targetBranch = [remoteBranches bk_match:^BOOL (GTBranch *obj) {
            // FIXME: How to get the remote head branch?
            // Use the master branch instead temporarily.
            return [obj.shortName isEqualToString:@"master"];
        }];

        if (!targetBranch) {
            targetBranch = remoteBranches.firstObject;
        }

        if (targetBranch) {
            result = [self mergeBranchIntoCurrentBranch:targetBranch withError:&error];

            if (conflictBlock && !result && [error.domain isEqualToString:GTGitErrorDomain] && error.code == GIT_ECONFLICT) {
                if (conflictBlock() && (result = [self commitWorkingFiles])) {
                    error = nil;
                }
            }
        }
    }

    if (error && outError) {
        *outError = error;
    }

    return result;
}

- (BOOL)pushToRemotes:(NSError **)error
{
    return [self pushToRemote:[self _credentialProvider] error:error];
}

- (GTCredentialProvider *)_credentialProvider
{
    return [GTCredentialProvider providerWithBlock:^GTCredential *(GTCredentialType type, NSString *URL, NSString *userName) {
        NSString *urlHost = [NSURL URLWithString:URL].host;
        NSDictionary *dict = GetCredentialForSite(urlHost);

        if (dict) {
            NSUInteger typeValue = [dict[CredentialKeyType] unsignedIntegerValue];

            if (typeValue == CredentialKeyTypeHTTPS) {
                return [GTCredential credentialWithUserName:dict[CredentialKeyUsername]
                                                   password:dict[CredentialKeyPassword]
                                                      error:nil];
            } else if (typeValue == CredentialKeyTypeSSH) {
                NSString *prefix = dict[CredentialKeySSHKey];
                NSURL *publicFilePath = GetSSHKeyFullPath(kSSHKeyPublicFileName(prefix));
                NSURL *privateFilePath = GetSSHKeyFullPath(kSSHKeyPrivateFileName(prefix));

                return [GTCredential credentialWithUserName:userName
                                               publicKeyURL:publicFilePath
                                              privateKeyURL:privateFilePath
                                                 passphrase:nil
                                                      error:nil];
            }
        }

        return nil;
    }];
}

@end
