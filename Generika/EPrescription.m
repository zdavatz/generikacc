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
    if (!str) return nil;
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

@end
