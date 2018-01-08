//
//  Product.h
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

@interface Product : NSObject <NSCoding>

@property (nonatomic, strong, readwrite) NSString *ean;
@property (nonatomic, strong, readwrite) NSString *reg;
@property (nonatomic, strong, readwrite) NSString *pack;
@property (nonatomic, strong, readwrite) NSString *name;

// only for scanned product
@property (nonatomic, strong, readwrite) NSString *datetime;
@property (nonatomic, strong, readwrite) NSString *barcode;
@property (nonatomic, strong, readwrite) NSString *expiresAt;

@property (nonatomic, strong, readwrite) NSString *seq;
@property (nonatomic, strong, readwrite) NSString *size;
@property (nonatomic, strong, readwrite) NSString *deduction;
@property (nonatomic, strong, readwrite) NSString *price;
@property (nonatomic, strong, readwrite) NSString *category;

// only for imported receipt (medications)
@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) NSString *comment;
@property (nonatomic, strong, readwrite) NSString *atc;
@property (nonatomic, strong, readwrite) NSString *owner;

+ (NSDictionary *)productKeyMaps;
+ (id)importFromDict:(NSDictionary *)dict;

- (id)initWithEan:(NSString *)ean;

- (NSArray *)productKeys;

@end
