//
//  XMLBuilder.h
//  Generika
//
//  Lightweight XML builder replacing KissXML/DDXML for iOS.
//  Copyright (c) 2026 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLElement : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSMutableArray<XMLElement *> *children;
@property (nonatomic, strong, readonly) NSMutableArray<NSDictionary *> *attributes;

+ (instancetype)elementWithName:(NSString *)name;
- (void)addAttribute:(NSDictionary *)attr;
- (void)addChild:(XMLElement *)child;
- (NSString *)XMLString;
- (NSData *)XMLData;

@end

@interface XMLNode : NSObject

+ (NSDictionary *)attributeWithName:(NSString *)name stringValue:(NSString *)value;

@end

@interface XMLDocument : NSObject

@property (nonatomic, strong, readonly) XMLElement *rootElement;

- (instancetype)initWithXMLString:(NSString *)string options:(NSUInteger)options error:(NSError **)error;
- (NSString *)XMLString;
- (NSData *)XMLData;

@end
