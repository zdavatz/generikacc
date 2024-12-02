//
//  ZurRoseAddress.h
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDXML.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZurRoseAddress : NSObject

@property (nonatomic, strong) NSString *title; // optional
@property (nonatomic, assign) int titleCode; // optional
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *firstName; // optional
@property (nonatomic, strong) NSString *street;
@property (nonatomic, strong) NSString *zipCode;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *kanton; // optional
@property (nonatomic, strong) NSString *country; // optional
@property (nonatomic, strong) NSString *phoneNrBusiness; // optional
@property (nonatomic, strong) NSString *phoneNrHome; // optional
@property (nonatomic, strong) NSString *faxNr; // optional
@property (nonatomic, strong) NSString *email; // optional

- (void)writeBodyToXMLElement:(DDXMLElement *)e;

@end

NS_ASSUME_NONNULL_END
