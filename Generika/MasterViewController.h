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
  WebViewController, AmkViewController,
  SettingsViewController, ReaderViewController;

@interface MasterViewController : UITableViewController <
  ZBarReaderDelegate,
  UIDocumentPickerDelegate,
  UISearchDisplayDelegate,
  UISearchBarDelegate,
  UIPopoverControllerDelegate>

// for app delegate
- (void)setSelectedSegmentIndex:(NSInteger)index;
- (void)handleOpenAmkFileURL:(NSURL *)url animated:(BOOL)animated;

@end
