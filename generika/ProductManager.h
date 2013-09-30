//
//  ProductManager.h
//  generika
//
//  Created by Yasuhiro Asaka on 09/02/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//


@class Product;

@interface ProductManager : UIDocument

@property (nonatomic, strong, readonly) NSMutableArray *products;

+ (ProductManager *)sharedManager;

- (BOOL)addProduct:(Product *)product;
- (BOOL)insertProduct:(Product *)project atIndex:(unsigned int)index;
- (BOOL)removeProductAtIndex:(unsigned int)index;
- (BOOL)moveProductAtIndex:(unsigned int)fromIndex toIndex:(unsigned int)toIndex;
- (NSString *)storeBarcode:(UIImage *)barcode ofEan:(NSString *)ean to:(NSString *)destination;
- (Product *)productAtIndex:(unsigned int)index;

- (BOOL)save;
- (void)load;

@end
