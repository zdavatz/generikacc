//
//  MasterViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 4/11/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController, WebViewController, ZBarReaderViewController;

@interface MasterViewController : UITableViewController < ZBarReaderDelegate >
{

    ZBarReaderViewController *_reader;
    WebViewController *_browser;
    UITableView *_tableView;
    NSMutableArray *_objects;
    UILabel *_nameLabel;
    UILabel *_sizeLabel;
    UILabel *_priceLabel;
    UILabel *_deductionLabel;
    UILabel *_categoryLabel;
    UILabel *_eanLabel;
}
@property (strong, nonatomic) DetailViewController *detailViewController;

- (IBAction)scanButtonTapped;

- (void)openReader;
- (void)openCompareSearchByEan:(NSString *)ean;
@end
