//
//  AmikoDBPriceComparison.h
//  Generika
//
//  Created by b123400 on 2025/10/22.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AmikoDBPackage.h"

NS_ASSUME_NONNULL_BEGIN

@interface AmikoDBPriceComparison : NSObject

@property (nonatomic, strong) AmikoDBPackage *package;
@property (nonatomic, assign) double priceDifferenceInPercentage;

+ (NSArray<AmikoDBPriceComparison*> *)comparePrice:(NSString *)gtin;

@end

NS_ASSUME_NONNULL_END
