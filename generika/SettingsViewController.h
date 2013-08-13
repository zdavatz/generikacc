//
//  SettingsViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 08/05/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SettingsDetailViewController;

@interface SettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
  SettingsDetailViewController *_settingsDetail;

  NSUserDefaults *_userDefaults;

  UITableView *_settingsView;
  NSArray *_entries;
}

@property (nonatomic, strong, readonly) SettingsDetailViewController *settingsDetail;
@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readonly) UITableView *settingsView;
@property (nonatomic, strong, readonly) NSArray *entries;

@end
