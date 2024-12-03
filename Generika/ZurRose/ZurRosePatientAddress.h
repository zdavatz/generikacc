//
//  ZurRosePatientAddress.h
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import "ZurRoseAddress.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZurRosePatientAddress : ZurRoseAddress

@property (nonatomic, strong) NSDate *birthday;
@property (nonatomic, assign) int langCode; // 1 = de, 2 = fr, 3 = it
@property (nonatomic, strong) NSString *coverCardId; // optional
@property (nonatomic, assign) int sex; // 1 = m, 2 = f
@property (nonatomic, strong) NSString *patientNr;
@property (nonatomic, strong) NSString *phoneNrMobile; // optional
@property (nonatomic, strong) NSString *room; // optional
@property (nonatomic, strong) NSString *section; // optional

- (DDXMLElement *)toXML;

@end

NS_ASSUME_NONNULL_END
