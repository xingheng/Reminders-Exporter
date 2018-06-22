//
//  AboutViewController.m
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/22.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "AboutViewController.h"

@interface AboutViewController ()

@property (nonatomic, strong) WKWebView *webview;

@end

@implementation AboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"About";
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
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    WKWebView *webview = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];

    self.webview = webview;
    [containerView addSubview:webview];

    [webview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(containerView);
    }];
}

- (void)loadDataForController:(BaseViewController *)viewController
{
    NSString *fileURL = [[NSBundle mainBundle] pathForResource:@"README" ofType:@"html"];

    if (fileURL) {
        NSError *error = nil;
        [self.webview loadHTMLString:[NSString stringWithContentsOfFile:fileURL encoding:NSUTF8StringEncoding error:&error] baseURL:nil];

        if (error) {
            HUDToast(self.view).title(@"Failed to read content of about page.").subTitle(error.description).delay(3).show();
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
