//
//  ProductManager.h
//  generika
//
//  Created by Yasuhiro Asaka on 09/02/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//


@class Product;

@interface ProductManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *products;

+ (ProductManager *)sharedManager;

- (void)addProduct:(Product *)product;
- (void)insertProduct:(Product *)project atIndex:(unsigned int)index;
- (Product *)productAtIndex:(unsigned int)index;
- (void)removeProductAtIndex:(unsigned int)index;
- (void)moveProductAtIndex:(unsigned int)fromIndex toIndex:(unsigned int)toIndex;

- (NSString *)save;
- (void)load;

@end
