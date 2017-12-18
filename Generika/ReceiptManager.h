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
- (NSString *)storeAmkFile:(NSString *)amkFile
                        to:(NSString *)destination;
- (Receipt *)receiptAtIndex:(unsigned int)index;

- (BOOL)save;
- (void)load;

@end
