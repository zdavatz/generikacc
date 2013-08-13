//
//  SettingsDetailViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 08/06/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsDetailViewController : UITableViewController
{
  NSUserDefaults *_userDefaults;

  UITableView *_detailView;
  NSIndexPath *_selectedPath;

  NSArray *_options;
  NSString *_defaultkey;
}

@property (nonatomic, strong, readwrite) NSArray *options;
@property (nonatomic, strong, readwrite) NSString *defaultKey;

@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readonly) UITableView *detailView;
@property (nonatomic, strong, readonly) NSIndexPath *selectedPath;

@end
