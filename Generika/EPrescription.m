//
//  EPrescription.m
//  Generika
//
//  Created by b123400 on 2024/11/21.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "EPrescription.h"
#import "NSData+GZIP.h"

@implementation EPrescriptionPatientId
@end
@implementation EPrescriptionPField
@end
@implementation EPrescriptionTakingTime
@end
@implementation EPrescriptionPosology
@end
@implementation EPrescriptionMedicament
@end

@implementation EPrescription

- (instancetype)initWithCHMED16A1String:(NSString *)str {
    if ([str hasPrefix:@"https://eprescription.hin.ch"]) {
        NSRange range = [str rangeOfString:@"#"];
        if (range.location == NSNotFound) return nil;
        str = [str substringFromIndex:range.location + 1];
        range = [str rangeOfString:@"&"];
        if (range.location == NSNotFound) return nil;
        str = [str substringToIndex:range.location];
    }
    NSString *prefix = @"CHMED16A1";
    if (![str hasPrefix:prefix]) {
        return nil;
    }
    if (self = [super init]) {
        str = [str substringFromIndex:[prefix length]];
        NSData *compressed = [[NSData alloc] initWithBase64EncodedString:str options:0];
        NSError *error = nil;
        NSData *decompressed1 = [compressed gunzippedData];
        NSString *ds1 = [[NSString alloc] initWithData:decompressed1 encoding:NSUTF8StringEncoding];
        NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:decompressed1 options:0 error:&error];
        if (![jsonObj isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        
        self.auth = jsonObj[@"Auth"];
        self.date = [EPrescription parseDateString:jsonObj[@"Dt"]];
        self.prescriptionId = jsonObj[@"Id"];
        self.medType = jsonObj[@"MedType"];
        self.zsr = jsonObj[@"Zsr"];
        self.rmk = jsonObj[@"rmk"];

        NSMutableArray<EPrescriptionPField *> *pfields = [NSMutableArray array];
        for (NSDictionary *pfield in jsonObj[@"PFields"]) {
            EPrescriptionPField *pf = [[EPrescriptionPField alloc] init];
            pf.nm = pfield[@"Nm"];
            pf.value = pfield[@"Val"];
            [pfields addObject:pf];
        }
        self.PFields = pfields;
        
        NSDictionary *patient = jsonObj[@"Patient"];
        self.patientBirthdate = [EPrescription parseDateString:patient[@"BDt"]];
        self.patientCity = patient[@"City"];
        self.patientFirstName = patient[@"FName"];
        self.patientLastName = patient[@"LName"];
        self.patientGender = patient[@"Gender"];
        self.patientPhone = patient[@"Phone"];
        self.patientStreet = patient[@"Street"];
        self.patientZip = patient[@"Zip"];
        self.patientEmail = patient[@"Email"];
        self.patientReceiverGLN = patient[@"Rcv"];
        self.patientLang = patient[@"Lng"];
        
        NSMutableArray<EPrescriptionPatientId *> *patientIds = [NSMutableArray array];
        for (NSDictionary *patientIdDict in patient[@"Ids"]) {
            EPrescriptionPatientId *pid = [[EPrescriptionPatientId alloc] init];
            pid.value = patientIdDict[@"Val"];
            pid.type = patientIdDict[@"Type"];
            [patientIds addObject:pid];
        }
        self.patientIds = patientIds;
        
        NSMutableArray<EPrescriptionPField *> *patientPFields = [NSMutableArray array];
        for (NSDictionary *patientPField in patient[@"PFields"]) {
            EPrescriptionPField *pf = [[EPrescriptionPField alloc] init];
            pf.nm = patientPField[@"Nm"];
            pf.value = patientPField[@"Val"];
            [patientPFields addObject:pf];
        }
        self.patientPFields = patientPFields;
        
        NSMutableArray<EPrescriptionMedicament *> *medicaments = [NSMutableArray array];
        for (NSDictionary *medicament in jsonObj[@"Medicaments"]) {
            EPrescriptionMedicament *m = [[EPrescriptionMedicament alloc] init];
            m.appInstr = medicament[@"AppInstr"];
            m.medicamentId = medicament[@"Id"];
            m.idType = medicament[@"IdType"];
            m.unit = medicament[@"Unit"];
            m.rep = medicament[@"rep"];
            m.nbPack = medicament[@"NbPack"];
            m.subs = medicament[@"Subs"];
            
            NSMutableArray<EPrescriptionPosology*> *pos = [NSMutableArray array];
            for (NSDictionary *posDict in medicament[@"Pos"]) {
                EPrescriptionPosology *p = [[EPrescriptionPosology alloc] init];
                
                p.dtFrom = [EPrescription parseDateString:posDict[@"DtFrom"]];
                p.dtTo = [EPrescription parseDateString:posDict[@"DtTo"]];
                p.cyDu = posDict[@"CyDu"];
                p.inRes = posDict[@"InRes"];
                
                p.d = posDict[@"D"];
                
                NSMutableArray<EPrescriptionTakingTime*>* tts = [NSMutableArray array];
                for (NSDictionary *ttDict in posDict[@"TT"]) {
                    EPrescriptionTakingTime *tt = [[EPrescriptionTakingTime alloc] init];
                    tt.off = ttDict[@"Off"];
                    tt.du = ttDict[@"Du"];
                    tt.doFrom = ttDict[@"DoFrom"];
                    tt.doTo = ttDict[@"DoTo"];
                    tt.a = ttDict[@"A"];
                    tt.ma = ttDict[@"MA"];
                    [tts addObject:tt];
                }
                p.tt = tts;
                
                [pos addObject:p];
            }
            m.pos = pos;
            
            [medicaments addObject:m];
        }
        self.medicaments = medicaments;
    }
    return self;
}

+ (NSDate *)parseDateString:(NSString *)str {
    if (!str || ![str isKindOfClass:[NSString class]]) return nil;
    static dispatch_once_t onceToken;
    static NSDateFormatter *isoFormatter = nil;
    static NSDateFormatter *isoDateFormatter = nil;
    // The specification says it's ISO8601, but I got a non-standard date as the sample input
    static NSDateFormatter *ePrescriptionFormatter = nil;
    dispatch_once(&onceToken, ^{
        isoFormatter = [[NSISO8601DateFormatter alloc] init];
        isoDateFormatter = [[NSDateFormatter alloc] init];
        isoDateFormatter.dateFormat = @"yyyy-MM-dd";
        ePrescriptionFormatter = [[NSDateFormatter alloc] init];
        ePrescriptionFormatter.dateFormat = @"yyyy-MM-ddHH:mm:ssZ";
    });
    NSDate *date = [isoFormatter dateFromString:str];
    if (date) return date;
    
    date = [isoDateFormatter dateFromString:str];
    if (date) return date;
    
    date = [ePrescriptionFormatter dateFromString:str];
    if (date) return date;
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([\\+|\\-])([0-9]{1,2}):?([0-9]{1,2})$"
                                                                           options:nil
                                                                             error:&error];
    NSTextCheckingResult *result = [regex firstMatchInString:str options:nil range:NSMakeRange(0, str.length)];
    NSString *overall = [str substringWithRange:[result range]];
    NSString *timeZoneOffsetMark = [str substringWithRange:[result rangeAtIndex:1]];
    NSString *timeZoneOffsetHour = [str substringWithRange:[result rangeAtIndex:2]];
    NSString *timeZoneOffsetMinutes = [str substringWithRange:[result rangeAtIndex:3]];
    
    NSString *newDateString = [NSString stringWithFormat:@"%@%@%02d:%02d",
                               [str substringToIndex:[result range].location],
                               timeZoneOffsetMark,
                               [timeZoneOffsetHour intValue],
                               [timeZoneOffsetMinutes intValue]
    ];
    
    date = [ePrescriptionFormatter dateFromString:newDateString];
    return date;
}

