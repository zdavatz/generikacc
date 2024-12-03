//
//  ZurRosePrescription.h
//  Generika
//
//  Created by b123400 on 2024/11/26.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDXML.h"
#import "ZurRosePrescriptorAddress.h"
#import "ZurRosePatientAddress.h"
#import "ZurRoseProduct.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    ZurRosePrescriptionDeliveryTypePatient = 1,
    ZurRosePrescriptionDeliveryTypeDoctor = 2,
    ZurRosePrescriptionDeliveryTypeAddress = 3,
} ZurRosePrescriptionDeliveryType;

@interface ZurRosePrescription : NSObject

@property (nonatomic, strong) NSDate *issueDate;
@property (nonatomic, strong) NSDate *validity;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *prescriptionNr; // optional
@property (nonatomic, assign) ZurRosePrescriptionDeliveryType deliveryType;
@property (nonatomic, assign) BOOL ignoreInteractions;
@property (nonatomic, assign) BOOL interactionsWithOldPres;
@property (nonatomic, strong) NSString *remark; // optional

@property (nonatomic, strong) ZurRosePrescriptorAddress *prescriptorAddress;
@property (nonatomic, strong) ZurRosePatientAddress *patientAddress;
//deliveryAddress // optional
//billingAddress // optional
//dailymed // optional

@property (nonatomic, strong) NSArray <ZurRoseProduct*> *products;

- (DDXMLDocument *)toXML;

- (void)sendToZurRoseWithCompletion:(void (^)(NSHTTPURLResponse* res, NSError* error))callback;

@end

NS_ASSUME_NONNULL_END
