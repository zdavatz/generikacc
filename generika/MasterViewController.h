//
//  MasterViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 4/11/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController, WebViewController;

@interface MasterViewController : UITableViewController < ZBarReaderDelegate >
{
    UIImageView *resultImage;
    UITextView  *resultText;

    WebViewController *browser;
    NSMutableString *_productName;
    NSMutableString *_productSize;

    UITableView *_tableView;
    NSMutableArray *_objects;
    UILabel *_nameLabel;
    UILabel *_sizeLabel;
    UILabel *_priceLabel;
    UILabel *_deductionLabel;
    UILabel *_categoryLabel;
    UILabel *_eanLabel;
}
@property (nonatomic, retain) IBOutlet UIImageView *resultImage;
@property (nonatomic, retain) IBOutlet UITextView *resultText;
@property (strong, nonatomic) DetailViewController *detailViewController;

- (IBAction)scanButtonTapped;

- (void)openCamera;
- (void)openCompareSearchByEan:(NSString *)ean;
@end
