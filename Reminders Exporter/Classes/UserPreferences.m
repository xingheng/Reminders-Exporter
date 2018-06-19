//
//  UserPreferences.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/19.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <UserDefaultsHelper/UserDefault.h>
#import "UserPreferences.h"

#pragma mark - Keys

NSString *const SignatureUsername = @"Username";
NSString *const SignatureEmail = @"Password";

NSString *const CredentialKeyUsername = @"Username";
NSString *const CredentialKeyPassword = @"Password";

#define UserKey(__KEY__) @"Exporter." #__KEY__

#define kSTRKey_Signature   UserKey(Signature)
#define kSTRKey_Credentials UserKey(Credentials)

NSDictionary * GetSignature(void)
{
    NSDictionary *dict = UserDefaultObject(kSTRKey_Signature);

    if (!dict) {
        return @{
#if TARGET_OS_SIMULATOR
                   SignatureUsername: @"steve",
                   SignatureEmail: @"steve@apple.com"
#else
                   SignatureUsername: @"iOS",
                   SignatureEmail: @""
#endif
        };
    }

    return dict;
}

void SetSignature(NSDictionary *values)
{
    SetUserDefaultObject(kSTRKey_Signature, values);
}

NSDictionary * GetCredentials(void)
{
    return UserDefaultObject(kSTRKey_Credentials);
}

void SetCredentials(NSDictionary *values)
{
    SetUserDefaultObject(kSTRKey_Credentials, values);
}
