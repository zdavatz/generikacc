//
//  Receipt.h
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//


@interface Receipt : NSObject <NSCoding>

@property (nonatomic, strong, readwrite) NSString *amkfile;
@property (nonatomic, strong, readwrite) NSString *datetime;
@property (nonatomic, strong, readwrite) NSString *expiresAt;

- (NSArray *)receiptKeys;

@end
