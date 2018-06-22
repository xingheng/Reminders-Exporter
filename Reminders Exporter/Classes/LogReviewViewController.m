//
//  LogReviewViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/22.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import "LogReviewViewController.h"

@interface LogReviewViewController ()

@property (nonatomic, strong) UITextView *textview;

@end

@implementation LogReviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - BuildViewDelegate

- (void)buildSubview:(UIView *)containerView controller:(BaseViewController *)viewController
{
    UITextView *textview = [UITextView new];

    self.textview = textview;
    textview.editable = NO;
    [containerView addSubview:textview];

    [textview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(containerView);
    }];
}

- (void)loadDataForController:(BaseViewController *)viewController
{
    if (self.fileInfo) {
        self.title = self.fileInfo.fileName;

        NSError *error = nil;
        self.textview.text = [NSString stringWithContentsOfFile:self.fileInfo.filePath encoding:NSUTF8StringEncoding error:&error];

        if (error) {
            HUDToast(self.view).title(@"Failed to read content from log file").subTitle(error.description).delay(3).show();
        }
    }
}

- (void)tearDown:(BaseViewController *)viewController
{
}

- (BOOL)shouldInvalidateDataForController:(BaseViewController *)viewController
{
    return NO;
}

@end
