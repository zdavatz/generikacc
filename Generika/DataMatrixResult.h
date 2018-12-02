//
//  DataMatrixResult.h
//  Generika
//
//  Created by b123400 on 2018/11/29.
//  Copyright © 2018 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataMatrixResult : NSObject

@property (nonatomic, strong) NSString *gtin;
@property (nonatomic, strong) NSString *productionDate;
@property (nonatomic, strong) NSString *bestBeforeDate;
@property (nonatomic, strong) NSString *expiryDate;
@property (nonatomic, strong) NSString *batchOrLotNumber;
@property (nonatomic, strong) NSString *specialNumber;
@property (nonatomic, strong) NSString *amount;

- (void)merge:(DataMatrixResult *)anotherDataMatrix;

@end

NS_ASSUME_NONNULL_END
