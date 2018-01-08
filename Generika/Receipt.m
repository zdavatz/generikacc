//
//  Receipt.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "Receipt.h"

@implementation Operator

+ (NSDictionary *)operatorKeyMaps
{
  return @{ // property : importingKey
    @"signature"  : @"signature",
    @"givenName"  : @"given_name",
    @"familyName" : @"family_name",
    @"title"      : @"title",
    @"email"      : @"email_address",
    @"phone"      : @"phone_number",
    @"address"    : @"postal_address",
    @"city"       : @"city",
    @"zipcode"    : @"zip_code",
    @"country"    : @"country",
  };
}

+ (id)importFromDict:(NSDictionary *)dict
{
  Operator *operator = [[self alloc] init];
  NSDictionary *keyMaps = [self operatorKeyMaps];
  for (NSString *key in [keyMaps allKeys]) {
    NSString *value;
    // get value from dict using importing key
    value = [dict valueForKey:keyMaps[key]] ?: [NSNull null];
    if (value == nil || [value isEqual:[NSNull null]]) {
      value = @"";
    }
    [operator setValue:value forKey:key];
  }
  return operator;
}

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
  _signature = nil;

  _givenName = nil;
  _familyName = nil;
  _title = nil;
  _email = nil;
  _phone = nil;
  _address = nil;
  _city = nil;
  _zipcode = nil;
  _country = nil;
}

- (UIImage *)signatureThumbnail
{
  if (self.signature == nil) {
    return nil;
  }
  NSData *data = [[NSData alloc]
    initWithBase64EncodedString:self.signature
                        options:NSDataBase64DecodingIgnoreUnknownCharacters];
  // original image
  UIImage* image = [UIImage imageWithData:data];

  // resize
  CGSize size = CGSizeMake(90.0, 45.0);
  CGRect rect = CGRectZero;
  
  CGFloat width = size.width / image.size.width;
  CGFloat height = size.height / image.size.height;
  CGFloat ratio = MIN(width, height);
  
  rect.size.width = image.size.width * ratio;
  rect.size.height = image.size.height * ratio;
  rect.origin.x = (size.width - rect.size.width) / 2.0f;
  rect.origin.y = (size.height - rect.size.height) / 2.0f;
  
  UIGraphicsBeginImageContextWithOptions(size, NO, 0 );
  [image drawInRect:rect];
  UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return scaledImage;
}

#pragma mark - NSCoding Interface

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (!self) {
    return nil;
  }
  for (NSString *key in [self operatorKeys]) {
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
  for (NSString *key in [self operatorKeys]) {
    NSString *value = [self valueForKey:key] ?: [NSNull null];
    if (value == nil || [value isEqual:[NSNull null]]) {
      value = @"";
    }
    [encoder encodeObject:value forKey:key];
  }
}

#pragma mark - Conversion to Dictionary

- (NSArray *)operatorKeys
{
  return [[[self class] operatorKeyMaps] allKeys];
}

@end


@implementation Patient

+ (NSDictionary *)patientKeyMaps
{
  return @{ // property : importingKey
    @"identifier" : @"patient_id",
    @"givenName"  : @"given_name",
    @"familyName" : @"family_name",
    @"weight"     : @"weight_kg",
    @"height"     : @"height_cm",
    @"birthDate"  : @"birth_date",
    @"gender"     : @"gender",
    @"email"      : @"email_address",
    @"phone"      : @"phone_number",
    @"address"    : @"postal_address",
    @"city"       : @"city",
    @"zipcode"    : @"zip_code",
    @"country"    : @"country",
  };
}

