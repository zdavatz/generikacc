//
//  Product.h
//  Generika
//
//  Created by Yasuhiro Asaka on 09/02/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//


@interface Product : NSObject <NSCoding>

@property (nonatomic, strong, readwrite) NSString *reg;
@property (nonatomic, strong, readwrite) NSString *seq;
@property (nonatomic, strong, readwrite) NSString *pack;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *size;
@property (nonatomic, strong, readwrite) NSString *deduction;
@property (nonatomic, strong, readwrite) NSString *price;
@property (nonatomic, strong, readwrite) NSString *category;
@property (nonatomic, strong, readwrite) NSString *barcode;
@property (nonatomic, strong, readwrite) NSString *ean;
@property (nonatomic, strong, readwrite) NSString *datetime;

- (id)initWithEan:(NSString *)ean;
- (NSArray *)productKeys;

@end
