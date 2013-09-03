//
//  SettingsDetailViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 08/06/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//


@interface SettingsDetailViewController : UITableViewController

@property (nonatomic, strong, readwrite) NSArray *options;
@property (nonatomic, strong, readwrite) NSString *defaultKey;

@end
