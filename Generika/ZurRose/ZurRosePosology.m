//
//  ZurRosePosology.m
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "ZurRosePosology.h"

@implementation ZurRosePosology

- (instancetype)init {
    self = [super init];
    self.qtyMorning = -1;
    self.qtyMidday = -1;
    self.qtyEvening = -1;
    self.qtyNight = -1;
    self.label = -1;
    return self;
}

- (XMLElement *)toXML {
    XMLElement *e = [XMLElement elementWithName:@"posology"];
    
    if (self.qtyMorning != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"qtyMorning" stringValue:[@(self.qtyMorning) stringValue]]];
    }
    if (self.qtyMidday != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"qtyMidday" stringValue:[@(self.qtyMidday) stringValue]]];
    }
    if (self.qtyEvening != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"qtyEvening" stringValue:[@(self.qtyEvening) stringValue]]];
    }
    if (self.qtyNight != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"qtyNight" stringValue:[@(self.qtyNight) stringValue]]];
    }
    if (self.qtyMorningString) {
        [e addAttribute:[XMLNode attributeWithName:@"qtyMorningString" stringValue:self.qtyMorningString]];
    }
    if (self.qtyMiddayString) {
        [e addAttribute:[XMLNode attributeWithName:@"qtyMiddayString" stringValue:self.qtyMiddayString]];
    }
    if (self.qtyEveningString) {
        [e addAttribute:[XMLNode attributeWithName:@"qtyEveningString" stringValue:self.qtyEveningString]];
    }
    if (self.qtyNightString) {
        [e addAttribute:[XMLNode attributeWithName:@"qtyNightString" stringValue:self.qtyNightString]];
    }
    if (self.posologyText) {
        [e addAttribute:[XMLNode attributeWithName:@"posologyText" stringValue:self.posologyText]];
    }
    if (self.label != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"label" stringValue:self.label ? @"true" : @"false"]];
    }
    
    return e;
}

@end
