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

- (XMLElement *)toXML {
    XMLElement *e = [XMLElement elementWithName:@"product"];
    
    if (self.pharmacode) {
        [e addAttribute:[XMLNode attributeWithName:@"pharmacode" stringValue:self.pharmacode]];
    }
    if (self.eanId) {
        [e addAttribute:[XMLNode attributeWithName:@"eanId" stringValue:self.eanId]];
    }
    if (self.description_) {
        [e addAttribute:[XMLNode attributeWithName:@"description" stringValue:self.description_]];
    }
    [e addAttribute:[XMLNode attributeWithName:@"repetition" stringValue:self.repetition ? @"true" : @"false"]];
    if (self.nrOfRepetitions >= 0) {
        [e addAttribute:[XMLNode attributeWithName:@"nrOfRepetitions" stringValue:[@(self.nrOfRepetitions) stringValue]]];
    }
    [e addAttribute:[XMLNode attributeWithName:@"quantity" stringValue:[@(self.quantity ?: 1) stringValue]]];
    if (self.validityRepetition) {
        [e addAttribute:[XMLNode attributeWithName:@"validityRepetition" stringValue:self.validityRepetition]];
    }
    if (self.notSubstitutableForBrandName >= 0) {
        [e addAttribute:[XMLNode attributeWithName:@"notSubstitutableForBrandName" stringValue:[@(self.notSubstitutableForBrandName) stringValue]]];
    }
    if (self.remark) {
        [e addAttribute:[XMLNode attributeWithName:@"remark" stringValue:self.remark]];
    }
    if (self.dailymed != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"dailymed" stringValue:self.dailymed ? @"true" : @"false"]];
    }
    if (self.dailymed_mo != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"dailymed_mo" stringValue:self.dailymed_mo ? @"true" : @"false"]];
    }
    if (self.dailymed_tu != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"dailymed_tu" stringValue:self.dailymed_tu ? @"true" : @"false"]];
    }
    if (self.dailymed_we != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"dailymed_we" stringValue:self.dailymed_we ? @"true" : @"false"]];
    }
    if (self.dailymed_th != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"dailymed_th" stringValue:self.dailymed_th ? @"true" : @"false"]];
    }
    if (self.dailymed_fr != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"dailymed_fr" stringValue:self.dailymed_fr ? @"true" : @"false"]];
    }
    if (self.dailymed_sa != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"dailymed_sa" stringValue:self.dailymed_sa ? @"true" : @"false"]];
    }
    if (self.dailymed_su != -1) {
        [e addAttribute:[XMLNode attributeWithName:@"dailymed_su" stringValue:self.dailymed_su ? @"true" : @"false"]];
    }
    
    XMLElement *insurance = [XMLElement elementWithName:@"insurance"];
    [e addChild:insurance];
    
    [insurance addAttribute:[XMLNode attributeWithName:@"eanId" stringValue:self.insuranceEanId.length ? self.insuranceEanId : @"1"]];
    
    if (self.insuranceBsvNr) {
        [insurance addAttribute:[XMLNode attributeWithName:@"bsvNr" stringValue:self.insuranceBsvNr]];
    }
    if (self.insuranceInsuranceName) {
        [insurance addAttribute:[XMLNode attributeWithName:@"insuranceName" stringValue:self.insuranceInsuranceName]];
    }

    [insurance addAttribute:[XMLNode attributeWithName:@"billingType" stringValue:[@(self.insuranceBillingType) stringValue]]];

    if (self.insuranceInsureeNr) {
        [insurance addAttribute:[XMLNode attributeWithName:@"insureeNr" stringValue:self.insuranceInsureeNr]];
    }
    
    for (ZurRosePosology *p in self.posology) {
        [e addChild:p.toXML];
    }

    return e;
}

@end
