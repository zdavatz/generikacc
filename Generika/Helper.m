//
//  Helper.m
//  Generika
//
//  Copyright (c) 2013-2018 ywesee GmbH. All rights reserved.
//

#import "Helper.h"
#import <CommonCrypto/CommonHMAC.h>

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

+ (BOOL)isStringNumber:(NSString *)string {
    return [@[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"] containsObject:string];
}

+ (UIImage*)sampleBufferToUIImage:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer

    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef cgImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);

    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    UIImage *newImage = [UIImage imageWithCGImage: cgImage];
    return newImage;
}

+ (NSString *)sha256:(NSString *)input {
    const char* str = [input UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, strlen(str), result);

    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++)
    {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

@end
