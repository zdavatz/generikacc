//
//  ZurRoseProduct.h
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDXML.h"
#import "ZurRosePosology.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZurRoseProduct : NSObject

@property (nonatomic, strong) NSString *pharmacode; // optional
@property (nonatomic, strong) NSString *eanId; // optional
@property (nonatomic, strong) NSString *description; // optional
@property (nonatomic, assign) BOOL repetition;
@property (nonatomic, assign) int nrOfRepetitions; // optional, 0 - 99
@property (nonatomic, assign) int quantity; // 0 - 999
@property (nonatomic, strong) NSString *validityRepetition; // optional
@property (nonatomic, assign) int notSubstitutableForBrandName; // optional
@property (nonatomic, strong) NSString *remark; // optional
@property (nonatomic, assign) int dailymed; // optional boolean
@property (nonatomic, assign) int dailymed_mo; // optional boolean
@property (nonatomic, assign) int dailymed_tu; // optional boolean
@property (nonatomic, assign) int dailymed_we; // optional boolean
@property (nonatomic, assign) int dailymed_th; // optional boolean
@property (nonatomic, assign) int dailymed_fr; // optional boolean
@property (nonatomic, assign) int dailymed_sa; // optional boolean
@property (nonatomic, assign) int dailymed_su; // optional boolean

@property (nonatomic, strong) NSString *insuranceEanId; // optional
@property (nonatomic, strong) NSString *insuranceBsvNr; // optional
@property (nonatomic, strong) NSString *insuranceInsuranceName; // optional
@property (nonatomic, assign) int insuranceBillingType; // required
@property (nonatomic, strong) NSString *insuranceInsureeNr; // optional

@property (nonatomic, strong) NSArray<ZurRosePosology *> *posology;

- (DDXMLElement *)toXML;

@end

NS_ASSUME_NONNULL_END
