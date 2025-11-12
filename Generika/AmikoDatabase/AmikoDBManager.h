//
//  DatabaseManager.h
//  Generika
//
//  Created by b123400 on 2025/10/18.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AmikoDBRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface AmikoDBManager : NSObject

+ (AmikoDBManager *)shared;

- (NSArray<AmikoDBRow*>*)findWithGtin:(NSString *)gtin;
- (NSArray<AmikoDBRow*>*)findWithRegnr:(NSString *)regnr;
- (NSArray<AmikoDBRow*>*)findWithATC:(NSString *)atc;

- (NSString *)dbStat;
- (NSString *)databaseLastUpdate;

- (NSURLSessionDownloadTask *)downloadNewDatabase:(void (^)(NSError *error))callback;

@end

NS_ASSUME_NONNULL_END
