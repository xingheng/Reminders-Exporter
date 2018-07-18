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

- (void)commitWorkingFiles:(RepoOperationBlock)completion
{
    NSDictionary *dict = GetSignature();
    GTSignature *signature = [[GTSignature alloc] initWithName:dict[SignatureUsername]
                                                         email:dict[SignatureEmail]
                                                          time:NSDate.date];

    [self commitWorkingFiles:signature completion:completion];
}

- (void)pullFromRemote:(NSString *)remoteName merge:(BOOL (^)(void))conflictBlock completion:(RepoOperationBlock)completion
{
    [self      fetchRemote:remoteName
        credentialProvider:[self _credentialProvider]
                completion:^(BOOL res, NSError *err) {
        if (!res) {
            !completion ? : completion(res, err);
            return;
        }

        __block BOOL result = YES;
        __block NSError *error = nil;
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
            result = [self mergeBranchIntoCurrentBranch:targetBranch
                                              withError:&error];

            if (conflictBlock && !result && [error.domain isEqualToString:GTGitErrorDomain] && error.code == GIT_ECONFLICT) {
                if (conflictBlock()) {
                    [self commitWorkingFiles:^(BOOL res, NSError *err) {
                        result = res;
                        error = err;
                    }];
                }
            }
        }

        RunInMainQueue(completion, result, error);
    }];
}

- (void)pushToRemotes:(RepoOperationBlock)completion
{
    return [self pushToRemote:[self _credentialProvider] completion:completion];
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
