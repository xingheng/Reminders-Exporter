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

- (BOOL)pushToRemotes
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
    }]];
}

@end
