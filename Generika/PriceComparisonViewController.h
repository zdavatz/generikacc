//
//  PriceComparisonViewController.h
//  Generika
//
//  Created by b123400 on 2025/10/26.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AmikoDatabase/AmikoDBPriceComparison.h"

NS_ASSUME_NONNULL_BEGIN

@interface PriceComparisonViewController : UIViewController

@property (nonatomic, assign) BOOL showAsTable;
@property (nonatomic, strong) NSArray<AmikoDBPriceComparison *> *comparisons;

@end

NS_ASSUME_NONNULL_END
