//
//  SimpleUnzip.m
//  Generika
//
//  Minimal ZIP extraction replacing SSZipArchive, using minizip via zlib.
//  Copyright (c) 2026 ywesee GmbH. All rights reserved.
//

#import "SimpleUnzip.h"
#import <zlib.h>

// Minimal ZIP local file header parsing
#define ZIP_LOCAL_HEADER_SIG 0x04034b50
#define ZIP_BUFFER_SIZE 65536

@implementation SimpleUnzip

+ (BOOL)unzipFileAtPath:(NSString *)path
          toDestination:(NSString *)destination
              overwrite:(BOOL)overwrite
               password:(NSString * _Nullable)password
                  error:(NSError **)error
{
    NSData *zipData = [NSData dataWithContentsOfFile:path];
    if (!zipData) {
        if (error) *error = [NSError errorWithDomain:@"SimpleUnzip" code:-1
                                            userInfo:@{NSLocalizedDescriptionKey: @"Cannot read zip file"}];
        return NO;
    }

    const uint8_t *bytes = (const uint8_t *)zipData.bytes;
    NSUInteger length = zipData.length;
    NSUInteger offset = 0;

    [[NSFileManager defaultManager] createDirectoryAtPath:destination
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    while (offset + 30 <= length) {
        // Read local file header signature
        uint32_t sig = *(uint32_t *)(bytes + offset);
        if (sig != ZIP_LOCAL_HEADER_SIG) break;

        uint16_t compressionMethod = *(uint16_t *)(bytes + offset + 8);
        uint32_t compressedSize = *(uint32_t *)(bytes + offset + 18);
        uint32_t uncompressedSize = *(uint32_t *)(bytes + offset + 22);
        uint16_t fileNameLen = *(uint16_t *)(bytes + offset + 26);
        uint16_t extraFieldLen = *(uint16_t *)(bytes + offset + 28);

        NSString *fileName = [[NSString alloc] initWithBytes:bytes + offset + 30
                                                      length:fileNameLen
                                                    encoding:NSUTF8StringEncoding];
        offset += 30 + fileNameLen + extraFieldLen;

        if (!fileName || [fileName hasSuffix:@"/"]) {
            // Directory entry
            if (fileName) {
                NSString *dirPath = [destination stringByAppendingPathComponent:fileName];
                [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
                                         withIntermediateDirectories:YES
                                                          attributes:nil
                                                               error:nil];
            }
            offset += compressedSize;
            continue;
        }

        NSString *fullPath = [destination stringByAppendingPathComponent:fileName];
        NSString *dirPath = [fullPath stringByDeletingLastPathComponent];
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];

        if (overwrite && [[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
        }

        if (offset + compressedSize > length) break;

        NSData *compressedData = [NSData dataWithBytesNoCopy:(void *)(bytes + offset)
                                                      length:compressedSize
                                                freeWhenDone:NO];
        offset += compressedSize;

        NSData *fileData = nil;
        if (compressionMethod == 0) {
            // Stored (no compression)
            fileData = compressedData;
        } else if (compressionMethod == 8) {
            // Deflate
            z_stream strm;
            memset(&strm, 0, sizeof(strm));
            strm.next_in = (Bytef *)compressedData.bytes;
            strm.avail_in = (uInt)compressedData.length;
            // -15 for raw deflate (no zlib/gzip header)
            if (inflateInit2(&strm, -15) != Z_OK) continue;

            NSMutableData *decompressed = [NSMutableData dataWithLength:uncompressedSize ?: compressedSize * 4];
            strm.next_out = (Bytef *)decompressed.mutableBytes;
            strm.avail_out = (uInt)decompressed.length;

            int status;
            while ((status = inflate(&strm, Z_NO_FLUSH)) == Z_OK || status == Z_BUF_ERROR) {
                if (strm.avail_out == 0) {
                    NSUInteger oldLen = decompressed.length;
                    decompressed.length = oldLen * 2;
                    strm.next_out = (Bytef *)decompressed.mutableBytes + oldLen;
                    strm.avail_out = (uInt)(decompressed.length - oldLen);
                } else break;
            }
            decompressed.length = strm.total_out;
            inflateEnd(&strm);
            fileData = decompressed;
        }

        if (fileData) {
            [fileData writeToFile:fullPath atomically:YES];
        }
    }

    return YES;
}

@end
