//
//  SessionToken.h
//  Generika
//
//  Created by b123400 on 2025/07/11.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SessionToken : NSObject

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *refreshToken;
@property (nonatomic, strong) NSDate *expiresAt;
@property (nonatomic, strong) NSString *scope;

- (instancetype)initWithJson:(id)jsonObj;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

- (BOOL)expired;

- (NSDictionary *)dictionaryRepresentation;

@end

NS_ASSUME_NONNULL_END