+ (id)importFromDict:(NSDictionary *)dict
{
  Patient *patient = [[self alloc] init];
  NSDictionary *keyMaps = [self patientKeyMaps];
  for (NSString *key in [keyMaps allKeys]) {
    NSString *value;
    value = [dict valueForKey:keyMaps[key]] ?: [NSNull null];
    if (value == nil || [value isEqual:[NSNull null]]) {
      value = @"";
    }
    [patient setValue:value forKey:key];
  }
  return patient;
}

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
  _identifier = nil;
  _givenName = nil;
  _familyName = nil;
  _birthDate = nil;
  _gender = nil;
  _email = nil;
  _phone = nil;
  _address = nil;
  _city = nil;
  _zipcode = nil;
  _country = nil;
}

#pragma mark - NSCoding Interface

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (!self) {
    return nil;
  }
  for (NSString *key in [self patientKeys]) {
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
  for (NSString *key in [self patientKeys]) {
    NSString *value = [self valueForKey:key] ?: [NSNull null];
    if (value == nil || [value isEqual:[NSNull null]]) {
      value = @"";
    }
    [encoder encodeObject:value forKey:key];
  }
}

#pragma mark - Conversion to Dictionary

- (NSArray *)patientKeys
{
  return [[[self class] patientKeyMaps] allKeys];
}

@end


@implementation Receipt

+ (NSDictionary *)receiptKeyMaps
{
  return @{ // property : importingKey
    @"hashedKey" : @"prescription_hash",
    @"placeDate" : @"place_date",
    @"operator"  : @"operator",
    @"patient"   : @"patient",
    @"products"  : @"medications"
  };
}

+ (id)importFromDict:(NSDictionary *)dict
{
  Receipt *receipt = [[self alloc] init];
  NSDictionary *keyMaps = [self receiptKeyMaps];
  for (NSString *key in [keyMaps allKeys]) {
    NSString *value;
    value = [dict valueForKey:keyMaps[key]] ?: [NSNull null];
    if (value == nil || [value isEqual:[NSNull null]]) {
      value = @"";
    }
    [receipt setValue:value forKey:key];
  }
  return receipt;
}

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
  _amkfile = nil; // file path
  _datetime = nil; // imported at

  _hashedKey = nil;
  _placeDate = nil;
  _operator = nil;
  _patient = nil;
  _products = nil;

  // values from placeDate
  _issuedPlace = nil;
  _issuedDate = nil;
}

#pragma mark - NSCoding Interface

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (!self) {
    return nil;
  }
  for (NSString *key in [self receiptKeys]) {
    NSString *value;
    if ([decoder containsValueForKey:key]) {
      value = [decoder decodeObjectForKey:key];
    } else {
      value = @"";
    }
    [self setValue:value forKey:key];
  }

  // "issuedPlace, issuedDate" are extracted from "place_date"
  _issuedPlace = nil;
  _issuedDate = nil;
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  for (NSString *key in [self receiptKeys]) {
    NSString *value = [self valueForKey:key] ?: [NSNull null];
    if (value == nil || [value isEqual:[NSNull null]]) {
      value = @"";
    }
    [encoder encodeObject:value forKey:key];
  }
}

#pragma mark - Getter methods

- (NSString *)issuedPlace
{
  if (_issuedPlace) {
    return _issuedPlace;
  } else if (self.placeDate) {
    _issuedPlace = [Constant detectStringWithRegexp:@".*,\\s?(\\w+)$"
                                               from:self.placeDate];
    return _issuedPlace;
  } else {
    return @"";
  }
}

- (NSString *)issuedDate
{
  if (_issuedDate) {
    return _issuedDate;
  } else if (self.placeDate) {
    _issuedDate = [Constant detectStringWithRegexp:@"(\\w*),\\s?.+$"
                                              from:self.placeDate];
    return _issuedDate;
  } else {
    return @"";
  }
}

#pragma mark - Conversion to Dictionary

- (NSArray *)receiptKeys
{
  NSArray *additionalKeys = @[
    @"amkfile",
    @"datetime"
  ];
  return [additionalKeys arrayByAddingObjectsFromArray:
    [[[self class] receiptKeyMaps] allKeys]];
}

@end
