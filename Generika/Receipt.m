//
//  Receipt.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "Receipt.h"


@interface Receipt ()

@end

@implementation Receipt

- (id)init
{
  self = [super init];
  if (!self) {
    return nil;
  }
  return self;
}

- (void)dealloc
{
  _datetime  = nil;
  _expiresAt = nil;
}


#pragma mark - NSCoding Interface

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (!self) {
    return nil;
  }
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
  [encoder encodeObject:self.datetime forKey:@"datetime"];

  if (self.expiresAt && [self.expiresAt length] != 0) {
    [encoder encodeObject:self.expiresAt forKey:@"expiresAt"];
  } else {
    [encoder encodeObject:@"" forKey:@"expiresAt"];
  }
}

#pragma mark - Conversion to Dictionary

- (NSArray *)receiptKeys
{
  return @[
    @"datetime", @"expiresAt"
  ];
}

@end
