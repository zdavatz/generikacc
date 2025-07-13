//
//  SessionToken.m
//  Generika
//
//  Created by b123400 on 2025/07/11.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "SessionToken.h"

@implementation SessionToken

- (instancetype)initWithJson:(id)jsonObj {
    if (self = [super init]) {
        self.accessToken = jsonObj[@"access_token"];
        self.refreshToken = jsonObj[@"refresh_token"];
        self.scope = jsonObj[@"scope"];
        
        NSNumber *expiresIn = jsonObj[@"expires_in"];
        self.expiresAt = [NSDate dateWithTimeIntervalSinceNow:expiresIn.doubleValue];
        
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.accessToken = dict[@"access_token"];
        self.refreshToken = dict[@"refresh_token"];
        self.scope = dict[@"scope"];
        self.expiresAt = dict[@"expires_at"];
    }
    return self;
}

- (BOOL)expired {
    return [[NSDate date] compare:self.expiresAt] == NSOrderedAscending;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"access_token": self.accessToken,
        @"refresh_token": self.refreshToken,
        @"scope": self.scope,
        @"expires_at": self.expiresAt,
    };
}

@end
