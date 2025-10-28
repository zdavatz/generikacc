//
//  PatinfoViewController.h
//  Generika
//
//  Created by b123400 on 2025/10/28.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AmikoDatabase/AmikoDBRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface PatinfoViewController : UIViewController

- (instancetype)initWithRow:(AmikoDBRow *)row;

@end

NS_ASSUME_NONNULL_END