- (ZurRosePrescription *)toZurRosePrescription {
    ZurRosePrescription *prescription = [[ZurRosePrescription alloc] init];

    prescription.issueDate = self.date;
    prescription.prescriptionNr = self.prescriptionId;
    prescription.remark = self.rmk;
    prescription.validity = self.valDt; // ???

    prescription.user = @"";
    prescription.password = @"";
    prescription.deliveryType = ZurRosePrescriptionDeliveryTypePatient;
    prescription.ignoreInteractions = NO;
    prescription.interactionsWithOldPres = NO;
    
    ZurRosePrescriptorAddress *prescriptor = [[ZurRosePrescriptorAddress alloc] init];
    prescription.prescriptorAddress = prescriptor;
    prescriptor.zsrId = self.zsr;
    prescriptor.lastName = self.auth; // ???
    
    prescriptor.langCode = 1;
    prescriptor.clientNrClustertec = @"888870";
    prescriptor.street = @"";
    prescriptor.zipCode = @"";
    prescriptor.city = @"";
    
    ZurRosePatientAddress *patient = [[ZurRosePatientAddress alloc] init];
    prescription.patientAddress = patient;
    patient.lastName = self.patientLastName;
    patient.firstName = self.patientFirstName;
    patient.street = self.patientStreet;
    patient.city = self.patientCity;
    patient.kanton = [self swissKantonFromZip:self.patientZip];
    patient.zipCode = self.patientZip;
    patient.birthday = self.patientBirthdate;
    patient.sex = [self.patientGender intValue]; // same, 1 = m, 2 = f
    patient.phoneNrHome = self.patientPhone;
    patient.email = self.patientEmail;
    patient.email = self.patientEmail;
    patient.langCode = [self.patientLang.lowercaseString hasPrefix:@"de"] ? 1
        : [self.patientLang.lowercaseString hasPrefix:@"fr"] ? 2
        : [self.patientLang.lowercaseString hasPrefix:@"it"] ? 3
        : 1;
    
    for (EPrescriptionPatientId *pid in self.patientIds) {
        if ([pid.type isEqual:@(1)]) {
            patient.coverCardId = pid.value;
            patient.patientNr = pid.value; // ???
        }
    }
    
    NSMutableArray<ZurRoseProduct*> *products = [NSMutableArray array];
    for (EPrescriptionMedicament *medi in self.medicaments) {
        ZurRoseProduct *product = [[ZurRoseProduct alloc] init];
        [products addObject:product];
        
        switch (medi.idType.intValue) {
            case 2:
                // GTIN
                product.eanId = medi.medicamentId;
                break;
            case 3:
                // Pharmacode
                product.pharmacode = medi.medicamentId;
                break;
        }
        product.quantity = medi.nbPack.intValue; // ???
        product.remark = medi.appInstr;
        product.insuranceBillingType = 1;
        
        BOOL repetition = NO;
        NSMutableArray<ZurRosePosology *> *poses = [NSMutableArray array];
        for (EPrescriptionPosology *mediPos in medi.pos) {
            ZurRosePosology *pos = [[ZurRosePosology alloc] init];
            [poses addObject:pos];
            if (mediPos.d.count) {
                pos.qtyMorning = mediPos.d[0];
                pos.qtyMidday = mediPos.d[1];
                pos.qtyEvening = mediPos.d[2];
                pos.qtyNight = mediPos.d[3];
            }
            if (mediPos.dtTo) {
                repetition = YES;
            }
        }
        product.repetition = repetition;
        product.posology = poses;
    }
    prescription.products = products;
    
    return prescription;
}

