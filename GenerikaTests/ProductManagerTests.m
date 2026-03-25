//
//  ProductManagerTests.m
//  ProductManagerTests
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ProductManager.h"
#import "Product.h"

@interface ProductManagerTests : XCTestCase

@end

@implementation ProductManagerTests

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testInit
{
  ProductManager *manager = [[ProductManager alloc] init];

  NSMutableArray *products = [[NSMutableArray array] init];

  XCTAssertNotNil(manager);
  XCTAssert([manager.products isEqualToArray:products]);
}

- (void)testDealloc
{
  // pass
}

- (void)testAddProduct_nilProductIsGiven
{
  ProductManager *manager = [[ProductManager alloc] init];
  XCTAssertFalse([manager addProduct:nil]);
}

- (void)testAddProduct_whenSavedAsSuccess
{
  ProductManager *manager = [[ProductManager alloc] init];

  // product has ean
  NSString *vEan = @"7680317060176";
  Product *product = [[Product alloc] initWithEan:vEan];
  XCTAssertNotNil(product);
}

- (void)testInsertProductAtIndex_nilIndexIsGiven
{
  // pass
}

- (void)testInsertProductAtIndex_invalidIndexIsGiven
{
  // pass
}

- (void)testInsertProductAtIndex_whenSavedAsSuccess
{
  // pass
}

- (void)testRemoveProduct_invalidIndexIsGiven
{
  // pass
}

- (void)testRemoveProduct_whenSavedAsSuccess
{
  // pass
}

- (void)testMoveProductAtIndexToINdex_invalidFromIndexIsGiven
{
  // pass
}

- (void)testMoveProductAtIndexToINdex_invalidToIndexIsGiven
{
  // pass
}

- (void)testMoveProductAtIndexToIndex_whenSavedAsSuccess
{
  // pass
}

- (void)testStoreBarcodeOfEanTo_whenFileManagerCreatesError
{
  // pass
}

- (void)testStoreBarcodeOfEanTo_whenSavedAsSuccess
{
  // pass
}

- (void)testProductAtIndex_invalidIndexIsGiven
{
  // pass
}

- (void)testSave
{
  // pass
}

- (void)testLoad
{
  // pass
}

@end
