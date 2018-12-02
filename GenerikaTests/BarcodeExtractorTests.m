//
//  BarcodeExtractorTests.m
//  GenerikaTests
//
//  Created by b123400 on 2018/12/02.
//  Copyright © 2018 ywesee GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BarcodeExtractor.h"

@interface BarcodeExtractorTests : XCTestCase

@end

@implementation BarcodeExtractorTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testBarcodeExtractor {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    DataMatrixResult *result = [[[BarcodeExtractor alloc] init] extractGS1DataFrom:@"01034531200000111719112510ABCD1234"];
    XCTAssertEqualObjects(result.gtin, @"3453120000011");
    XCTAssertEqualObjects(result.expiryDate, @"11.2019");
    XCTAssertEqualObjects(result.batchOrLotNumber, @"ABCD1234");
}

@end
