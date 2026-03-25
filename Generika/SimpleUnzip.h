//
//  SimpleUnzip.h
//  Generika
//
//  Minimal ZIP extraction replacing SSZipArchive.
//  Copyright (c) 2026 ywesee GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SimpleUnzip : NSObject

+ (BOOL)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
              overwrite:(BOOL)overwrite
               password:(NSString * _Nullable)password
                  error:(NSError **)error;

@end
