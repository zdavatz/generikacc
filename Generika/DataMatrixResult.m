//
//  DataMatrixResult.m
//  Generika
//
//  Created by b123400 on 2018/11/29.
//  Copyright © 2018 ywesee GmbH. All rights reserved.
//

#import "DataMatrixResult.h"

@implementation DataMatrixResult

- (void)merge:(DataMatrixResult *)anotherDataMatrix {
    if (self.gtin == nil) {
        self.gtin = anotherDataMatrix.gtin;
    }
    if (self.productionDate == nil) {
        self.productionDate = anotherDataMatrix.productionDate;
    }
    if (self.bestBeforeDate == nil) {
        self.bestBeforeDate = anotherDataMatrix.bestBeforeDate;
    }
    if (self.expiryDate == nil) {
        self.expiryDate = anotherDataMatrix.expiryDate;
    }
    if (self.batchOrLotNumber == nil) {
        self.batchOrLotNumber = anotherDataMatrix.batchOrLotNumber;
    }
    if (self.specialNumber == nil) {
        self.specialNumber = anotherDataMatrix.specialNumber;
    }
    if (self.amount == nil) {
        self.amount = anotherDataMatrix.amount;
    }
}

@end
