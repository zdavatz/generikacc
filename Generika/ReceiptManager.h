//
//  ReceiptManager.h
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//


@class Receipt;

@interface ReceiptManager : UIDocument

@property (nonatomic, strong, readonly) NSMutableArray *receipts;

+ (ReceiptManager *)sharedManager;

- (BOOL)addReceipt:(Receipt *)receipt;
- (BOOL)insertReceipt:(Receipt *)receipt atIndex:(unsigned int)index;
- (BOOL)removeReceiptAtIndex:(unsigned int)index;
- (BOOL)moveReceiptAtIndex:(unsigned int)fromIndex
                   toIndex:(unsigned int)toIndex;
- (NSString *)storeAmkData:(NSData *)amkData
                    ofFile:(NSString *)fileName
                        to:(NSString *)destination;
- (Receipt *)receiptAtIndex:(unsigned int)index;

- (id)importReceiptFromURL:(NSURL *)url;
- (id)importReceiptFromAMKDict:(NSDictionary *)receiptData fileName:(NSString *)fileName;

- (BOOL)save;
- (void)load;

@end
