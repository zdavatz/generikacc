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
  DLogMethod

  Product *product = [[Product alloc] init];
  XCTAssertNotNil(product);
}

- (void)testDealloc
{
  // pass
}

- (void)testInitWithEan
{
  DLogMethod

  NSString *vEan = @"7680317060176";

  Product *product = [[Product alloc] initWithEan:vEan];

  NSString *ean = product.ean;
  XCTAssertEqualObjects(ean, vEan);
}

- (void)testInitWithCoder_withoutExpiresAt
{
  DLogMethod

  NSString *vEan = @"7680317060176";

  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc]
                              initForWritingWithMutableData:data];
  [encoder encodeObject:vEan forKey:@"ean"];
  [encoder finishEncoding];

  NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc]
                                initForReadingWithData:data];
  Product *product = [[Product alloc] initWithCoder:decoder];

  DLog(@"product.ean -> %@", [decoder decodeObjectForKey:@"ean"]);
  DLog(@"product.expiresAt -> %@", [decoder decodeObjectForKey:@"expiresAt"]);

  NSString *ean = product.ean;
  XCTAssertEqualObjects(ean, vEan);

  NSString *expiresAt = product.expiresAt;
  XCTAssertEqualObjects(expiresAt, @"");
}

- (void)testInitWithCoder_withExpiresAt
{
  DLogMethod

  NSString *vEan = @"7680317060176";
  NSString *vExpiresAt = @"29.02.2017";

  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc]
                              initForWritingWithMutableData:data];
  [encoder encodeObject:vEan forKey:@"ean"];
  [encoder encodeObject:vExpiresAt forKey:@"expiresAt"];
  [encoder finishEncoding];

  NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc]
                                initForReadingWithData:data];
  Product *product = [[Product alloc] initWithCoder:decoder];

  DLog(@"product.ean -> %@", [decoder decodeObjectForKey:@"ean"]);
  DLog(@"product.expiresAt -> %@", [decoder decodeObjectForKey:@"expiresAt"]);

  NSString *ean = product.ean;
  XCTAssertEqualObjects(ean, vEan);

  NSString *expiresAt = product.expiresAt;
  XCTAssertEqualObjects(expiresAt, vExpiresAt);
}

- (void)testEncodeWithCoder_withoutExpiresAt
{
  // pass
}

- (void)testEncodeWithCoder_withExpiresAt
{
  // pass
}

- (void)testReg_reg
{
  DLogMethod

  NSString *vReg = @"31706";

  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc]
                              initForWritingWithMutableData:data];
  [encoder encodeObject:vReg forKey:@"reg"];
  [encoder finishEncoding];

  NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc]
                                initForReadingWithData:data];
  Product *product = [[Product alloc] initWithCoder:decoder];

  NSString *reg = product.reg;
  XCTAssertEqualObjects(reg, vReg);

  NSString *ean = product.ean;
  XCTAssertEqualObjects(ean, @"");
}

- (void)testReg_extractingFromEan
{
  DLogMethod

  NSString *vEan = @"7680317060176";

  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc]
                              initForWritingWithMutableData:data];
  [encoder encodeObject:vEan forKey:@"ean"];
  [encoder finishEncoding];

  NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc]
                                initForReadingWithData:data];
  Product *product = [[Product alloc] initWithCoder:decoder];

  NSString *reg = product.reg;
  XCTAssertEqualObjects(reg, @"31706");

  NSString *ean = product.ean;
  XCTAssertEqualObjects(ean, vEan);
}

- (void)testReg_noProperties
{
  DLogMethod

  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc]
                              initForWritingWithMutableData:data];
  [encoder finishEncoding];

  NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc]
                                initForReadingWithData:data];
  Product *product = [[Product alloc] initWithCoder:decoder];

  NSString *reg = product.reg;
  XCTAssertEqualObjects(reg, @"");

  NSString *ean = product.ean;
  XCTAssertEqualObjects(ean, @"");
}

- (void)testSeq_seq
{
  DLogMethod

  NSString *vSeq = @"017";

  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc]
                              initForWritingWithMutableData:data];
  [encoder encodeObject:vSeq forKey:@"seq"];
  [encoder finishEncoding];

  NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc]
                                initForReadingWithData:data];
  Product *product = [[Product alloc] initWithCoder:decoder];

  NSString *seq = product.seq;
  XCTAssertEqualObjects(seq, vSeq);

  NSString *ean = product.ean;
  XCTAssertEqualObjects(ean, @"");
}

- (void)testSeq_extractingFromEan
{
  DLogMethod

  NSString *vEan = @"7680317060176";

  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc]
                              initForWritingWithMutableData:data];
  [encoder encodeObject:vEan forKey:@"ean"];
  [encoder finishEncoding];

  NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc]
                                initForReadingWithData:data];
  Product *product = [[Product alloc] initWithCoder:decoder];

  NSString *seq = product.seq;
  XCTAssertEqualObjects(seq, @"017");

  NSString *ean = product.ean;
  XCTAssertEqualObjects(ean, vEan);
}

