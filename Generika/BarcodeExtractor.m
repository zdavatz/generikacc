//
//  BarcodeExtractor.m
//  Generika
//
//  Created by b123400 on 2018/11/29.
//  Copyright © 2018 ywesee GmbH. All rights reserved.
//

#import "BarcodeExtractor.h"
#import "DataMatrixResult.h"
#import "Helper.h"

@implementation BarcodeExtractor

- (DataMatrixResult*)extractGS1DataFrom:(NSString *)input {
    if (!input.length) {
        return nil;
    }
    NSString *firstCharacter = [input substringWithRange:NSMakeRange(0, 1)];
    if ([Helper isStringNumber:firstCharacter]) {
        return [self parsePayload: input];
    }
    DataMatrixResult *result = [[DataMatrixResult alloc] init];
    for (NSString *substring in [[input substringFromIndex: 1] componentsSeparatedByString: firstCharacter]) {
        [result merge: [self parsePayload: substring]];
    }
    return result;
}

- (DataMatrixResult*)parsePayload:(NSString *)input {
    if (input.length < 2) {
        return nil;
    }
    DataMatrixResult *result = [[DataMatrixResult alloc] init];
    while (input.length >= 2) {
        NSString *firstTwoCharacter = [input substringWithRange:NSMakeRange(0, 2)];
        NSString *rest = [input substringFromIndex: 2];
        if ([firstTwoCharacter isEqualToString: @"01"]) {
            result.gtin = [self trimZeroPadding:[rest substringToIndex: 14]];
            input = [rest substringFromIndex: 14];
        } else if ([firstTwoCharacter isEqualToString: @"11"]) {
            result.productionDate = [self convertStringForDate:[rest substringToIndex: 6]];
            input = [rest substringFromIndex: 6];
        } else if ([firstTwoCharacter isEqualToString: @"15"]) {
            result.bestBeforeDate = [self convertStringForDate:[rest substringToIndex: 6]];
            input = [rest substringFromIndex: 6];
        } else if ([firstTwoCharacter isEqualToString: @"17"]) {
            result.expiryDate = [self convertStringForDate:[rest substringToIndex: 6]];
            input = [rest substringFromIndex: 6];
        } else if ([firstTwoCharacter isEqualToString: @"10"]) {
            NSInteger length = MIN(rest.length, 20);
            result.batchOrLotNumber = [rest substringToIndex: length];
            input = [rest substringFromIndex: length];
        } else if ([firstTwoCharacter isEqualToString: @"21"]) {
            NSInteger length = MIN(rest.length, 20);
            result.specialNumber = [rest substringToIndex: length];
            input = [rest substringFromIndex: length];
        } else if ([firstTwoCharacter isEqualToString: @"30"]) {
            NSInteger length = MIN(rest.length, 8);
            result.amount = [rest substringToIndex: length];
            input = [rest substringFromIndex: length];
        } else {
            break;
        }
    }
    return result;
}

// Convert date string from YYMMDD to MM.YYYY
-(NSString*)convertStringForDate:(NSString*)input {
    return [NSString stringWithFormat:@"%@.20%@",
            [input substringWithRange:NSMakeRange(2, 2)],
            [input substringToIndex:2]];
}

-(NSString*)trimZeroPadding:(NSString*)input {
    while (input.length && [[input substringToIndex:1] isEqualToString:@"0"]){
        input = [input substringFromIndex:1];
    }
    return input;
}

@end
