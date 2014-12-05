//
//  Product.m
//  Generika
//
//  Created by Yasuhiro Asaka on 09/02/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//

#import "Product.h"


@interface Product ()

- (NSString *)detectNumberFromEanWithRegexpString:(NSString *)regexpString;

@end

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
  _reg       = nil;
  _seq       = nil;
  _pack      = nil;
  _name      = nil;
  _size      = nil;
  _deduction = nil;
  _price     = nil;
  _category  = nil;
  _barcode   = nil;
  _ean       = nil;
  _datetime  = nil;
}


#pragma mark - NSCoding Interface

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _reg       = [decoder decodeObjectForKey:@"reg"];
  _seq       = [decoder decodeObjectForKey:@"seq"];
  _pack      = [decoder decodeObjectForKey:@"pack"];
  _name      = [decoder decodeObjectForKey:@"name"];
  _size      = [decoder decodeObjectForKey:@"size"];
  _deduction = [decoder decodeObjectForKey:@"deduction"];
  _price     = [decoder decodeObjectForKey:@"price"];
  _category  = [decoder decodeObjectForKey:@"category"];
  _barcode   = [decoder decodeObjectForKey:@"barcode"];
  _ean       = [decoder decodeObjectForKey:@"ean"];
  _datetime  = [decoder decodeObjectForKey:@"datetime"];
  return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.reg forKey:@"reg"];
  [encoder encodeObject:self.seq forKey:@"seq"];
  [encoder encodeObject:self.pack forKey:@"pack"];
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.size forKey:@"size"];
  [encoder encodeObject:self.deduction forKey:@"deduction"];
  [encoder encodeObject:self.price forKey:@"price"];
  [encoder encodeObject:self.category forKey:@"category"];
  [encoder encodeObject:self.barcode forKey:@"barcode"];
  [encoder encodeObject:self.ean forKey:@"ean"];
  [encoder encodeObject:self.datetime forKey:@"datetime"];
}

#pragma mark - Getter methods

- (NSString *)reg
{
  if (_reg) {
    return _reg;
  } else if (self.ean) {
    return [self detectNumberFromEanWithRegexpString:@"7680(\\d{5}).+"];
  } else {
    return @"";
  }
}

- (NSString *)seq
{
  if (_seq) {
    return _seq;
  } else if (_ean) {
    return [self detectNumberFromEanWithRegexpString:@"7680\\d{5}(\\d{3}).+"];
  } else {
    return @"";
  }
}

- (NSString *)detectNumberFromEanWithRegexpString:(NSString *)regexpString
{
  NSString *num = @"";
  NSError *error = nil;
  NSRegularExpression *regexp = 
    [NSRegularExpression regularExpressionWithPattern:regexpString
                                              options:0
                                                error:&error];
  if (error == nil) {
    NSTextCheckingResult *match =
      [regexp firstMatchInString:self.ean options:0 range:NSMakeRange(0, self.ean.length)];
    if (match.numberOfRanges > 1) {
      num = [self.ean substringWithRange:[match rangeAtIndex:1]];
    }
  }
  return num;
}


#pragma mark - Conversion to Dictionary

- (NSArray *)productKeys
{
  return @[
    @"reg", @"seq", @"pack",
    @"name", @"size", @"deduction",
    @"price", @"category", @"barcode", @"ean",
    @"datetime"
  ];
}

@end
