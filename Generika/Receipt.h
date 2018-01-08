//
//  Receipt.h
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

@interface Operator : NSObject <NSCoding>

@property (nonatomic, strong, readwrite) NSString *signature;

@property (nonatomic, strong, readwrite) NSString *givenName;
@property (nonatomic, strong, readwrite) NSString *familyName;
@property (nonatomic, strong, readwrite) NSString *title;

@property (nonatomic, strong, readwrite) NSString *email;
@property (nonatomic, strong, readwrite) NSString *phone;

@property (nonatomic, strong, readwrite) NSString *address;
@property (nonatomic, strong, readwrite) NSString *city;
@property (nonatomic, strong, readwrite) NSString *zipcode;
@property (nonatomic, strong, readwrite) NSString *country;

+ (NSDictionary *)operatorKeyMaps;
+ (id)importFromDict:(NSDictionary *)dict;

- (UIImage *)signatureThumbnail;
- (NSArray *)operatorKeys;

@end


@interface Patient : NSObject <NSCoding>

@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSString *givenName;
@property (nonatomic, strong, readwrite) NSString *familyName;
@property (nonatomic, assign) int weight;
@property (nonatomic, assign) int height;
@property (nonatomic, strong, readwrite) NSString *birthDate;
@property (nonatomic, strong, readwrite) NSString *gender;

@property (nonatomic, strong, readwrite) NSString *email;
@property (nonatomic, strong, readwrite) NSString *phone;

@property (nonatomic, strong, readwrite) NSString *address;
@property (nonatomic, strong, readwrite) NSString *city;
@property (nonatomic, strong, readwrite) NSString *zipcode;
@property (nonatomic, strong, readwrite) NSString *country;

+ (NSDictionary *)patientKeyMaps;
+ (id)importFromDict:(NSDictionary *)dict;

- (NSArray *)patientKeys;

@end


@interface Receipt : NSObject <NSCoding>

@property (nonatomic, strong, readwrite) NSString *amkfile;
@property (nonatomic, strong, readwrite) NSString *datetime;

@property (nonatomic, strong, readwrite) NSString *hashedKey;
@property (nonatomic, strong, readwrite) NSString *placeDate;
@property (nonatomic, strong, readwrite) Operator *operator;
@property (nonatomic, strong, readwrite) Patient *patient;
@property (nonatomic, strong, readwrite) NSArray *products;

@property (nonatomic, strong, readwrite) NSString *issuedPlace;
@property (nonatomic, strong, readwrite) NSString *issuedDate;

+ (NSDictionary *)rereiptKeyMaps;
+ (id)importFromDict:(NSDictionary *)dict;

- (NSArray *)receiptKeys;

@end