- (void)testSeq_noProperties
{
  DLogMethod

  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc]
                              initForWritingWithMutableData:data];
  [encoder finishEncoding];

  NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc]
                                initForReadingWithData:data];
  Product *product = [[Product alloc] initWithCoder:decoder];

  NSString *seq = product.seq;
  XCTAssertEqualObjects(seq, @"");

  NSString *ean = product.ean;
  XCTAssertEqualObjects(ean, @"");
}

- (void)testDetectNumberFromEanWithRegexpString_regexpString
{
  // pass
}

- (void)testDictConversion_usingProductKeys_via_scan
{
  // scanned product
  NSString *vEan = @"7680317060176";
  NSString *vPack = @"6";
  NSString *vName = @"Inderal";

  NSString *vSize = @"1";
  NSString *vDeduction = @"";
  NSString *vPrice = @"12.34";
  NSString *vCategory = @"A";

  NSString *vBarcode = @"";
  NSString *vDatetime = @"02.02.2017";
  NSString *vExpiresAt = @"29.02.2017";

  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc]
                              initForWritingWithMutableData:data];
  [encoder encodeObject:vEan forKey:@"ean"];
  [encoder encodeObject:vPack forKey:@"pack"];
  [encoder encodeObject:vName forKey:@"name"];

  [encoder encodeObject:vSize forKey:@"size"];
  [encoder encodeObject:vDeduction forKey:@"deduction"];
  [encoder encodeObject:vPrice forKey:@"price"];
  [encoder encodeObject:vCategory forKey:@"category"];

  [encoder encodeObject:vBarcode forKey:@"barcode"];
  [encoder encodeObject:vDatetime forKey:@"datetime"];
  [encoder encodeObject:vExpiresAt forKey:@"expiresAt"];
  [encoder finishEncoding];

  NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc]
                                initForReadingWithData:data];
  Product *product = [[Product alloc] initWithCoder:decoder];

  NSDictionary *productDict = [product
    dictionaryWithValuesForKeys:[product productKeys]];
  NSDictionary *expected = @{
    @"atc": @"",
    @"owner": @"",
    @"title": @"",
    @"comment": @"",

    @"reg": @"31706",
    @"ean": vEan,
    @"pack": vPack,
    @"name": vName,

    // scanned properties
    @"seq": @"017",
    @"size": vSize,
    @"deduction": vDeduction,
    @"price": vPrice,
    @"category": vCategory,

    @"barcode": vBarcode,
    @"expiresAt": vExpiresAt,

    @"datetime": vDatetime
  };
  XCTAssertEqualObjects(productDict, expected);
}

- (void)testDictConversion_usingProductKeys_via_import
{
  // imported product
  NSString *vEan = @"7680317060176";
  NSString *vReg = @"31706";
  NSString *vPack = @"ABCD;EFG6";
  NSString *vName = @"Inderal";

  NSString *vAtc = @"1234567890";
  NSString *vOwner = @"Firm";
  NSString *vTitle = @"Prescription Title";
  NSString *vComment = @"This is prescription";

  NSString *vDatetime = @"02.02.2017";

  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc]
                              initForWritingWithMutableData:data];

  [encoder encodeObject:vEan forKey:@"ean"];
  [encoder encodeObject:vReg forKey:@"reg"];
  [encoder encodeObject:vPack forKey:@"pack"];
  [encoder encodeObject:vName forKey:@"name"];

  [encoder encodeObject:vAtc forKey:@"atc"];
  [encoder encodeObject:vOwner forKey:@"owner"];
  [encoder encodeObject:vTitle forKey:@"title"];
  [encoder encodeObject:vComment forKey:@"comment"];

  [encoder encodeObject:vDatetime forKey:@"datetime"];
  [encoder finishEncoding];

  NSKeyedUnarchiver *decoder = [[NSKeyedUnarchiver alloc]
                                initForReadingWithData:data];
  Product *product = [[Product alloc] initWithCoder:decoder];

  NSDictionary *productDict = [product
    dictionaryWithValuesForKeys:[product productKeys]];
  NSDictionary *expected = @{
    @"atc": vAtc,
    @"owner": vOwner,
    @"title": vTitle,
    @"comment": vComment,

    @"reg": vReg,
    @"ean": vEan,
    @"pack": vPack,
    @"name": vName,

    // scanned properties
    @"seq": @"017",
    @"size": @"",
    @"deduction": @"",
    @"price": @"",
    @"category": @"",

    @"barcode": @"",
    @"expiresAt": @"",

    @"datetime": vDatetime
  };
  XCTAssertEqualObjects(productDict, expected);
}

@end
