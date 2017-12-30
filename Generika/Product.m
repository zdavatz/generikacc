//
//  Product.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "Product.h"

@implementation Product

+ (id)importFromDict:(NSDictionary *)dict
{
  Product *product = [[self alloc] init];
  NSDictionary *keyMaps = [[self class] productKeyMaps];
  for (NSString *key in [keyMaps allKeys]) {
    NSString *value;
    // get value from dict using importing key
    value = [dict valueForKey:keyMaps[key]] ?: [NSNull null];
    if (value == nil || [value isEqual:[NSNull null]]) {
      value = @"";
    }
    [product setValue:value forKey:key];
  }
  return product;
}

- (id)init
{
  self = [super init];
  if (!self) {
    return nil;
  }
  return self;
}

- (id)initWithEan:(NSString *)ean
{
  self = [self init];
  if (self) {
    self.ean = ean;
  }
  return self;
}

- (void)dealloc
{
  _datetime = nil; // scanned at

  _ean = nil;
  _reg = nil;
  _pack = nil;
  _name = nil;

  // product
  _barcode = nil; // file path
  _expiresAt = nil; // value from picker

  _seq = nil;
  _size = nil;
  _deduction = nil;
  _price = nil;
  _category = nil;

  // receipt
  _atc = nil;
  _owner = nil;
  _title = nil;
  _comment = nil;
}

#pragma mark - NSCoding Interface

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (!self) {
    return nil;
  }
  for (NSString *key in [self productKeys]) {
    NSString *value;
    if ([decoder containsValueForKey:key]) {
      value = [decoder decodeObjectForKey:key];
    } else {
      value = @"";
    }
    [self setValue:value forKey:key];
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  for (NSString *key in [self productKeys]) {
    NSString *value = [self valueForKey:key] ?: [NSNull null];
    if (value == nil || [value isEqual:[NSNull null]]) {
      value = @"";
    }
    [encoder encodeObject:value forKey:key];
  }
}

#pragma mark - Getter methods

- (NSString *)reg
{
  if (_reg != nil && _reg != @"") {
    return _reg;
  } else if (self.ean) {
    return [Constant detectStringWithRegexp:@"7680(\\d{5}).+"
                                       from:self.ean];
  } else {
    return @"";
  }
}

- (NSString *)seq
{
  if (_seq != nil && _seq != @"") {
    return _seq;
  } else if (self.ean) {
    return [Constant detectStringWithRegexp:@"7680\\d{5}(\\d{3}).+"
                                       from:self.ean];
  } else {
    return @"";
  }
}


#pragma mark - Conversion to Dictionary

+ (NSDictionary *)productKeyMaps
{
  return @{ // property : importingKey
    // (shared)
    @"ean"  : @"eancode",
    @"reg"  : @"regnrs",
    @"pack" : @"package",
    @"name" : @"product_name",
    // (package)
    @"seq"       : @"seq",
    @"size"      : @"size",
    @"deduction" : @"deduction",
    @"price"     : @"price",
    @"category"  : @"category",
    // (receipt)
    @"atc"     : @"atccode",
    @"owner"   : @"owner",
    @"title"   : @"title",
    @"comment" : @"comment"
  };
}

- (NSArray *)productKeys
{
  NSArray *additionalKeys = @[
    @"barcode",
    @"datetime",
    @"expiresAt"
  ];
  return [additionalKeys arrayByAddingObjectsFromArray:
    [[[self class] productKeyMaps] allKeys]];
}

@end
