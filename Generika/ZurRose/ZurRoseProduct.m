//
//  ZurRoseProduct.m
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "ZurRoseProduct.h"

@implementation ZurRoseProduct

- (instancetype)init {
    self = [super init];
    self.nrOfRepetitions = -1;
    self.notSubstitutableForBrandName = -1;
    self.dailymed = -1;
    self.dailymed_mo = -1;
    self.dailymed_tu = -1;
    self.dailymed_we = -1;
    self.dailymed_th = -1;
    self.dailymed_fr = -1;
    self.dailymed_sa = -1;
    self.dailymed_su = -1;
    return self;
}

- (DDXMLElement *)toXML {
    DDXMLElement *e = [DDXMLElement elementWithName:@"product"];
    
    if (self.pharmacode) {
        [e addAttribute:[DDXMLNode attributeWithName:@"pharmacode" stringValue:self.pharmacode]];
    }
    if (self.eanId) {
        [e addAttribute:[DDXMLNode attributeWithName:@"eanId" stringValue:self.eanId]];
    }
    if (self.description_) {
        [e addAttribute:[DDXMLNode attributeWithName:@"description" stringValue:self.description_]];
    }
    [e addAttribute:[DDXMLNode attributeWithName:@"repetition" stringValue:self.repetition ? @"true" : @"false"]];
    if (self.nrOfRepetitions >= 0) {
        [e addAttribute:[DDXMLNode attributeWithName:@"nrOfRepetitions" stringValue:[@(self.nrOfRepetitions) stringValue]]];
    }
    [e addAttribute:[DDXMLNode attributeWithName:@"quantity" stringValue:[@(self.quantity) stringValue]]];
    if (self.validityRepetition) {
        [e addAttribute:[DDXMLNode attributeWithName:@"validityRepetition" stringValue:self.validityRepetition]];
    }
    if (self.notSubstitutableForBrandName >= 0) {
        [e addAttribute:[DDXMLNode attributeWithName:@"notSubstitutableForBrandName" stringValue:[@(self.notSubstitutableForBrandName) stringValue]]];
    }
    if (self.remark) {
        [e addAttribute:[DDXMLNode attributeWithName:@"remark" stringValue:self.remark]];
    }
    if (self.dailymed != -1) {
        [e addAttribute:[DDXMLNode attributeWithName:@"dailymed" stringValue:self.dailymed ? @"true" : @"false"]];
    }
    if (self.dailymed_mo != -1) {
        [e addAttribute:[DDXMLNode attributeWithName:@"dailymed_mo" stringValue:self.dailymed_mo ? @"true" : @"false"]];
    }
    if (self.dailymed_tu != -1) {
        [e addAttribute:[DDXMLNode attributeWithName:@"dailymed_tu" stringValue:self.dailymed_tu ? @"true" : @"false"]];
    }
    if (self.dailymed_we != -1) {
        [e addAttribute:[DDXMLNode attributeWithName:@"dailymed_we" stringValue:self.dailymed_we ? @"true" : @"false"]];
    }
    if (self.dailymed_th != -1) {
        [e addAttribute:[DDXMLNode attributeWithName:@"dailymed_th" stringValue:self.dailymed_th ? @"true" : @"false"]];
    }
    if (self.dailymed_fr != -1) {
        [e addAttribute:[DDXMLNode attributeWithName:@"dailymed_fr" stringValue:self.dailymed_fr ? @"true" : @"false"]];
    }
    if (self.dailymed_sa != -1) {
        [e addAttribute:[DDXMLNode attributeWithName:@"dailymed_sa" stringValue:self.dailymed_sa ? @"true" : @"false"]];
    }
    if (self.dailymed_su != -1) {
        [e addAttribute:[DDXMLNode attributeWithName:@"dailymed_su" stringValue:self.dailymed_su ? @"true" : @"false"]];
    }
    
    DDXMLElement *insurance = [DDXMLElement elementWithName:@"insurance"];
    [e addChild:insurance];
    
    if (self.insuranceEanId) {
        [insurance addAttribute:[DDXMLNode attributeWithName:@"eanId" stringValue:self.insuranceEanId]];
    }
    if (self.insuranceBsvNr) {
        [insurance addAttribute:[DDXMLNode attributeWithName:@"bsvNr" stringValue:self.insuranceBsvNr]];
    }
    if (self.insuranceInsuranceName) {
        [insurance addAttribute:[DDXMLNode attributeWithName:@"insuranceName" stringValue:self.insuranceInsuranceName]];
    }

    [insurance addAttribute:[DDXMLNode attributeWithName:@"billingType" stringValue:[@(self.insuranceBillingType) stringValue]]];

    if (self.insuranceInsureeNr) {
        [insurance addAttribute:[DDXMLNode attributeWithName:@"insureeNr" stringValue:self.insuranceInsureeNr]];
    }
    
    for (ZurRosePosology *p in self.posology) {
        [e addChild:p.toXML];
    }

    return e;
}

@end
