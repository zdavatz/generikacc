//
//  AmikoDBPackage.m
//  Generika
//
//  Created by b123400 on 2025/10/20.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "AmikoDBPackage.h"

@implementation AmikoDBPackage

- (instancetype)initWithPackageString:(NSString *)str parent:(AmikoDBRow *)row {
    if (self = [super init]) {
        NSArray *parts = [str componentsSeparatedByString:@"|"];
        self.name = parts[0];
        self.dosage = parts[1];
        self.units = parts[2];
        self.efp = parts[3];
        self.pp = parts[4];
        self.fap = parts[5];
        self.fep = parts[6];
        self.vat = parts[7];
        self.flags = parts[8];
        self.gtin = parts[9];
        self.phar = parts[10];

        self.parent = row;
    }
    return self;
}

- (NSArray<NSString*>*)parsedFlags {
    return [self.flags componentsSeparatedByString:@","];
}

- (NSString *)selbstbehalt {
    for (NSString *flag in [self parsedFlags]) {
        if ([flag hasPrefix:@"SB "]) {
            return [flag substringFromIndex:3];
        }
    }
    return nil;
}

- (NSString *)priceDifferenceInPercent {
//    % (Preisunterschied in Prozent)
//    AmikoDBPackage *smallestPackage = nil;
//    double smallestSize = -1;
//    for (AmikoDBPackage *package in self.parent.parsedPackages) {
//        double thisSize = [package.dosage doubleValue];
//        if (smallestSize == -1 || thisSize < smallestSize) {
//            smallestPackage = package;
//        }
//    }
//    if (smallestPackage == self) {
//        return nil;
//    }
//    
//    1- self.pp / (smallestPackage.pp / smallestSize * self.dosage);
}

@end
