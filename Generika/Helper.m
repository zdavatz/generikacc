//
//  Helper.m
//  Generika
//
//  Copyright (c) 2013-2018 ywesee GmbH. All rights reserved.
//

#import "Helper.h"


@implementation Helper

#pragma UI Helpers

+ (UIColor *)activeUIColor
{
  UIColor *color = [UIColor colorWithRed:6/255.0
                                   green:121/255.0
                                    blue:251/255.0
                                   alpha:1.0];
  return color;
}

+ (CGSize)getSizeOfLabel:(UILabel *)label inWidth:(CGFloat)width
{
  CGSize constraint = CGSizeMake(width, CGFLOAT_MAX);
  NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
  CGSize boundSize = [label.text
    boundingRectWithSize:constraint
                 options:NSStringDrawingUsesLineFragmentOrigin
              attributes:@{NSFontAttributeName:label.font}
                 context:context].size;
  return CGSizeMake(ceil(boundSize.width), ceil(boundSize.height));
}


#pragma Other Methods

+ (NSString *)detectStringWithRegexp:(NSString *)regexpString
                                from:(NSString *)fromString
{
  NSString *str;
  NSError *error = nil;
  NSRegularExpression *regexp =
    [NSRegularExpression regularExpressionWithPattern:regexpString
                                              options:0
                                                error:&error];
  if (error == nil) {
    NSTextCheckingResult *match =
      [regexp firstMatchInString:fromString
                         options:0
                           range:NSMakeRange(0, fromString.length)];
    if (match.numberOfRanges > 1) {
      str = [fromString substringWithRange:[match rangeAtIndex:1]];
    }
  }
  if (str == nil) {
    str = @"";
  }
  return str;
}

@end
