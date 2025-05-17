//
//  SettingsManager.h
//  Generika
//
//  Created by b123400 on 2025/05/17.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEYCHAIN_KEY_ZSR @"zsr"
#define KEYCHAIN_KEY_ZR_CUSTOMER_NUMBER @"zrCustomerNumber"

NS_ASSUME_NONNULL_BEGIN

@interface SettingsManager : NSObject

+ (instancetype)shared;

@property (nonatomic, strong) NSString *zsrNumber;
@property (nonatomic, strong) NSString *zrCustomerNumber;

- (NSDictionary*)getDictFromKeychain;
- (NSDictionary*)getDictFromKeychainCached:(BOOL)cached;
- (void)setDictToKeychain:(NSDictionary *)dict;
- (void)migrateFromUserDefaultsToKeychain;

@end

NS_ASSUME_NONNULL_END