- (NSString *)swissKantonFromZip:(NSString *)zip {
    if (!zip.length) return nil;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"swiss-zip-to-kanton" withExtension:@"json"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSError *error = nil;
    NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return parsed[zip];
}

- (NSString *)generatePatientUniqueID
{
    NSString *birthDateString = @"";
    
    if (self.patientBirthdate) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self.patientBirthdate];
        birthDateString = [NSString stringWithFormat:@"%d.%d.%d", components.day, components.month, components.year];
    }

    // The UUID should be unique and should be based on familyname, givenname, and birthday
    NSString *str = [NSString stringWithFormat:@"%@.%@.%@", [self.patientLastName lowercaseString] , [self.patientFirstName lowercaseString], birthDateString];
    NSString *hashed = [Helper sha256:str];
    return hashed;
}

- (NSDictionary *)amkDict {
    NSDateFormatter *birthDateDateFormatter = [[NSDateFormatter alloc] init];
    birthDateDateFormatter.dateFormat = @"yyyy.MM.dd";
    
    NSDateFormatter *placeDateFormatter = [[NSDateFormatter alloc] init];
    placeDateFormatter.dateFormat = @"dd.MM.yyyy (HH:mm:ss)";
    [placeDateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSMutableArray<NSDictionary*> *mediDicts = [NSMutableArray array];
    
    for (EPrescriptionMedicament *medi in self.medicaments) {
        [mediDicts addObject:@{
            @"eancode": medi.medicamentId,
        }];
    }
    
    NSDictionary *amkDict = @{
        @"prescription_hash": [[NSUUID UUID] UUIDString],
        // Normally place_date is composed with doctor's name or city,
        // however it's not available in ePrescription, instead we put the ZSR nummber here
        @"place_date": [NSString stringWithFormat:@"%@,%@", self.zsr ?: @"", [placeDateFormatter stringFromDate:self.date ?: [NSDate date]]],
        @"operator": @{
            @"gln": self.auth ?: @"",
            @"zsr_number": self.zsr ?: @"",
        },
        @"patient": @{
            @"patient_id": [self generatePatientUniqueID],
            @"given_name": self.patientLastName ?: @"",
            @"family_name": self.patientFirstName ?: @"",
            @"birth_date": self.patientBirthdate ? [birthDateDateFormatter stringFromDate:self.patientBirthdate] : @"",
            @"gender": self.patientGender.intValue == 1 ? @"M" : @"F",
            @"email_address": self.patientEmail ?: @"",
            @"phone_number": self.patientPhone ?: @"",
            @"postal_address": self.patientStreet ?: @"",
            @"city": self.patientCity ?: @"",
            @"zip_code": self.patientZip ?: @"",
            @"insurance_gln": self.patientReceiverGLN ?: @"",
        },
        @"medications": mediDicts,
    };
    return amkDict;
}

@end
