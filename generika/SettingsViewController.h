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

  NSArray *_settings;

  NSUserDefaults *_userDefaults;

  UITableView *_settingsView;
  UILabel *_sectionLabel;
  UILabel *_nameLabel;
  UILabel *_optionLabel;
}

@end
