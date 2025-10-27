//
//  AmikoDBPackage.h
//  Generika
//
//  Created by b123400 on 2025/10/20.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AmikoDBRow;

@interface AmikoDBPackage : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *dosage;
@property (nonatomic, strong) NSString *units;
@property (nonatomic, strong) NSString *efp;
@property (nonatomic, strong) NSString *pp;
@property (nonatomic, strong) NSString *fap;
@property (nonatomic, strong) NSString *fep;
@property (nonatomic, strong) NSString *vat;
@property (nonatomic, strong) NSString *flags;
@property (nonatomic, strong) NSString *gtin;
@property (nonatomic, strong) NSString *phar;

@property (nonatomic, strong) AmikoDBRow *parent;

- (instancetype)initWithPackageString:(NSString *)str parent:(AmikoDBRow *)row;

- (NSArray<NSString*>*)parsedFlags;
- (NSString *)selbstbehalt;

@end

NS_ASSUME_NONNULL_END
