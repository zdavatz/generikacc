//
//  Constant.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "Constant.h"


CGFloat const kVersionNumber_iOS_6_1 = 993.00; // NSFoundationVersionNumber_iOS_6_1

NSString *const kOddbBaseURL               = @"https://generika.cc";
NSString *const kOddbProductSearchBaseURL  = @"https://generika.cc/de/generika/api_search/ean";
NSString *const kOddbMobileFlavorUserAgent = @"org.oddb.generikacc";

NSString *const kSearchTypes[] = {
  @"Preisvergleich", @"PI", @"FI"
};
NSString *const kSearchLanguages[] = {
  @"Deutsch", @"Français"
};
NSString *const kSearchLangs[] = { // short name
  @"de", @"fr"
};

@implementation Constant

+ (NSArray *)searchTypes
{
  static NSArray *types = nil;
  if (types == nil) {
    int count = sizeof(kSearchTypes) / sizeof(*kSearchTypes);
    types = [[NSArray alloc] initWithObjects:kSearchTypes count:count];
  }
  return types;
}

+ (NSArray *)searchLanguages
{
  static NSArray *languages = nil;
  if (languages == nil) {
    int count = sizeof(kSearchLanguages) / sizeof(*kSearchLanguages);
    languages = [[NSArray alloc] initWithObjects:kSearchLanguages count:count];
  }
  return languages;
}

+ (NSArray *)searchLangs
{
  static NSArray *langs = nil;
  if (langs == nil) {
    int count = sizeof(kSearchLangs) / sizeof(*kSearchLangs);
    langs = [[NSArray alloc] initWithObjects:kSearchLangs count:count];
  }
  return langs;
}

@end
