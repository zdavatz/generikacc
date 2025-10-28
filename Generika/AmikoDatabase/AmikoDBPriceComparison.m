//
//  AmikoDBPriceComparison.m
//  Generika
//
//  Created by b123400 on 2025/10/22.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "AmikoDBPriceComparison.h"
#import "AmikoDBManager.h"

@implementation AmikoDBPriceComparison

+ (NSArray<AmikoDBPriceComparison*> *)comparePrice:(NSString *)gtin {
    NSArray *rows = [[AmikoDBManager shared] findWithGtin:gtin];
    if (rows.count == 0) return nil;
    NSMutableDictionary *idToRowDict = [NSMutableDictionary dictionary];
    NSString *atc = nil;
    AmikoDBPackage *thePackage = nil;
    for (AmikoDBRow *row in rows) {
        idToRowDict[row._id] = row;
        if ([row.atc length]) {
            atc = row.atc;
        }
        for (AmikoDBPackage *package in row.parsedPackages) {
            if ([package.gtin isEqual:gtin]) {
                thePackage = package;
            }
        }
    }
    if (![atc length] || !thePackage) return nil;
    NSArray<AmikoDBRow *> *comparables = [[AmikoDBManager shared] findWithATC:atc];
    for (AmikoDBRow *comparableRow in comparables) {
        idToRowDict[comparableRow._id] = comparableRow;
    }
    
    double baseQuantity = [thePackage.dosage doubleValue];
    double basePrice = [[thePackage.pp stringByReplacingOccurrencesOfString:@"CHF " withString:@""] doubleValue];

    NSMutableArray<AmikoDBPriceComparison*> *results = [NSMutableArray array];
    
    for (AmikoDBRow *row in [idToRowDict allValues]) {
        for (AmikoDBPackage *package in row.parsedPackages) {
            if ([package.gtin isEqual:gtin] || ![package.units isEqual:thePackage.units]) continue;
            
            AmikoDBPriceComparison *c = [[AmikoDBPriceComparison alloc] init];
            [results addObject:c];
            c.package = package;
            
            double thisQuantity = [package.dosage doubleValue];
            double thisPrice = [[package.pp stringByReplacingOccurrencesOfString:@"CHF " withString:@""] doubleValue];
            
            if (basePrice <= 0 || thisPrice <= 0 || baseQuantity <= 0 || thisQuantity <= 0) {
                // We still add it to the results even when numbers are missing
                continue;
            }
            
            // cheaper = negative number
            double diff = thisPrice / (basePrice / baseQuantity * thisQuantity) - 1;
            c.priceDifferenceInPercentage = diff * 100;
        }
    }
    // prepend thePackage
    AmikoDBPriceComparison *selfC = [[AmikoDBPriceComparison alloc] init];
    selfC.package = thePackage;
    [results insertObject:selfC atIndex:0];
    
    return results;
}


@end
