//
//  ZurRosePrescriptorAddress.m
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "ZurRosePrescriptorAddress.h"

@implementation ZurRosePrescriptorAddress

- (XMLElement *)toXML {
    XMLElement *e = [XMLElement elementWithName:@"prescriptorAddress"];
    [super writeBodyToXMLElement:e];

    [e addAttribute:[XMLNode attributeWithName:@"langCode" stringValue:[@(self.langCode) stringValue]]];
    [e addAttribute:[XMLNode attributeWithName:@"clientNrClustertec" stringValue:self.clientNrClustertec]];
    [e addAttribute:[XMLNode attributeWithName:@"zsrId" stringValue:self.zsrId]];
    if (self.eanId) {
        [e addAttribute:[XMLNode attributeWithName:@"eanId" stringValue:self.eanId]];
    }
    return e;
}

@end
