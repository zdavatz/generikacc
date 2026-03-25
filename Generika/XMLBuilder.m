//
//  XMLBuilder.m
//  Generika
//
//  Lightweight XML builder replacing KissXML/DDXML for iOS.
//  Copyright (c) 2026 ywesee GmbH. All rights reserved.
//

#import "XMLBuilder.h"

static NSString *xmlEscape(NSString *s) {
    if (!s) return @"";
    s = [s stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    s = [s stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    s = [s stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    s = [s stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    s = [s stringByReplacingOccurrencesOfString:@"'" withString:@"&apos;"];
    return s;
}

@implementation XMLElement

+ (instancetype)elementWithName:(NSString *)name {
    XMLElement *el = [[XMLElement alloc] init];
    el->_name = name;
    el->_children = [NSMutableArray array];
    el->_attributes = [NSMutableArray array];
    return el;
}

- (void)addAttribute:(NSDictionary *)attr {
    if (attr) [_attributes addObject:attr];
}

- (void)addChild:(XMLElement *)child {
    if (child) [_children addObject:child];
}

- (NSString *)XMLString {
    NSMutableString *xml = [NSMutableString stringWithFormat:@"<%@", _name];
    for (NSDictionary *attr in _attributes) {
        NSString *name = attr[@"name"];
        NSString *value = attr[@"value"];
        if (name && value) {
            [xml appendFormat:@" %@=\"%@\"", name, xmlEscape(value)];
        }
    }
    if (_children.count == 0) {
        [xml appendString:@"/>"];
    } else {
        [xml appendString:@">"];
        for (XMLElement *child in _children) {
            [xml appendString:[child XMLString]];
        }
        [xml appendFormat:@"</%@>", _name];
    }
    return xml;
}

- (NSData *)XMLData {
    return [[self XMLString] dataUsingEncoding:NSUTF8StringEncoding];
}

@end

@implementation XMLNode

+ (NSDictionary *)attributeWithName:(NSString *)name stringValue:(NSString *)value {
    return @{@"name": name ?: @"", @"value": value ?: @""};
}

@end

@implementation XMLDocument

- (instancetype)initWithXMLString:(NSString *)string options:(NSUInteger)options error:(NSError **)error {
    self = [super init];
    if (self) {
        // Extract root element name from simple XML like "<prescription></prescription>"
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<(\\w+)" options:0 error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
        NSString *rootName = @"root";
        if (match && match.numberOfRanges >= 2) {
            rootName = [string substringWithRange:[match rangeAtIndex:1]];
        }
        _rootElement = [XMLElement elementWithName:rootName];
    }
    return self;
}

- (NSString *)XMLString {
    return [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>%@", [_rootElement XMLString]];
}

- (NSData *)XMLData {
    return [[self XMLString] dataUsingEncoding:NSUTF8StringEncoding];
}

@end
