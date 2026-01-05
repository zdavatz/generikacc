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

- (BOOL)isGeneric {
    for (NSString *flag in [self parsedFlags]) {
        if ([flag isEqual:@"G"]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isOriginal {
    for (NSString *flag in [self parsedFlags]) {
        if ([flag isEqual:@"O"]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)parsedDosageFromName {
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:@"((\\d+)(\\.\\d+)?\\s*(ml|mg|g))" options:0 error:nil];
    NSTextCheckingResult *match1 = [regex1 firstMatchInString:self.name options:0 range:NSMakeRange(0, self.name.length)];
    NSString *dosage1 = [match1 numberOfRanges] ? [self.name substringWithRange:[match1 rangeAtIndex:0]] : @"";
    
    NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:@"(((\\d+)(\\.\\d+)?(Ds|ds|mg)?)(\\/(\\d+)(\\.\\d+)?\\s*(Ds|ds|mg|ml|mg|g)?)+)" options:0 error:nil];
    NSTextCheckingResult *match2 = [regex2 firstMatchInString:self.name options:0 range:NSMakeRange(0, self.name.length)];
    NSString *dosage2 = [match2 numberOfRanges] ? [self.name substringWithRange:[match2 rangeAtIndex:0]] : @"";
    
    if (dosage1.length == 0 || [dosage2 containsString:dosage1]) {
        return dosage2;
    }

    return dosage1;
}

- (BOOL)isDosageEqualsTo:(AmikoDBPackage*)other {
    NSString *dosage1 = [[self parsedDosageFromName] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *dosage2 = [[other parsedDosageFromName] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([dosage1 isEqual:dosage2]) {
        return YES;
    }
    NSString *numOnly1 = [AmikoDBPackage takeNumOnly:dosage1];
    NSString *numOnly2 = [AmikoDBPackage takeNumOnly:dosage2];
    BOOL is1WithoutUnit = [dosage1.lowercaseString hasSuffix:@"ds"] || [numOnly1 isEqual:dosage1];
    BOOL is2WithoutUnit = [dosage2.lowercaseString hasSuffix:@"ds"] || [numOnly2 isEqual:dosage2];
    if (is1WithoutUnit || is2WithoutUnit) {
        return [numOnly1 isEqual:numOnly2];
    }
    return NO;
}

+ (NSString *)takeNumOnly:(NSString *)str {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*(\\d+)" options:0 error:&error];
    if (error != nil) {
        NSLog(@"Regex Error: %@", error.localizedDescription);
    }
    NSTextCheckingResult *match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, str.length)];
    if ([match numberOfRanges] >= 2) {
        return [str substringWithRange:[match rangeAtIndex:1]];
    }
    return nil;
}

@end
