//
//  Utility.m
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <Security/Security.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#import <DSUtility/NSString+Date.h>
#import "Utility.h"

#pragma mark - Functions

BOOL IsFileExist(NSString *strFilePath)
{
    if (strFilePath.length <= 0) {
        return NO;
    }

    return [[NSFileManager defaultManager] fileExistsAtPath:strFilePath];
}

BOOL DeleteFile(NSString *strFilePath, NSError **outError)
{
    return [[NSFileManager defaultManager] removeItemAtPath:strFilePath error:outError];
}

BOOL MoveFile(NSString *strFilePath, NSString *strDestPath, NSError **outError)
{
    return [[NSFileManager defaultManager] moveItemAtPath:strFilePath toPath:strDestPath error:outError];
}

BOOL CopyFile(NSString *strFilePath, NSString *strDestPath, NSError **outError)
{
    return [[NSFileManager defaultManager] copyItemAtPath:strFilePath toPath:strDestPath error:outError];
}

NSURL * CreateDirectoryIfNotExist(NSURL *sourceURL)
{
    if (IsFileExist(sourceURL.path)) {
        return sourceURL;
    }

    NSError *error = nil;

    if (![[NSFileManager defaultManager] createDirectoryAtURL:sourceURL
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error]) {
        NSLog(@"%@", error);
        return nil;
    }

    return sourceURL;
}

static NSURL * GetDocumentDirectoryPath(void)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentDirURL = [fileManager URLForDirectory:NSDocumentDirectory
                                                inDomain:NSUserDomainMask
                                       appropriateForURL:nil
                                                  create:NO
                                                   error:nil];

    return documentDirURL;
}

NSURL * GetRepoRootDirectoryPath(void)
{
    NSURL *resultURL = [GetDocumentDirectoryPath() URLByAppendingPathComponent:@"repos" isDirectory:YES];

    return CreateDirectoryIfNotExist(resultURL);
}

NSURL * GetReminderRepoRootDirectoryPath(void)
{
    NSURL *resultURL = [GetRepoRootDirectoryPath() URLByAppendingPathComponent:@"reminders" isDirectory:YES];

    return CreateDirectoryIfNotExist(resultURL);
}

NSURL * GetSSHKeysRootDirectoryPath(void)
{
    NSURL *resultURL = [GetRepoRootDirectoryPath() URLByAppendingPathComponent:@".keys" isDirectory:YES];

    return CreateDirectoryIfNotExist(resultURL);
}

NSURL * GetSSHKeyFullPath(NSString *filename)
{
    return [GetSSHKeysRootDirectoryPath() URLByAppendingPathComponent:filename];
}

void GenerateKeyPair()
{
    CFStringRef bundleID = CFBundleGetIdentifier(CFBundleGetMainBundle());
    NSData *tag = [(__bridge NSString *)bundleID dataUsingEncoding:NSUTF8StringEncoding];

    CFTypeRef key = NULL;

    NSDictionary *attr = @{
                           (id)kSecAttrKeyType: (id)kSecAttrKeyTypeRSA,
                           (id)kSecAttrKeySizeInBits: @2048,
                           (id)kSecPrivateKeyAttrs: @{
                                   (id)kSecAttrIsPermanent:    @YES,
                                   (id)kSecAttrApplicationTag: tag,
                                   },
                           };

    if (SecItemCopyMatching((CFDictionaryRef)attr, &key) == errSecSuccess) {
        DDLogDebug(@"%@", key);
    }

    NSDictionary *attributes = @{
        (id)kSecAttrKeyType: (id)kSecAttrKeyTypeRSA,
        (id)kSecAttrKeySizeInBits: @2048,
        (id)kSecPrivateKeyAttrs: @{
            (id)kSecAttrIsPermanent:    @YES,
            (id)kSecAttrApplicationTag: tag,
        },
    };

    SecKeyRef publicKey, privateKey;
    OSStatus status = SecKeyGeneratePair((CFDictionaryRef)attributes, &publicKey, &privateKey);

    if (status != errSecSuccess) {
        return;
    }

    CFErrorRef error = NULL;
    CFDataRef publicData = SecKeyCopyExternalRepresentation(publicKey, &error);
    CFDataRef privateData = SecKeyCopyExternalRepresentation(privateKey, &error);

    NSString *strPublicKey = [(__bridge NSData *)publicData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString *strPrivateKey = [(__bridge NSData *)privateData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

    DDLogDebug(@"%@", strPublicKey);
    DDLogDebug(@"%@", strPrivateKey);

    if (publicKey) {
        CFRelease(publicKey);
    }

    if (privateKey) {
        CFRelease(privateKey);
    }
}

// How to Use OpenSSL to Generate RSA Keys in C/C++
// URL: http://www.codepool.biz/how-to-use-openssl-generate-rsa-keys-cc.html
bool generate_key(const char *public_key_file, const char *private_key_file)
{
    int ret = 0;
    RSA *r = NULL;
    BIGNUM *bne = NULL;
    BIO *bp_public = NULL, *bp_private = NULL;

    int bits = 2048;
    BN_ULONG e = RSA_F4;

    // 1. generate rsa key
    bne = BN_new();
    ret = BN_set_word(bne, e);

    if (ret != 1) {
        goto free_all;
    }

    r = RSA_new();
    ret = RSA_generate_key_ex(r, bits, bne, NULL);

    if (ret != 1) {
        goto free_all;
    }

    // 2. save public key
    bp_public = BIO_new_file(public_key_file, "w+");
    ret = PEM_write_bio_RSAPublicKey(bp_public, r);

    if (ret != 1) {
        goto free_all;
    }

    // 3. save private key
    bp_private = BIO_new_file(private_key_file, "w+");
    ret = PEM_write_bio_RSAPrivateKey(bp_private, r, NULL, NULL, 0, NULL, NULL);

    // 4. free
 free_all:

    BIO_free_all(bp_public);
    BIO_free_all(bp_private);
    RSA_free(r);
    BN_free(bne);

    return (ret == 1);
}

#pragma mark - NSDate (Descriptions)

@implementation NSDate (Descriptions)

- (NSString *)descriptionForCurrentLocale
{
    return [self stringFromDateFormat:kDateFormat_Date_Time_Second];
//    return [self descriptionWithLocale:NSLocale.currentLocale];
}

@end
