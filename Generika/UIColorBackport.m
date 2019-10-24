//
//  UIColorBackport.m
//  Generika
//
//  Created by Brian Chan on 2019/10/24.
//  Copyright © 2019 ywesee GmbH. All rights reserved.
//

#import "UIColorBackport.h"

@implementation UIColorBackport

+ (UIColor *)systemBackgroundColor {
    if ([[UIColor class] respondsToSelector:@selector(systemBackgroundColor)]) {
        return [super systemBackgroundColor];
    }
    return [UIColor whiteColor];
}

+ (UIColor *)labelColor {
    if ([[UIColor class] respondsToSelector:@selector(labelColor)]) {
        return [super labelColor];
    }
    return [UIColor blackColor];
}

+ (UIColor *)secondaryLabelColor {
    if ([[UIColor class] respondsToSelector:@selector(secondaryLabelColor)]) {
        return [super secondaryLabelColor];
    }
    return [UIColor colorWithRed:60.0/255.0
                           green:60.0/255.0
                            blue:67.0/255.0
                           alpha:0.6];
}

+ (UIColor *)systemRedColor {
    if ([[UIColor class] respondsToSelector:@selector(systemRedColor)]) {
        return [super systemRedColor];
    }
    return [UIColor colorWithRed:255.0/255.0
                           green:59.0/255.0
                            blue:48.0/255.0
                           alpha:1.0];
}

+ (UIColor *)systemGreenColor {
    if ([[UIColor class] respondsToSelector:@selector(systemGreenColor)]) {
        return [super systemGreenColor];
    }
    return [UIColor colorWithRed:52.0/255.0
                           green:199.0/255.0
                            blue:89.0/255.0
                           alpha:1.0];
}

@end
