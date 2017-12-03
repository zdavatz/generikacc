//
//  ProductTests.m
//  ProductTests
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Product.h"

@interface ProductTests : XCTestCase

@end

@implementation ProductTests

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
  Product *product = [[Product alloc] init];
  XCTAssertNotNil(product);
}

- (void)testInitWithEan
{
  NSString *eancode = @"1234567890123";
  Product *product = [[Product alloc] initWithEan:eancode];

  NSString *ean = product.ean;

  XCTAssertEqualObjects(ean, eancode);
}

@end
