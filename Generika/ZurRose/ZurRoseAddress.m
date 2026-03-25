//
//  ZurRoseAddress.m
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "ZurRoseAddress.h"

@implementation ZurRoseAddress

- (instancetype)init {
    self = [super init];
    self.titleCode = -1;
    return self;
}

- (void)writeBodyToXMLElement:(XMLElement *)e {
    if (self.title) {
        [e addAttribute:[XMLNode attributeWithName:@"title" stringValue:self.title]];
    };

    if (self.titleCode != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"titleCode" stringValue:[@(self.titleCode) stringValue]]];
    }

    [e addAttribute:[XMLNode attributeWithName:@"lastName" stringValue:self.lastName]];

    if (self.firstName) {
        [e addAttribute:[XMLNode attributeWithName:@"firstName" stringValue:self.firstName]];
    };

    [e addAttribute:[XMLNode attributeWithName:@"street" stringValue:self.street]];
    [e addAttribute:[XMLNode attributeWithName:@"zipCode" stringValue:self.zipCode ?: @""]];
    [e addAttribute:[XMLNode attributeWithName:@"city" stringValue:self.city]];

    [e addAttribute:[XMLNode attributeWithName:@"kanton" stringValue:self.kanton ?: @""]];
    if (self.country) {
        [e addAttribute:[XMLNode attributeWithName:@"country" stringValue:self.country]];
    };
    if (self.phoneNrBusiness) {
        [e addAttribute:[XMLNode attributeWithName:@"phoneNrBusiness" stringValue:self.phoneNrBusiness]];
    };
    if (self.phoneNrHome) {
        [e addAttribute:[XMLNode attributeWithName:@"phoneNrHome" stringValue:self.phoneNrHome]];
    };
    if (self.faxNr) {
        [e addAttribute:[XMLNode attributeWithName:@"faxNr" stringValue:self.faxNr]];
    };
    if (self.email) {
        [e addAttribute:[XMLNode attributeWithName:@"email" stringValue:self.email]];
    };    
}

@end
