//
//  ProductManager.m
//  generika
//
//  Created by Yasuhiro Asaka on 09/02/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//

#import "ProductManager.h"
#import "Product.h"


@interface ProductManager ()

- (NSString *)productsPath;

@end

@implementation ProductManager

static ProductManager *_sharedInstance = nil;

+ (ProductManager *)sharedManager
{
  if (!_sharedInstance) {
    _sharedInstance = [[ProductManager alloc] init];
  }
  return _sharedInstance;
}

- (id)init
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _products = [[NSMutableArray array] init];
  return self;
}

- (void)dealloc
{
  _products = nil;
}


#pragma mark - Accessor Methods

- (void)addProduct:(Product *)product
{
  if (!product) {
    return;
  }
  [self.products addObject:product];
}

- (void)insertProduct:(Product *)product atIndex:(unsigned int)index
{
  if (!product) {
    return;
  }
  if (index > [self.products count]) {
    return;
  }
  [self.products insertObject:product atIndex:index];
}

- (Product *)productAtIndex:(unsigned int)index
{
  if (index > ([self.products count] - 1)) {
    return nil;
  }
  return [self.products objectAtIndex:index];
}

- (void)removeProductAtIndex:(unsigned int)index
{
  if (index > ([self.products count] - 1)) {
    return;
  }
  [self.products removeObjectAtIndex:index];
}

- (void)moveProductAtIndex:(unsigned int)fromIndex toIndex:(unsigned int)toIndex
{
  if (fromIndex > ([self.products count] - 1)) {
    return;
  }
  if (toIndex > [self.products count]) {
    return;
  }
  Product *product;
  product = [self.products objectAtIndex:fromIndex];
  [self.products removeObject:product];
  [self.products insertObject:product atIndex:toIndex];
}


#pragma mark - Saving and Loading methods

- (NSString *)save
{
  NSMutableArray *productDicts = [[NSMutableArray alloc] init];
  NSString *productsPath = [self productsPath];
  for (Product *product in self.products) {
    NSDictionary *productDict = [product dictionaryWithValuesForKeys:[product productKeys]];
    [productDicts addObject:productDict]; 
  }
  BOOL saved = [productDicts writeToFile:productsPath atomically:YES];
  if (saved) {
    return productsPath;
  } else {
    return nil;
  }
}

- (void)load
{
  NSString *productsPath = [self productsPath];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL exist = [fileManager fileExistsAtPath:productsPath isDirectory:NO];
  if (exist) {
    NSArray *productDicts = [[NSArray alloc] initWithContentsOfFile:productsPath];
    for (NSDictionary *productDict in productDicts) {
      Product *product = [[Product alloc] init]; 
      [product setValuesForKeysWithDictionary:productDict];
      [self addProduct:product];
    }
  }
}


#pragma mark - File Path

- (NSString *)productsPath
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  if ([paths count] < 1) {
    return nil;
  }
  NSString *path = [paths objectAtIndex:0];
  NSString *filePath = [path stringByAppendingPathComponent:@"products.plist"];
  return filePath;
}

@end
