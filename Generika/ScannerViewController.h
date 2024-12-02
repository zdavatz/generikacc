//
//  ScannerViewController.h
//  Generika
//
//  Created by b123400 on 2018/11/27.
//  Copyright © 2018 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataMatrixResult.h"
#import "EPrescription.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ScannerViewControllerDelegate <NSObject>

- (void)scannerViewController:(id)sender
              didScannedEan13:(NSString *)ean
                    withImage:(UIImage *)image;

- (void)scannerViewController:(id)sender
         didScannedDataMatrix:(DataMatrixResult *)result
                    withImage:(UIImage *)image;

- (void)scannerViewController:(id)sender
             didEPrescription:(EPrescription *)result
                    withImage:(UIImage *)image;

@end

@interface ScannerViewController : UIViewController

@property (nonatomic, weak) id <ScannerViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
