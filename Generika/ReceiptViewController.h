//
//  ReceiptViewController.h
//  Generika
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import "Receipt.h"
#import "MasterViewController.h"

@interface ReceiptViewController : UIViewController <UIActionSheetDelegate>

@property (nonatomic, strong, readwrite) MasterViewController *parent;
@property (nonatomic, strong, readonly) Receipt *receipt;

- (void)loadReceipt:(Receipt *)receipt;

@end
