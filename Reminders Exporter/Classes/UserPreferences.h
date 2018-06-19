//
//  UserPreferences.h
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/19.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const SignatureUsername;
FOUNDATION_EXPORT NSString *const SignatureEmail;

FOUNDATION_EXPORT NSString *const CredentialKeyUsername;
FOUNDATION_EXPORT NSString *const CredentialKeyPassword;

NSDictionary * GetSignature(void);

void SetSignature(NSDictionary *values);


NSDictionary * GetCredentials(void);

void SetCredentials(NSDictionary *values);
