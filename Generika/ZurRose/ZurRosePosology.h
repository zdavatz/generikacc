//
//  ZurRosePosology.h
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDXML.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZurRosePosology : NSObject

@property (nonatomic, assign) int qtyMorning; // optional, -1 = null
@property (nonatomic, assign) int qtyMidday; // optional, -1 = null
@property (nonatomic, assign) int qtyEvening; // optional, -1 = null
@property (nonatomic, assign) int qtyNight; // optional, -1 = null
@property (nonatomic, strong) NSString *qtyMorningString; // optional
@property (nonatomic, strong) NSString *qtyMiddayString; // optional
@property (nonatomic, strong) NSString *qtyEveningString; // optional
@property (nonatomic, strong) NSString *qtyNightString; // optional
@property (nonatomic, strong) NSString *posologyText; // optional
@property (nonatomic, assign) int label; // optional, boolean, -1 = null

- (DDXMLElement *)toXML;

@end

NS_ASSUME_NONNULL_END
