//
//  AmikoDBRow.h
//  Generika
//
//  Created by b123400 on 2025/10/20.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AmikoDBPackage.h"

NS_ASSUME_NONNULL_BEGIN

@interface AmikoDBRow : NSObject

@property (nonatomic, strong) NSString* _id;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* auth;
@property (nonatomic, strong) NSString* atc;
@property (nonatomic, strong) NSString* substances;
@property (nonatomic, strong) NSString* regnrs;
@property (nonatomic, strong) NSString* atc_class;
@property (nonatomic, strong) NSString* tindex_str;
@property (nonatomic, strong) NSString* application_str;
@property (nonatomic, strong) NSString* indications_str;
@property (nonatomic, strong) NSString* customer_id;
@property (nonatomic, strong) NSString* pack_info_str;
@property (nonatomic, strong) NSString* add_info_str;
@property (nonatomic, strong) NSString* ids_str;
@property (nonatomic, strong) NSString* titles_str;
@property (nonatomic, strong) NSString* content;
@property (nonatomic, strong) NSString* style_str;
@property (nonatomic, strong) NSString* packages;

- (instancetype)initWithRow:(NSArray *)row;

- (NSArray<AmikoDBPackage*>*)parsedPackages;

@end

NS_ASSUME_NONNULL_END
