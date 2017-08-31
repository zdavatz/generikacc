//
//  SettingsDetailViewController.h
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//


@interface SettingsDetailViewController : UITableViewController

@property (nonatomic, strong, readwrite) NSArray *options;
@property (nonatomic, strong, readwrite) NSString *defaultKey;
@property (nonatomic, strong, readwrite) NSString *label;

@end
