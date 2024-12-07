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
@property (nonatomic, strong, readwrite) NSString *gln;
@property (nonatomic, strong, readwrite) NSString *zsrNumber;

+ (NSDictionary *)operatorKeyMaps;
+ (id)importFromDict:(NSDictionary *)dict;

- (UIImage *)signatureThumbnail;
- (NSArray *)operatorKeys;

@end


@interface Patient : NSObject <NSCoding>

@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSString *givenName;
@property (nonatomic, strong, readwrite) NSString *familyName;
@property (nonatomic, strong, readwrite) NSString *weight;
@property (nonatomic, strong, readwrite) NSString *height;
@property (nonatomic, strong, readwrite) NSString *birthDate;
@property (nonatomic, strong, readwrite) NSString *gender;
@property (nonatomic, strong, readwrite) NSString *gln;

@property (nonatomic, strong, readwrite) NSString *email;
@property (nonatomic, strong, readwrite) NSString *phone;

@property (nonatomic, strong, readwrite) NSString *address;
@property (nonatomic, strong, readwrite) NSString *city;
@property (nonatomic, strong, readwrite) NSString *zipcode;
@property (nonatomic, strong, readwrite) NSString *country;

@property (nonatomic, strong, readonly) NSString *genderSign;

+ (NSDictionary *)patientKeyMaps;
+ (id)importFromDict:(NSDictionary *)dict;

- (NSArray *)patientKeys;

@end


@interface Receipt : NSObject <NSCoding>

@property (nonatomic, strong, readwrite) NSString *amkfile;
@property (nonatomic, strong, readwrite) NSString *filename;
@property (nonatomic, strong, readwrite) NSString *datetime;

@property (nonatomic, strong, readwrite) NSString *hashedKey;
@property (nonatomic, strong, readwrite) NSString *placeDate;
@property (nonatomic, strong, readwrite) Operator *operator;
@property (nonatomic, strong, readwrite) Patient *patient;
@property (nonatomic, strong, readwrite) NSArray *products;

@property (nonatomic, strong, readonly) NSString *issuedDate;
@property (nonatomic, strong, readonly) NSString *issuedPlace;
@property (nonatomic, strong, readonly) NSString *importedAt;

+ (NSDictionary *)rereiptKeyMaps;
+ (id)importFromDict:(NSDictionary *)dict;

- (NSInteger)entriesCountOfField:(NSString *)field;
- (NSArray *)receiptKeys;

@end
