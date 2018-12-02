//
//  MasterViewController.h
//  Generika
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

@class Product;
@class Receipt;
@class Reachability,
  WebViewController, ReceiptViewController,
  SettingsViewController, ReaderViewController;

@interface MasterViewController : UITableViewController <
  UIDocumentPickerDelegate,
  UISearchDisplayDelegate,
  UISearchBarDelegate,
  UIPopoverControllerDelegate>

// for app delegate
- (void)setSelectedSegmentIndex:(NSInteger)index;
- (void)handleOpenAmkFileURL:(NSURL *)url animated:(BOOL)animated;

@end
