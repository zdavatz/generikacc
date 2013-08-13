//
//  MasterViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 4/11/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Reachability, WebViewController, SettingsViewController, ZBarReaderViewController;

@interface MasterViewController : UITableViewController <ZBarReaderDelegate>
{
  Reachability *_reachability;
  ZBarReaderViewController *_reader;
  WebViewController *_browser;
  SettingsViewController *_settings;

  NSUserDefaults *_userDefaults;

  UITableView *_productsView;
  NSMutableArray *_products;
}

@property (nonatomic, strong, readonly) Reachability *reachability;
@property (nonatomic, strong, readonly) ZBarReaderViewController *reader;
@property (nonatomic, strong, readonly) WebViewController *browser;
@property (nonatomic, strong, readonly) SettingsViewController *settings;
@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readonly) UITableView *productsView;
@property (nonatomic, strong, readonly) NSMutableArray *products;

- (void)scanButtonTapped:(UIButton *)button;
- (void)settingsButtonTapped:(UIButton *)button;

- (void)openReader;
- (void)searchInfoForProduct:(NSDictionary *)product;

@end
