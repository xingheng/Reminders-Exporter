//
//  AppDelegate.m
//  Reminders Exporter
//
//  Created by WeiHan on 10/05/2018.
//  Copyright © 2018 WillHan. All rights reserved.
//
#import <UserNotifications/UserNotifications.h>
#import <CoreLocation/CoreLocation.h>
#import <DSBaseViewController/BaseNavigationController.h>
#import <DSBaseViewController/BaseTabBarController.h>
#import "AppDelegate.h"
#import "RemindersViewController.h"
#import "SettingsViewController.h"
#import "EKGroup+Reminders.h"
#import "Repo+Reminders.h"
#import "Repo+UserActions.h"
#import "REFileLogger.h"

@interface AppDelegate () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    [self setupDDLog];

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound;
    [center requestAuthorizationWithOptions:options
                          completionHandler:^(BOOL granted, NSError *error) {
        if (!granted) {
            DDLogError(@"%s: error: %@", __func__, error);
        }
    }];

    CLLocationManager *locationManager = [CLLocationManager new];
    self.locationManager = locationManager;

    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            [locationManager requestAlwaysAuthorization];
            break;

        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            DDLogDebug(@"Denied or Restricted!");
            break;

        case kCLAuthorizationStatusAuthorizedWhenInUse:
            break;

        case kCLAuthorizationStatusAuthorizedAlways:
            locationManager.delegate = self;
            locationManager.allowsBackgroundLocationUpdates = YES;

            if (@available(iOS 11.0, *)) {
                locationManager.showsBackgroundLocationIndicator = YES;
            }

            break;

        default:
            break;
    }

    if ([launchOptions[UIApplicationLaunchOptionsLocationKey] boolValue]) {
        [locationManager startMonitoringSignificantLocationChanges];
    }

    BaseNavigationController *navi1 = [[BaseNavigationController alloc] initWithRootViewController:[RemindersViewController new]];
    BaseNavigationController *navi2 = [[BaseNavigationController alloc] initWithRootViewController:[SettingsViewController new]];
    BaseTabBarController *tabBarVC = [BaseTabBarController new];

    navi1.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFeatured tag:0];
    navi2.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMore tag:0];

    tabBarVC.viewControllers = @[navi1, navi2];
    self.window.rootViewController = tabBarVC;

    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    [self.locationManager startMonitoringSignificantLocationChanges];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Background Fetch

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [EKGroup fetchRemindersToRepo:Repo.reminderRepo
                       completion:^(BOOL result, NSArray<EKGroup *> *groups) {
        [self sendLocalNotification:@"Updated by Background Fetch"
                               body:NSDate.date.descriptionForCurrentLocale];
        DDLogVerbose(@"Updated %@", NSDate.date.descriptionForCurrentLocale);
        completionHandler(result ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
    }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    [EKGroup fetchRemindersToRepo:Repo.reminderRepo
                       completion:^(BOOL result, NSArray<EKGroup *> *groups) {
        [self sendLocalNotification:@"Updated by Location Changes"
                               body:NSDate.date.descriptionForCurrentLocale];
        DDLogDebug(@"%s: %@", __func__, locations);
    }];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DDLogDebug(@"%s: %@", __func__, error);
}

#pragma mark - Private

- (void)setupDDLog
{
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[REFileLogger sharedInstance]];
}

- (void)sendLocalNotification:(NSString *)title body:(NSString *)body
{
#if DEBUG
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull settings) {
        if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
            UNMutableNotificationContent *content = [UNMutableNotificationContent new];
            content.title = title;
            content.body = body;
            content.sound = [UNNotificationSound defaultSound];

            UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1
                                                                                                            repeats:NO];
            NSString *identifier = @"UYLLocalNotification";
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                                  content:content
                                                                                  trigger:trigger];

            [center addNotificationRequest:request
                     withCompletionHandler:^(NSError *_Nullable error) {
                if (error != nil) {
                    DDLogError(@"Something went wrong: %@", error);
                }
            }];
        }
    }];
#endif /* if DEBUG */
}

@end
