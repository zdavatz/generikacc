//
//  AmikoDBRow.m
//  Generika
//
//  Created by b123400 on 2025/10/20.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "AmikoDBRow.h"

@implementation AmikoDBRow

- (instancetype)initWithRow:(NSArray *)row {
    if (self = [super init]) {
        self._id = row[0];
        self.title = row[1];
        self.auth = row[2];
        self.atc = row[3];
        self.substances = row[4];
        self.regnrs = row[5];
        self.atc_class = row[6];
        self.tindex_str = row[7];
        self.application_str = row[8];
        self.indications_str = row[9];
        self.customer_id = row[10];
        self.pack_info_str = row[11];
        self.add_info_str = row[12];
        self.ids_str = row[13];
        self.titles_str = row[14];
        self.content = row[15];
        self.style_str = row[16];
        self.packages = row[17];
    }
    return self;
}

- (NSArray<AmikoDBPackage*>*)parsedPackages {
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *str in [self.packages componentsSeparatedByString:@"\n"]) {
        [result addObject:[[AmikoDBPackage alloc] initWithPackageString:str parent:self]];
    }
    return result;
}

- (NSArray<NSString *> *)chapterIds {
    return [self.ids_str componentsSeparatedByString:@","];
}

- (NSArray<NSString *> *)chapterTitles {
    return [self.titles_str componentsSeparatedByString:@";"];
}

@end
