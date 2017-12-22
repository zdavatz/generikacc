//
//  Constant.h
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//


extern CGFloat const kVersionNumber_iOS_6_1;

extern NSString *const kOddbBaseURL;
extern NSString *const kOddbProductSearchBaseURL;
extern NSString *const kOddbMobileFlavorUserAgent;

#ifdef __IPHONE_6_0 // >= iOS 6
    #define kTextAlignmentCenter NSTextAlignmentCenter
    #define kTextAlignmentLeft   NSTextAlignmentLeft
    #define kTextAlignmentRight  NSTextAlignmentRight
#else
    #define kTextAlignmentCenter UITextAlignmentCenter
    #define kTextAlignmentLeft   UITextAlignmentLeft
    #define kTextAlignmentRight  UITextAlignmentRight
#endif

@interface Constant : NSObject

+ (NSArray *)searchTypes;
+ (NSArray *)searchLanguages;
+ (NSArray *)searchLangs;

+ (UIColor *)activeUIColor;

@end
