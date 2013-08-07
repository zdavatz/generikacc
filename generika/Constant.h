//
//  Constant.h
//  generika
//
//  Created by Yasuhiro Asaka on 08/07/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//

extern NSString *const kOddbBaseURL;
extern NSString *const kOddbProductSearchBaseURL;
extern NSString *const kOddbMobileFlavorUserAgent;

@interface Constant : NSObject

+ (NSArray *)searchTypes;
+ (NSArray *)searchLanguages;
+ (NSArray *)searchLangs;
@end
