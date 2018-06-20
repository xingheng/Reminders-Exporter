//
//  RemindersTableView.h
//  Reminders Exporter
//
//  Created by WeiHan on 2018/6/20.
//  Copyright © 2018 WillHan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EKGroup.h"

NSString * GetTimeDistance(NSDate *date1, NSDate *date2);


@interface RemindersTableView : UITableView

@property (nonatomic, strong) NSArray<EKGroup *> *dataItems;

@property (nonatomic, copy) void (^ refreshBlock)(UIRefreshControl *);

@end
