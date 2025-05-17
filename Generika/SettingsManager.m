//
//  SettingsManager.m
//  Generika
//
//  Created by b123400 on 2025/05/17.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "SettingsManager.h"

#define KEYCHAIN_KEY @"ywesee-keychain"

@interface SettingsManager ()
@property (nonatomic, strong) NSDictionary *cacheDict;
@end

@implementation SettingsManager

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static SettingsManager *shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [[SettingsManager alloc] init];
    });
    return shared;
}

- (NSString *)zsrNumber {
    return [self getDictFromKeychain][KEYCHAIN_KEY_ZSR];
}

- (void)setZsrNumber:(NSString *)zsrNumber {
    NSMutableDictionary *dict = [[self getDictFromKeychain] mutableCopy];
    dict[KEYCHAIN_KEY_ZSR] = zsrNumber;
    [self setDictToKeychain:dict];
}

- (NSString *)zrCustomerNumber {
    return [self getDictFromKeychain][KEYCHAIN_KEY_ZR_CUSTOMER_NUMBER];
}

- (void)setZrCustomerNumber:(NSString *)zrCustomerNumber {
    NSMutableDictionary *dict = [[self getDictFromKeychain] mutableCopy];
    dict[KEYCHAIN_KEY_ZR_CUSTOMER_NUMBER] = zrCustomerNumber;
    [self setDictToKeychain:dict];
}

- (NSDictionary*)getDictFromKeychain {
    return [self getDictFromKeychainCached:true];
}

- (NSDictionary*)getDictFromKeychainCached:(BOOL)useCached {
    if (useCached && self.cacheDict) {
        return self.cacheDict;
    }
    NSDictionary *readQuery = @{
        (id)kSecAttrAccount: KEYCHAIN_KEY,
        (id)kSecReturnData: (id)kCFBooleanTrue,
        (id)kSecClass:      (id)kSecClassGenericPassword
    };
    NSData *gotData = nil;
    OSStatus osStatus = SecItemCopyMatching((CFDictionaryRef)readQuery, (CFTypeRef)&gotData);
    if (osStatus == errSecItemNotFound) {
        // First time, no data
        return @{};
    }
    if(osStatus != noErr) {
        NSLog(@"OSStatus: %d", osStatus);
        return nil;
    }
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:gotData options:0 error:&error];
    if (error) {
        NSLog(@"Error when reading from key-chain %@", error.description);
    }
    self.cacheDict = dict;
    return dict;
}

- (void)setDictToKeychain:(NSDictionary *)dict {
    NSError *error = nil;
    CFErrorRef cfError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:nil error:&error];
    SecAccessControlRef access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleAlways, kSecAccessControlUserPresence, &cfError);
    error = (__bridge NSError *)cfError;
    if (error) {
        NSLog(@"Cannot gen access %@", error.description);
        return;
    }
//    LAContext *context = [[LAContext alloc] init];
    NSDictionary *addQuery = @{
        (id)kSecAttrAccount: KEYCHAIN_KEY,
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrAccessControl: (__bridge id)access,
        (id)kSecValueData: data,
    };
    OSStatus status = status = SecItemAdd((CFDictionaryRef)addQuery, nil);
    if (status == errSecDuplicateItem) {
        NSLog(@"Cannot add, try update %d", status);
        NSDictionary *readQuery = @{
            (id)kSecAttrAccount: KEYCHAIN_KEY,
            (id)kSecClass: (id)kSecClassGenericPassword,
            (id)kSecReturnData: (id)kCFBooleanFalse,
        };
        NSDictionary *updateQuery = @{
            (id)kSecAttrAccessControl: (__bridge id)access,
            (id)kSecValueData: data,
        };
        status = SecItemUpdate((CFDictionaryRef)readQuery, (CFDictionaryRef)updateQuery);
        NSLog(@"Update: %d", status);
    }
    if (status != errSecSuccess) {
        NSLog(@"Cannot save dict %d, %@", status, error.description);
    } else {
        self.cacheDict = dict;
    }
}

- (void)migrateFromUserDefaultsToKeychain {
    // We used to save ZSR and zrCustomerNumber in UserDefaults,
    // Moving them to keychain
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *zsr = [userDefaults stringForKey:@"profile.zsr"];
    if (zsr) {
        [userDefaults removeObjectForKey:@"profile.zsr"];
    }
    NSString *zrCustomerNumber = [userDefaults stringForKey:@"profile.zrCustomerNumber"];
    if (zrCustomerNumber) {
        [userDefaults removeObjectForKey:@"profile.zrCustomerNumber"];
    }
    if (zsr || zrCustomerNumber) {
        [userDefaults synchronize];
        NSMutableDictionary *keychain = [[[SettingsManager shared] getDictFromKeychain] mutableCopy];
        if (zsr) keychain[KEYCHAIN_KEY_ZSR] = zsr;
        if (zrCustomerNumber) keychain[KEYCHAIN_KEY_ZR_CUSTOMER_NUMBER] = zrCustomerNumber;
        [[SettingsManager shared] setDictToKeychain:keychain];
    }
}

@end
