//
//  BarcodeExtractor.h
//  Generika
//
//  Created by b123400 on 2018/11/29.
//  Copyright © 2018 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataMatrixResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface BarcodeExtractor : NSObject

- (DataMatrixResult*)extractGS1DataFrom:(NSString *)input;

@end

NS_ASSUME_NONNULL_END
