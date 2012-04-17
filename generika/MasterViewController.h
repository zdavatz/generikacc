//
//  MasterViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 4/11/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Reachability, WebViewController, ZBarReaderViewController;

@interface MasterViewController : UITableViewController <ZBarReaderDelegate>
{
  Reachability *_reachability;
  ZBarReaderViewController *_reader;
  WebViewController *_browser;
  UITableView *_tableView;
  NSMutableArray *_objects;
  UILabel *_nameLabel;
  UILabel *_sizeLabel;
  UILabel *_dateLabel;
  UILabel *_priceLabel;
  UILabel *_deductionLabel;
  UILabel *_categoryLabel;
  UILabel *_eanLabel;
}

- (IBAction)scanButtonTapped:(UIButton*)button;

- (void)openReader;
- (void)openCompareSearchByEan:(NSString *)ean;
@end
