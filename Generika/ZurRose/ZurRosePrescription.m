//
//  ZurRosePrescription.m
//  Generika
//
//  Created by b123400 on 2024/11/26.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "ZurRosePrescription.h"

@implementation ZurRosePrescription

- (DDXMLDocument *)toXML {
    NSError *error = nil;
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"<prescription></prescription>"
                                                               options:0
                                                                 error:&error];
    DDXMLElement *e = [document rootElement];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    [e addAttribute:[DDXMLNode attributeWithName:@"issueDate" stringValue:[formatter stringFromDate:self.issueDate]]];
    [e addAttribute:[DDXMLNode attributeWithName:@"validity" stringValue:[formatter stringFromDate:self.validity]]];
    [e addAttribute:[DDXMLNode attributeWithName:@"user" stringValue:self.user]];
    [e addAttribute:[DDXMLNode attributeWithName:@"password" stringValue:self.password]];
    if (self.prescriptionNr) {
        [e addAttribute:[DDXMLNode attributeWithName:@"prescriptionNr" stringValue:self.prescriptionNr]];
    }
    
    [e addAttribute:[DDXMLNode attributeWithName:@"deliveryType" stringValue:[@(self.deliveryType) stringValue]]];
    
    [e addAttribute:[DDXMLNode attributeWithName:@"ignoreInteractions" stringValue:self.ignoreInteractions ? @"true" : @"false"]];
    [e addAttribute:[DDXMLNode attributeWithName:@"interactionsWithOldPres" stringValue:self.interactionsWithOldPres ? @"true" : @"false"]];
    
    if (self.remark) {
        [e addAttribute:[DDXMLNode attributeWithName:@"remark" stringValue:self.remark]];
    }
    
    if (self.prescriptorAddress) {
        [e addChild:self.prescriptorAddress.toXML];
    }
    if (self.patientAddress) {
        [e addChild:self.patientAddress.toXML];
    }
    
    for (ZurRoseProduct *product in self.products) {
        [e addChild:product.toXML];
    }
    
    NSString *output = [document XMLString];
    NSLog(@"output %@", output);
    return document;
}

@end
