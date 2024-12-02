//
//  ZurRosePatientAddress.m
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "ZurRosePatientAddress.h"

@implementation ZurRosePatientAddress

- (DDXMLElement *)toXML {
    DDXMLElement *e = [DDXMLElement elementWithName:@"patientAddress"];
    [super writeBodyToXMLElement:e];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    [e addAttribute:[DDXMLNode attributeWithName:@"birthday" stringValue:[formatter stringFromDate:self.birthday]]];
    
    [e addAttribute:[DDXMLNode attributeWithName:@"langCode" stringValue:[@(self.langCode) stringValue]]];
    
    if (self.coverCardId) {
        [e addAttribute:[DDXMLNode attributeWithName:@"coverCardId" stringValue:self.coverCardId]];
    }
    
    [e addAttribute:[DDXMLNode attributeWithName:@"sex" stringValue:[@(self.sex) stringValue]]];
    
    [e addAttribute:[DDXMLNode attributeWithName:@"patientNr" stringValue:self.patientNr]];
    
    if (self.phoneNrMobile) {
        [e addAttribute:[DDXMLNode attributeWithName:@"phoneNrMobile" stringValue:self.phoneNrMobile]];
    }
    if (self.room) {
        [e addAttribute:[DDXMLNode attributeWithName:@"room" stringValue:self.room]];
    }
    if (self.section) {
        [e addAttribute:[DDXMLNode attributeWithName:@"section" stringValue:self.section]];
    }
    
    return e;
}

@end
