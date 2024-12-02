//
//  ZurRosePrescriptorAddress.h
//  Generika
//
//  Created by b123400 on 2024/11/27.
//  Copyright © 2024 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZurRoseAddress.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZurRosePrescriptorAddress : ZurRoseAddress

@property (nonatomic, assign) int langCode; // 1 = de, 2 = fr, 3 = it
@property (nonatomic, strong) NSString *clientNrClustertec;
@property (nonatomic, strong) NSString *zsrId;
@property (nonatomic, strong) NSString *eanId; // optional

- (DDXMLElement *)toXML;

@end

NS_ASSUME_NONNULL_END
