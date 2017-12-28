//
//  Receipt.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "Receipt.h"

@implementation Operator

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
  _givenName = nil;
  _familyName = nil;
  _title = nil;
  _email = nil;
  _phone = nil;
  _address = nil;
  _city = nil;
  _zipcode = nil;
  _country = nil;

  _signature = nil;
}

#pragma mark - NSCoding Interface

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _givenName = [decoder decodeObjectForKey:@"given_name"];
  _familyName = [decoder decodeObjectForKey:@"family_name"];
  _title = [decoder decodeObjectForKey:@"title"];
  _email = [decoder decodeObjectForKey:@"email_address"];
  _phone = [decoder decodeObjectForKey:@"phone_number"];
  _address = [decoder decodeObjectForKey:@"postal_address"];
  _city = [decoder decodeObjectForKey:@"city"];
  _zipcode = [decoder decodeObjectForKey:@"zip_code"];
  _country = [decoder decodeObjectForKey:@"country"];

  _signature = [decoder decodeObjectForKey:@"signature"];

  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.givenName forKey:@"given_name"];
  [encoder encodeObject:self.familyName forKey:@"family_name"];
  [encoder encodeObject:self.title forKey:@"title"];

  [encoder encodeObject:self.email forKey:@"email_address"];
  [encoder encodeObject:self.phone forKey:@"phone_number"];
  [encoder encodeObject:self.address forKey:@"postal_address"];
  [encoder encodeObject:self.city forKey:@"city"];
  [encoder encodeObject:self.zipcode forKey:@"zip_code"];
  [encoder encodeObject:self.country forKey:@"country"];
  [encoder encodeObject:self.signature forKey:@"signature"];
}

#pragma mark - Conversion to Dictionary

- (NSArray *)operatorKeys
{
  return @[
    @"givenName", @"familyName", @"title"
    @"email", @"phone",
    @"address", @"city", @"zipcode", @"country",
    @"signature"
  ];
}

@end


@implementation Patient

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
  _id = nil;
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

#pragma mark - Conversion to Dictionary

- (NSArray *)patientKeys
{
  return @[
    @"id", @"givenName", @"familyName",
    @"weight", @"height",
    @"birthDate", @"gender",
    @"email", @"phone",
    @"address", @"city", @"zipcode", @"country",
  ];
}

@end


@implementation Medication

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
  _title = nil;
  _comment = nil;
  _reg = nil;
  _atc = nil;
  _ean = nil;
  _pack = nil;
  _name = nil;
  _owner = nil;
}

#pragma mark - Conversion to Dictionary

- (NSArray *)medicationKeys
{
  return @[
    @"title", @"comment",
    @"reg", @"atc", @"ean", @"pack",
    @"name", @"owner"
  ];
}

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
  _amkfile = nil; // file path
  _datetime = nil; // imported at

  _hashedKey = nil;
  _placeDate = nil;
  _operator = nil;
  _patient = nil;
  _medications = nil;

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
  _amkfile = [decoder decodeObjectForKey:@"amkfile"];
  _datetime = [decoder decodeObjectForKey:@"datetime"];

  // keys from amk file
  _hashedKey = [decoder decodeObjectForKey:@"prescription_hash"];
  _placeDate = [decoder decodeObjectForKey:@"place_date"];
  _operator = [decoder decodeObjectForKey:@"operator"];
  _patient = [decoder decodeObjectForKey:@"patient"];
  _medications = [decoder decodeObjectForKey:@"medications"];

  // "issuedPlace, issuedDate" are extracted from "place_date"
  _issuedPlace = nil;
  _issuedDate = nil;
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.amkfile forKey:@"amkfile"];
  [encoder encodeObject:self.datetime forKey:@"datetime"];

  [encoder encodeObject:self.hashedKey forKey:@"prescription_hash"];
  [encoder encodeObject:self.placeDate forKey:@"place_date"];
  [encoder encodeObject:self.operator forKey:@"operator"];
  [encoder encodeObject:self.patient forKey:@"patient"];
  [encoder encodeObject:self.medications forKey:@"medications"];
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
  return @[
    @"hashedKey", // hash
    @"placeDate", @"operator", @"patient", @"medications",

    @"amkfile",
    @"datetime"
  ];
}

@end
