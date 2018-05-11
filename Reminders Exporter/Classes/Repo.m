//
//  Repo.m
//  Reminders Exporter
//
//  Created by WeiHan on 11/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "Repo.h"

@implementation Repo

- (instancetype)initWithURL:(NSURL *)localFileURL createIfNotExist:(BOOL)flag error:(NSError * _Nullable __autoreleasing *)error
{
    if (self = [super initWithURL:localFileURL error:error]) {

    } else if (flag) {
        self = [Repo initializeEmptyRepositoryAtFileURL:localFileURL options:nil error:error];
    }

    return self;
}

@end
