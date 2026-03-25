//
//  ZurRosePatientAddress.m
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "ZurRosePatientAddress.h"

@implementation ZurRosePatientAddress

- (XMLElement *)toXML {
    XMLElement *e = [XMLElement elementWithName:@"patientAddress"];
    [super writeBodyToXMLElement:e];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    [e addAttribute:[XMLNode attributeWithName:@"birthday" stringValue:[formatter stringFromDate:self.birthday]]];
    
    [e addAttribute:[XMLNode attributeWithName:@"langCode" stringValue:[@(self.langCode) stringValue]]];
    
    if (self.coverCardId) {
        [e addAttribute:[XMLNode attributeWithName:@"coverCardId" stringValue:self.coverCardId]];
    }
    
    [e addAttribute:[XMLNode attributeWithName:@"sex" stringValue:[@(self.sex) stringValue]]];
    
    [e addAttribute:[XMLNode attributeWithName:@"patientNr" stringValue:self.patientNr]];
    
    if (self.phoneNrMobile) {
        [e addAttribute:[XMLNode attributeWithName:@"phoneNrMobile" stringValue:self.phoneNrMobile]];
    }
    if (self.room) {
        [e addAttribute:[XMLNode attributeWithName:@"room" stringValue:self.room]];
    }
    if (self.section) {
        [e addAttribute:[XMLNode attributeWithName:@"section" stringValue:self.section]];
    }
    
    return e;
}

@end
