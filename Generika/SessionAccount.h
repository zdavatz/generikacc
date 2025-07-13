//
//  SessionUserInfo.h
//  Generika
//
//  Created by b123400 on 2025/07/11.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SessionAccount : NSObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *email;

- (instancetype)initWithJson:(id)jsonObj;

@end

NS_ASSUME_NONNULL_END
