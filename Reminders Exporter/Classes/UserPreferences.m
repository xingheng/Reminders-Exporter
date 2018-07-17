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

NSString *const CredentialKeyType = @"Type";
NSString *const CredentialKeyUsername = @"Username";
NSString *const CredentialKeyPassword = @"Password";
NSString *const CredentialKeySSHKey = @"SSHKey";

NSUInteger const CredentialKeyTypeHTTPS = 1;
NSUInteger const CredentialKeyTypeSSH = 2;

#define UserKey(__KEY__) @"Exporter." #__KEY__

#define kSTRKey_Signature      UserKey(Signature)
#define kSTRKey_Credentials    UserKey(Credentials)
#define kSTRKey_LastUpdateDate UserKey(LastUpdateDate)


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
                   SignatureEmail: @"ios@apple.com"
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

NSDictionary * GetCredentialForSite(NSString *siteKey)
{
    return UserDefaultObject(kSTRKey_Credentials)[siteKey];
}

void SetCredential(NSString *siteKey, NSDictionary *values)
{
    NSMutableDictionary *credentialDict = [[NSMutableDictionary alloc] initWithDictionary:GetCredentials()];

    [credentialDict setValue:values forKey:siteKey];
    SetUserDefaultObject(kSTRKey_Credentials, credentialDict);
}

NSDate * GetLastUpdateDate(void)
{
    NSTimeInterval interval = [UserDefaultObject(kSTRKey_LastUpdateDate) doubleValue];

    return interval > 0 ? [NSDate dateWithTimeIntervalSince1970:interval] : nil;
}

void SetLastUpdateDate(NSDate *value)
{
    SetUserDefaultObject(kSTRKey_LastUpdateDate, @(value.timeIntervalSince1970));
}
