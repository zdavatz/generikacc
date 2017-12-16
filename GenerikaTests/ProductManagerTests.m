//
//  ProductManagerTests.m
//  ProductManagerTests
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ProductManager.h"
#import "Product.h"

@interface ProductManagerTests : XCTestCase

- (BOOL)saveToLocal;

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
  DLogMethod

  // iCloud OFF
  id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
  OCMStub([userDefaultsMock integerForKey:@"sync.icloud"]).andReturn(0);

  // this will fail  :'(
  // id managerMock = OCMClassMock([ProductManager class]);
  // OCMExpect([managerMock initWithFileURL:
  //            [OCMArg isKindOfClass:[NSURL class]]]);

  ProductManager *manager = [[ProductManager alloc] init];

  // OCMVerifyAll(managerMock);

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
  DLogMethod

  ProductManager *manager = [[ProductManager alloc] init];
  XCTAssertFalse([manager addProduct:nil]);
}

- (void)testAddProduct_whenSavedAsSuccess
{
  DLogMethod

  // iCloud OFF
  id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
  OCMStub([userDefaultsMock integerForKey:@"sync.icloud"]).andReturn(0);

  ProductManager *manager = [[ProductManager alloc] init];

  // stub `saveToLocal` as success
  id managerMock = OCMPartialMock(manager);
  OCMStub([managerMock saveToLocal]).andReturn(true);

  // product has ean
  NSString *vEan = @"7680317060176";
  Product *product = [[Product alloc] initWithEan:vEan];
  XCTAssertTrue([manager addProduct:product]);

  NSMutableArray *products = [[NSMutableArray array] init];
  NSInteger *index = 0;
  XCTAssertEqual(product, [manager.products objectAtIndex:index]);

  OCMVerifyAll(managerMock);
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
