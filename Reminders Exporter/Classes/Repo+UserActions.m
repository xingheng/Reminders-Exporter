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
    NSDictionary *credentialDict = GetCredentials();

    result = [self fetchRemote:remoteName
            credentialProvider:[GTCredentialProvider providerWithBlock:^GTCredential *(GTCredentialType type, NSString *URL, NSString *userName) {
        NSString *urlHost = [NSURL URLWithString:URL].host;
        NSDictionary *dict = credentialDict[urlHost];

        if (dict) {
            return [GTCredential credentialWithUserName:dict[CredentialKeyUsername]
                                               password:dict[CredentialKeyPassword]
                                                  error:nil];
        }

        return nil;
    }]
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
    NSDictionary *credentialDict = GetCredentials();

    return [self pushToRemote:[GTCredentialProvider providerWithBlock:^GTCredential *(GTCredentialType type, NSString *URL, NSString *userName) {
        NSString *urlHost = [NSURL URLWithString:URL].host;
        NSDictionary *dict = credentialDict[urlHost];

        if (dict) {
            return [GTCredential credentialWithUserName:dict[CredentialKeyUsername]
                                               password:dict[CredentialKeyPassword]
                                                  error:nil];
        }

        return nil;
    }]
                        error:error];
}

@end
