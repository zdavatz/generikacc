//
//  MasterViewController.h
//  Generika
//
//  Created by Yasuhiro Asaka on 4/11/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import <ZBarSDK/ZBarSDK.h>

@class Product;
@class Reachability, WebViewController, SettingsViewController, ReaderViewController;

@interface MasterViewController : UITableViewController <ZBarReaderDelegate, UISearchDisplayDelegate, UISearchBarDelegate, UIPopoverControllerDelegate>

@end
