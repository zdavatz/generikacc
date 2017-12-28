//
//  Product.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "Product.h"


@implementation Product

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
  _barcode   = nil; // file path
  _datetime  = nil; // scanned at
  _expiresAt = nil; // value from picker

  // fetched values
  _reg       = nil;
  _seq       = nil;
  _pack      = nil;
  _name      = nil;
  _size      = nil;
  _deduction = nil;
  _price     = nil;
  _category  = nil;
  _ean       = nil;
}


#pragma mark - NSCoding Interface

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _barcode   = [decoder decodeObjectForKey:@"barcode"];

  _reg       = [decoder decodeObjectForKey:@"reg"];
  _seq       = [decoder decodeObjectForKey:@"seq"];
  _pack      = [decoder decodeObjectForKey:@"pack"];
  _name      = [decoder decodeObjectForKey:@"name"];
  _size      = [decoder decodeObjectForKey:@"size"];
  _deduction = [decoder decodeObjectForKey:@"deduction"];
  _price     = [decoder decodeObjectForKey:@"price"];
  _category  = [decoder decodeObjectForKey:@"category"];
  _ean       = [decoder decodeObjectForKey:@"ean"];

  _datetime  = [decoder decodeObjectForKey:@"datetime"];

  if ([decoder containsValueForKey:@"expiresAt"]) {
    _expiresAt = [decoder decodeObjectForKey:@"expiresAt"];
  } else {
    _expiresAt = @"";
  }
  return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.barcode forKey:@"barcode"];

  [encoder encodeObject:self.reg forKey:@"reg"];
  [encoder encodeObject:self.seq forKey:@"seq"];
  [encoder encodeObject:self.pack forKey:@"pack"];
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.size forKey:@"size"];
  [encoder encodeObject:self.deduction forKey:@"deduction"];
  [encoder encodeObject:self.price forKey:@"price"];
  [encoder encodeObject:self.category forKey:@"category"];
  [encoder encodeObject:self.ean forKey:@"ean"];

  [encoder encodeObject:self.datetime forKey:@"datetime"];

  if (self.expiresAt && [self.expiresAt length] != 0) {
    [encoder encodeObject:self.expiresAt forKey:@"expiresAt"];
  } else {
    [encoder encodeObject:@"" forKey:@"expiresAt"];
  }
}

#pragma mark - Getter methods

- (NSString *)reg
{
  if (_reg) {
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
  if (_seq) {
    return _seq;
  } else if (_ean) {
    return [Constant detectStringWithRegexp:@"7680\\d{5}(\\d{3}).+"
                                       from:self.ean];
  } else {
    return @"";
  }
}


#pragma mark - Conversion to Dictionary

- (NSArray *)productKeys
{
  return @[
    @"reg", @"seq", @"pack",
    @"name", @"size", @"deduction",
    @"price", @"category", @"ean",
    @"barcode",

    @"datetime", @"expiresAt"
  ];
}

@end
