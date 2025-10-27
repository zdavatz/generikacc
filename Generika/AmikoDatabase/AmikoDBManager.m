//
//  DatabaseManager.m
//  Generika
//
//  Created by b123400 on 2025/10/18.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "AmikoDBManager.h"
#import <sqlite3.h>
#define AMIKODB_COLUMNS @"_id, title, auth, atc, substances, regnrs, atc_class, tindex_str, application_str, indications_str, customer_id, pack_info_str, add_info_str, ids_str, titles_str, content, style_str, packages"

@interface AmikoDBManager () {
    sqlite3 *sqliteDB;
}

@end

@implementation AmikoDBManager

static AmikoDBManager *_sharedInstance = nil;

+ (AmikoDBManager *)shared
{
  if (!_sharedInstance) {
    _sharedInstance = [[AmikoDBManager alloc] init];
  }
  return _sharedInstance;
}

- (BOOL)open {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"amiko_db_full_idx_pinfo_de" ofType:@"db"];
    int rc = sqlite3_open_v2([path UTF8String], &sqliteDB, SQLITE_OPEN_READONLY, NULL);
    if (rc != SQLITE_OK) {
        NSLog(@"%s Unable to open database! %d", __FUNCTION__, rc);
        return NO;
    }
    return YES;
}

- (NSArray<AmikoDBRow*>*)findWithGtin:(NSString *)gtin {
    if (!sqliteDB && ![self open]) {
        return nil;
    }
    if ([gtin length] != 13) {
        return nil;
    }
    NSString *regnr = [gtin substringWithRange:NSMakeRange(4, 5)];
    return [self findWithRegnr:regnr];
}

- (NSArray<AmikoDBRow*>*)excuteSQL:(sqlite3_stmt *)compiledStatement {
    NSMutableArray *result = [NSMutableArray array];
    while (sqlite3_step(compiledStatement) == SQLITE_ROW) {
        NSMutableArray *row = [NSMutableArray array];
        for (int i=0; i<sqlite3_column_count(compiledStatement); i++) {
            int colType = sqlite3_column_type(compiledStatement, i);
            id value;
            if (colType == SQLITE_TEXT) {
                const char *col = (const char *)sqlite3_column_text(compiledStatement, i);
                value = [[NSString alloc] initWithUTF8String:col];
            }
            else if (colType == SQLITE_INTEGER) {
                int col = sqlite3_column_int(compiledStatement, i);
                value = [NSNumber numberWithInt:col];
            }
            else if (colType == SQLITE_FLOAT) {
                double col = sqlite3_column_double(compiledStatement, i);
                value = [NSNumber numberWithDouble:col];
            }
            else if (colType == SQLITE_NULL) {
                value = [NSNull null];
            }
            else {
                NSLog(@"%s Unknown data type.", __FUNCTION__);
            }

            // Add value to row
            [row addObject:value];
            value = nil;
        }
        
        AmikoDBRow *rowObj = [[AmikoDBRow alloc] initWithRow:row];
        // Add row to array
        [result addObject:rowObj];
    }
    return result;
}

- (NSArray<AmikoDBRow*>*)findWithRegnr:(NSString *)regnr {
    if (!sqliteDB && ![self open]) {
        return nil;
    }
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM amikodb WHERE regnrs LIKE ?", AMIKODB_COLUMNS];
    sqlite3_stmt *compiledStatement = nil;
    int rc = sqlite3_prepare_v2(sqliteDB, [sql UTF8String], -1, &compiledStatement, nil);
    if (rc != SQLITE_OK) {
        NSLog(@"%s Error when preparing query! %d", __FUNCTION__, rc);
        return nil;
    }
    rc = sqlite3_bind_text(compiledStatement, 1, [[NSString stringWithFormat:@"%%%@%%", regnr] UTF8String], -1, NULL);
    if (rc != SQLITE_OK) {
        NSLog(@"%s Error when binding query! %d", __FUNCTION__, rc);
        return nil;
    }
    NSArray<AmikoDBRow*> *result = [self excuteSQL:compiledStatement];
    // Reset statement (not necessary)
    sqlite3_reset(compiledStatement);
    // Release compiled statement from memory
    sqlite3_finalize(compiledStatement);
    return result;
}

- (NSArray<AmikoDBRow*>*)findWithATC:(NSString *)atc {
    if (!sqliteDB && ![self open]) {
        return nil;
    }
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM amikodb WHERE atc = ?", AMIKODB_COLUMNS];
    sqlite3_stmt *compiledStatement = nil;
    int rc = sqlite3_prepare_v2(sqliteDB, [sql UTF8String], -1, &compiledStatement, nil);
    if (rc != SQLITE_OK) {
        NSLog(@"%s Error when preparing query! %d", __FUNCTION__, rc);
        return nil;
    }
    rc = sqlite3_bind_text(compiledStatement, 1, [atc UTF8String], -1, NULL);
    if (rc != SQLITE_OK) {
        NSLog(@"%s Error when binding query! %d", __FUNCTION__, rc);
        return nil;
    }
    NSMutableArray *result = [self excuteSQL:compiledStatement];
    // Reset statement (not necessary)
    sqlite3_reset(compiledStatement);
    // Release compiled statement from memory
    sqlite3_finalize(compiledStatement);
    return result;
}

@end
