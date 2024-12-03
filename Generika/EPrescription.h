//
//  EPrescription.h
//  Generika
//
//  Created by b123400 on 2024/11/21.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZurRosePrescription.h"

NS_ASSUME_NONNULL_BEGIN

@interface EPrescriptionPatientId : NSObject
@property (nonatomic, strong) NSNumber *type;
@property (nonatomic, strong) NSString *value;
@end

@interface EPrescriptionPField : NSObject
@property (nonatomic, strong) NSString *nm;
@property (nonatomic, strong) NSString *value;
@end

@interface EPrescriptionTakingTime : NSObject
@property (nonatomic, strong) NSNumber *off;
@property (nonatomic, strong) NSNumber *du;
@property (nonatomic, strong) NSNumber *doFrom;
@property (nonatomic, strong) NSNumber *doTo;
@property (nonatomic, strong) NSNumber *a;
@property (nonatomic, strong) NSNumber *ma;
@end

@interface EPrescriptionPosology : NSObject
@property (nonatomic, strong) NSDate *dtFrom;
@property (nonatomic, strong) NSDate *dtTo;
@property (nonatomic, strong) NSNumber *cyDu;
@property (nonatomic, strong) NSNumber *inRes;
@property (nonatomic, strong) NSArray<NSNumber*> *d;
@property (nonatomic, strong) NSArray<EPrescriptionTakingTime*> *tt;
@end

@interface EPrescriptionMedicament : NSObject
@property (nonatomic, strong) NSString *appInstr;
@property (nonatomic, strong) NSString *medicamentId;
@property (nonatomic, strong) NSNumber *idType;
@property (nonatomic, strong) NSString *unit;
@property (nonatomic, strong) NSNumber *rep;
@property (nonatomic, strong) NSNumber *nbPack;
@property (nonatomic, strong) NSNumber *subs;
@property (nonatomic, strong) NSArray<EPrescriptionPosology *> *pos;
@end

@interface EPrescription : NSObject

- (instancetype)initWithCHMED16A1String:(NSString *)str;

@property (nonatomic, strong) NSString *auth;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *prescriptionId;
@property (nonatomic, strong) NSNumber * medType;
@property (nonatomic, strong) NSString *zsr;
@property (nonatomic, strong) NSArray<EPrescriptionPField *> *PFields;
@property (nonatomic, strong) NSString *rmk;
@property (nonatomic, strong) NSString *valBy; // The GLN of the healthcare professional who has validated the medication plan.
@property (nonatomic, strong) NSDate *valDt; // Date of validation

@property (nonatomic, strong) NSString *patientFirstName;
@property (nonatomic, strong) NSString *patientLastName;
@property (nonatomic, strong) NSDate *patientBirthdate;
@property (nonatomic, strong) NSNumber *patientGender;
@property (nonatomic, strong) NSString *patientStreet;
@property (nonatomic, strong) NSString *patientCity;
@property (nonatomic, strong) NSString *patientZip;
@property (nonatomic, strong) NSString *patientLang; // Patient’s language (ISO 639-19 language code) (e.g. de)
@property (nonatomic, strong) NSString *patientPhone;
@property (nonatomic, strong) NSString *patientEmail;
@property (nonatomic, strong) NSString *patientReceiverGLN;
@property (nonatomic, strong) NSArray<EPrescriptionPatientId *> *patientIds;
@property (nonatomic, strong) NSArray<EPrescriptionPField *> *patientPFields;

@property (nonatomic, strong) NSArray<EPrescriptionMedicament*> *medicaments;

// TODO: HcPerson, HcOrg

- (ZurRosePrescription *)toZurRosePrescription;

@end

NS_ASSUME_NONNULL_END
