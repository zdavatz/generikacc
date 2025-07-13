//
//  SessionUserInfo.m
//  Generika
//
//  Created by b123400 on 2025/07/11.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "SessionAccount.h"

@implementation SessionAccount

- (instancetype)initWithJson:(id)jsonObj {
    if (self = [super init]) {
        self.firstName = jsonObj[@"firstName"];
        self.lastName = jsonObj[@"lastName"];
        self.email = jsonObj[@"email"];
        self.username = jsonObj[@"username"];
    }
    return self;
}

@end
