//
//  MasterViewController.h
//  Generika
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import <ZBarSDK/ZBarSDK.h>

@class Product;
@class Receipt;
@class Reachability,
  WebViewController, SettingsViewController, ReaderViewController;

@interface MasterViewController : UITableViewController <
  ZBarReaderDelegate,
  UISearchDisplayDelegate,
  UISearchBarDelegate,
  UIPopoverControllerDelegate>

// for app delegate
- (void)setSelectedSegmentIndex:(NSInteger)index;
- (void)handleOpenAMKFileURL:(NSURL *)url;

@end
