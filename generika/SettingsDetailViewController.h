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
  NSArray *_options;
  NSString *_defaultkey;

  NSUserDefaults *_userDefaults;
  NSIndexPath *_selectedPath;

  UITableView *_detailView;
  UILabel *_nameLabel;
}

@property (nonatomic, retain) NSArray *options;
@property (nonatomic, retain) NSString *defaultKey;

@end
