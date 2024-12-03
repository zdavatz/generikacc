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

- (void)writeBodyToXMLElement:(DDXMLElement *)e {
    if (self.title) {
        [e addAttribute:[DDXMLNode attributeWithName:@"title" stringValue:self.title]];
    };

    if (self.titleCode != -1) {
        [e addAttribute:[DDXMLNode attributeWithName:@"titleCode" stringValue:[@(self.titleCode) stringValue]]];
    }

    [e addAttribute:[DDXMLNode attributeWithName:@"lastName" stringValue:self.lastName]];

    if (self.firstName) {
        [e addAttribute:[DDXMLNode attributeWithName:@"firstName" stringValue:self.firstName]];
    };

    [e addAttribute:[DDXMLNode attributeWithName:@"street" stringValue:self.street]];
    [e addAttribute:[DDXMLNode attributeWithName:@"zipCode" stringValue:self.zipCode]];
    [e addAttribute:[DDXMLNode attributeWithName:@"city" stringValue:self.city]];

    if (self.kanton) {
        [e addAttribute:[DDXMLNode attributeWithName:@"kanton" stringValue:self.kanton]];
    };
    if (self.country) {
        [e addAttribute:[DDXMLNode attributeWithName:@"country" stringValue:self.country]];
    };
    if (self.phoneNrBusiness) {
        [e addAttribute:[DDXMLNode attributeWithName:@"phoneNrBusiness" stringValue:self.phoneNrBusiness]];
    };
    if (self.phoneNrHome) {
        [e addAttribute:[DDXMLNode attributeWithName:@"phoneNrHome" stringValue:self.phoneNrHome]];
    };
    if (self.faxNr) {
        [e addAttribute:[DDXMLNode attributeWithName:@"faxNr" stringValue:self.faxNr]];
    };
    if (self.email) {
        [e addAttribute:[DDXMLNode attributeWithName:@"email" stringValue:self.email]];
    };    
}

@end
