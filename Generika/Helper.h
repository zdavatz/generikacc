//
//  Helper.h
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//
#import <CoreMedia/CoreMedia.h>

@interface Helper : NSObject

+ (UIColor *)activeUIColor;
+ (CGSize)getSizeOfLabel:(UILabel *)label inWidth:(CGFloat)width;

+ (NSString *)detectStringWithRegexp:(NSString *)regexpString
                                from:(NSString *)fromString;
+ (BOOL)isStringNumber:(NSString *)string;
+ (UIImage*)sampleBufferToUIImage:(CMSampleBufferRef)sampleBuffer;
+ (NSString *)sha256:(NSString *)input;

@end
