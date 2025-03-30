//
//  ZurRosePrescriptorAddress.m
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "ZurRosePrescriptorAddress.h"

@implementation ZurRosePrescriptorAddress

- (DDXMLElement *)toXML {
    DDXMLElement *e = [DDXMLElement elementWithName:@"prescriptorAddress"];
    [super writeBodyToXMLElement:e];

    [e addAttribute:[DDXMLNode attributeWithName:@"langCode" stringValue:[@(self.langCode) stringValue]]];
    [e addAttribute:[DDXMLNode attributeWithName:@"clientNrClustertec" stringValue:self.clientNrClustertec]];
    [e addAttribute:[DDXMLNode attributeWithName:@"zsrId" stringValue:self.zsrId]];
    if (self.eanId) {
        [e addAttribute:[DDXMLNode attributeWithName:@"eanId" stringValue:self.eanId]];
    }
    return e;
}

@end
