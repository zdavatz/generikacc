//
//  SessionManager.h
//  Generika
//
//  Created by b123400 on 2025/07/10.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SessionToken.h"
#import "SessionAccount.h"

NS_ASSUME_NONNULL_BEGIN

@interface SessionManager : NSObject

+ (instancetype)shared;

- (void)loginWithViewController:(UIViewController *)vc callback:(void (^)(SessionToken * _Nullable token, NSError * _Nullable error))completionHandler;
- (void)fetchAccountWithToken:(SessionToken *)token callback:(void (^)(SessionAccount * _Nullable userInfo, NSError * _Nullable error))callback;

- (void)saveToken:(SessionToken *)token;
- (SessionToken *)savedToken;
- (void)logout;
- (BOOL)isLoggedIn;
@end

NS_ASSUME_NONNULL_END
