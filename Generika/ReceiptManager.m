//
//  ReceiptManager.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "ReceiptManager.h"
#import "Receipt.h"
#import "Product.h"


@interface ReceiptManager ()

@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) NSMetadataQuery *query;
@property (nonatomic, strong, readwrite) NSFileWrapper *fileWrapper;

- (void)loadRemoteFile:(NSString *)filePath;
- (NSString *)receiptsPath;

@end

@implementation ReceiptManager

static ReceiptManager *_sharedInstance = nil;

+ (ReceiptManager *)sharedManager
{
  if (!_sharedInstance) {
    _sharedInstance = [[ReceiptManager alloc] init];
  }
  return _sharedInstance;
}

- (id)init
{
  NSURL *pathURL = [self receiptsPathURL];
  self = [super initWithFileURL:pathURL];
  if (!self) {
    return nil;
  }
  _receipts = [[NSMutableArray array] init];
  _userDefaults = [NSUserDefaults standardUserDefaults];
  return self;
}

- (void)dealloc
{
  _receipts = nil;
  _userDefaults = nil;
}


#pragma mark - Interface Methods

- (BOOL)addReceipt:(Receipt *)receipt
{
  if (!receipt) {
    return false;
  }
  [self.receipts addObject:receipt];
  if ([self iCloudOn]) {
    [self updateChangeCount:UIDocumentChangeDone];
  }
  return [self save];
}

- (BOOL)insertReceipt:(Receipt *)receipt atIndex:(unsigned int)index
{
  if (!receipt) {
    return false;
  }
  if (index > [self.receipts count]) {
    return false;
  }
  [self.receipts insertObject:receipt atIndex:index];
  if ([self iCloudOn]) {
    [self updateChangeCount:UIDocumentChangeDone];
  }
  return [self save];
}

- (BOOL)removeReceiptAtIndex:(unsigned int)index
{
  if (index > ([self.receipts count] - 1)) {
    return false;
  }
  Receipt *receipt = [self receiptAtIndex:index];
  if (receipt) {
    [self.receipts removeObjectAtIndex:index];
    if ([self iCloudOn]) {
      [self updateChangeCount:UIDocumentChangeDone];
    }
  }
  return [self save];
}

- (BOOL)moveReceiptAtIndex:(unsigned int)fromIndex
                   toIndex:(unsigned int)toIndex
{
  if (fromIndex > ([self.receipts count] - 1)) {
    return false;
  }
  if (toIndex > [self.receipts count]) {
    return false;
  }
  Receipt *receipt;
  receipt = [self.receipts objectAtIndex:fromIndex];
  [self.receipts removeObject:receipt];
  [self.receipts insertObject:receipt atIndex:toIndex];
  if ([self iCloudOn]) {
    [self updateChangeCount:UIDocumentChangeDone];
  }
  return [self save];
}

- (Receipt *)receiptAtIndex:(unsigned int)index
{
  if (index > ([self.receipts count] - 1)) {
    return nil;
  }
  return [self.receipts objectAtIndex:index];
}

- (id)importReceiptFromURL:(NSURL *)url{
    // import .amk receipt file.
    NSString *fileName = [[url absoluteString] lastPathComponent];

    NSData *encryptedData = [NSData dataWithContentsOfURL:url];
    NSData *decryptedData = [[NSData alloc]
      initWithBase64EncodedData:encryptedData
                        options:NSDataBase64DecodingIgnoreUnknownCharacters];

    NSError *error;
    NSDictionary *receiptData = [NSJSONSerialization
      JSONObjectWithData:decryptedData
                 options:NSJSONReadingAllowFragments
                   error:&error];
    if (error) {
      return nil;
    }
    return [self importReceiptFromAMKDict:receiptData fileName:fileName];
}
- (id)importReceiptFromAMKDict:(NSDictionary *)receiptData fileName:(NSString *)fileName
{
    // hashedKey (prescription_hash) is required
    NSString *hash;
    hash = [receiptData valueForKey:@"prescription_hash"];
    if (hash == nil ||
        [hash isEqual:[NSNull null]] ||
        [hash isEqualToString:@""]) {
        return nil;
    }
    NSPredicate *predicate = [NSPredicate
                              predicateWithFormat:@"hashedKey == %@", hash];
    NSArray *matched = [self.receipts filteredArrayUsingPredicate:predicate];
    if ([matched count] > 0) {
        // already imported
        return [NSNull null];
    }
    
    Operator *operator;
    Patient *patient;
    NSMutableArray *medications = [[NSMutableArray alloc] init];
    
    // operator
    NSDictionary *operatorDict = [
        receiptData valueForKey:@"operator"] ?: [NSNull null];
    if (operatorDict) {
        operator = [Operator importFromDict:operatorDict];
    }
    // patient
    NSDictionary *patientDict = [
        receiptData valueForKey:@"patient"] ?: [NSNull null];
    if (patientDict) {
        patient = [Patient importFromDict:patientDict];
    }
    // medications (products)
    NSArray *medicationArray = [
        receiptData valueForKey:@"medications"] ?: [NSNull null];
    if (medicationArray) {
        for (NSDictionary *medicationDict in medicationArray) {
            [medications addObject:[Product importFromDict:medicationDict]];
        }
    }
    if (operator == nil || patient == nil || medications == nil) {
        return nil;
    }
    Receipt *receipt;
    
    ReceiptManager *manager = [[self class] sharedManager];
    NSString *amkfile = [manager storeAmkData:[[NSJSONSerialization dataWithJSONObject:receiptData options:0 error:nil] base64EncodedDataWithOptions:0]
                                       ofFile:fileName
                                           to:@"both"];
    if (amkfile == nil) {
        return nil;
    }
    NSDictionary *receiptDict = @{
        @"prescription_hash" : [
            receiptData valueForKey:@"prescription_hash"] ?: [NSNull null],
        @"place_date"        : [
            receiptData valueForKey:@"place_date"] ?: [NSNull null],
        @"operator"          : operator,
        @"patient"           : patient,
        @"medications"       : medications
    };
    receipt = [Receipt importFromDict:receiptDict];
    // additional values
    [receipt setValue:amkfile forKey:@"amkfile"];
    [receipt setValue:fileName forKey:@"filename"];
    NSData *now = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm:ss dd.MM.YYYY"];
    [receipt setValue:[dateFormat stringFromDate:now] forKey:@"datetime"];
    
    return receipt;
}

#pragma mark - Saving and Loading methods

- (NSString *)storeAmkData:(NSData *)amkData
                    ofFile:(NSString *)fileName
                        to:(NSString *)destination
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];

  NSString *path = [documentsDirectory
    stringByAppendingPathComponent:@"amkfiles"];
  NSError *error;
  [fileManager createDirectoryAtPath:path
         withIntermediateDirectories:YES
                          attributes:nil
                               error:&error];
  if (error) { return nil; }
  // create file as new name `RZ_timestamp.amk`
  time_t timestamp = (time_t)[[NSDate date] timeIntervalSince1970];
  NSString *amkFile = [NSString stringWithFormat:
    @"%@_%d.amk", @"RZ", (int)timestamp];
  NSString *amkFilePath = [path stringByAppendingPathComponent:amkFile];
  BOOL amkSaved = [amkData writeToFile:amkFilePath atomically:YES];
  if (amkSaved) {
    if ([destination isEqualToString:@"both"] && [self iCloudOn]) {
      dispatch_async(
          dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
          ^(void) {
        [self copyFileInPath:amkFilePath toiCloudDirectory:@"amkfiles"];
      });
    }
    return amkFilePath;
  } else {
    return nil;
  }
}

- (BOOL)save
{
  if ([self saveToLocal]) {
    if ([self iCloudOn]) {
      NSURL *receiptsPathURL = [self receiptsPathURL];
      [self saveToURL:receiptsPathURL
     forSaveOperation:UIDocumentSaveForOverwriting
    completionHandler:^(BOOL success) {
        [self closeWithCompletionHandler:NULL];
      }];
    }
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"receiptsDidLoaded"
                    object:self];
    return true;
  } else {
    return false;
  }
}

- (void)load
{
  if ([self iCloudOn]) {
    [self loadRemoteFile:@"receipts.plist"];
  }
  [self loadFromLocal];
  if ([self iCloudOn]) {
    [self updateChangeCount:UIDocumentChangeDone];
  }
}

- (BOOL)iCloudOn
{
  if (!self.userDefaults) { // at init
    return NO;
  }
  NSInteger selected = [self.userDefaults integerForKey:@"sync.icloud"];
  NSNumber *value = [NSNumber numberWithInt:(int)selected];
  return [value boolValue];
}

- (NSString *)iCloudFilePath
{
  NSURL *ubiq = [[NSFileManager defaultManager]
    URLForUbiquityContainerIdentifier:nil];
  if (ubiq) {
    NSURL *plist = [[ubiq
      URLByAppendingPathComponent:@"Documents"
                      isDirectory:YES]
      URLByAppendingPathComponent:@"receipts.plist"];
    return [plist absoluteString];
  } else {
    return nil;
  }
}

- (NSString *)localFilePath
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES);
  if ([paths count] < 1) {
    return nil;
  }
  NSString *path = [paths objectAtIndex:0];
  NSString *filePath = [path stringByAppendingPathComponent:@"receipts.plist"];
  return filePath;
}

- (NSURL *)receiptsPathURL
{
  NSString *filePath = nil;
  NSURL *pathURL = nil;
  if ([self iCloudOn]) {
    filePath = [self iCloudFilePath];
    if (filePath) {
      pathURL = [[NSURL alloc] initWithString:filePath];
    }
  }
  if (!pathURL) {
    filePath = [self localFilePath];
    pathURL = [NSURL fileURLWithPath:filePath];
  }
  return pathURL;
}

- (NSString *)receiptsPath
{
  NSURL *ubiq = [[NSFileManager defaultManager]
    URLForUbiquityContainerIdentifier:nil];
  if ([self iCloudOn] && ubiq) {
    return [self iCloudFilePath];
  } else {
    return [self localFilePath];
  }
}

- (BOOL)saveToLocal
{
  NSMutableData *data = [NSMutableData data];
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]
    initForWritingWithMutableData:data];
  [archiver encodeObject:self.receipts forKey:@"data"];
  [archiver finishEncoding];

  NSString *filePath = [self localFilePath];
  return [data writeToFile:filePath atomically:YES];
}

- (void)loadFromLocal
{
  NSString *filePath = [self localFilePath];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:filePath]) {
    BOOL created = [fileManager createFileAtPath:filePath
                                        contents:nil
                                      attributes:nil];
    if (created) {
      [self.receipts removeAllObjects];
    }
  }
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  NSKeyedUnarchiver *archiver = [
    [NSKeyedUnarchiver alloc] initForReadingWithData:data];
  NSArray *receipts = [archiver decodeObjectForKey:@"data"];
  [archiver finishDecoding];

  if (receipts) {
    [self.receipts removeAllObjects];
    for (Receipt *receipt in receipts) {
      [self.receipts addObject:receipt];
    }
  }
}

- (BOOL)copyFileInPath:(NSString *)filePath
     toiCloudDirectory:(NSString *)directory
{
  BOOL saved = false;
  NSURL *ubiq = [[NSFileManager defaultManager]
    URLForUbiquityContainerIdentifier:nil];
  if (ubiq) {
    NSURL *dir = [[ubiq
      URLByAppendingPathComponent:@"Documents"
                      isDirectory:YES]
      URLByAppendingPathComponent:directory isDirectory:YES];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *creationError;
    [fileManager createDirectoryAtURL:dir
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&creationError];
    if (creationError) { return false; }
    NSError *copyError = nil;
    NSString *fileName = [filePath lastPathComponent];
    saved = [fileManager
      copyItemAtURL:[NSURL fileURLWithPath:filePath]
              toURL:[dir URLByAppendingPathComponent:fileName]
              error:&copyError];
    if (copyError != nil) {
      return false;
    }
  }
  return saved;
}

- (BOOL)removeFile:(NSString *)fileName
  fromiCloudDirectory:(NSString *)directory
{
  BOOL saved = false;
  NSURL *ubiq = [[NSFileManager defaultManager]
    URLForUbiquityContainerIdentifier:nil];
  if (ubiq) {
    NSURL *dir = [[ubiq
      URLByAppendingPathComponent:@"Documents"
                      isDirectory:YES]
      URLByAppendingPathComponent:directory isDirectory:YES];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    saved = [fileManager
      removeItemAtURL:[dir URLByAppendingPathComponent:fileName]
                error:&error];
  }
  return saved;
}

#pragma mark - UIDocument

- (void)loadRemoteFile:(NSString *)fileName
{
  NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
  self.query = query;
  [query setSearchScopes:[NSArray
    arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:
    @"%K == %@", NSMetadataItemFSNameKey, fileName];
  [query setPredicate:predicate];
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(queryDidFinishGathering:)
           name:NSMetadataQueryDidFinishGatheringNotification
         object:query];
  [[NSNotificationCenter defaultCenter]
   addObserver:self
      selector:@selector(queryDidFinishGathering:)
          name:NSMetadataQueryDidUpdateNotification
        object:query];
  [query startQuery];
}

- (void)loadData:(NSMetadataQuery *)query
{
  if ([query resultCount] == 1) {
    NSMetadataItem *item = [query resultAtIndex:0];
    NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
    NSError *error = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc]
      initWithFilePresenter:nil];
    if ([[url lastPathComponent] isEqualToString:@"receipts.plist"]) {
      [coordinator
        coordinateReadingItemAtURL:url
                           options:NSFileCoordinatorReadingWithoutChanges
                             error:&error
                        byAccessor:^(NSURL *readingURL) {
                          // TODO check conflict
                          NSMutableData *data = [[NSMutableData alloc]
                            initWithContentsOfURL:readingURL];
                          NSKeyedUnarchiver *archiver = [
                            [NSKeyedUnarchiver alloc]
                            initForReadingWithData:data];
                          NSArray *receipts = [archiver
                            decodeObjectForKey:@"data"];
                          [archiver finishDecoding];
                          if (receipts != nil && [receipts count] > 0) {
                            [self.receipts removeAllObjects];
                            for (Receipt *receipt in receipts) {
                              [self.receipts addObject:receipt];
                            }
                            [self saveToLocal];
                          }
      }];
    } else { // amk file
      // TODO
    }
    [[NSNotificationCenter defaultCenter]
      postNotificationName:@"receiptsDidLoaded"
                    object:self];
  }
}

- (void)queryDidFinishGathering:(NSNotification *)notification
{
  NSMetadataQuery *query = [notification object];
  [query disableUpdates];
  [query stopQuery];

  [[NSNotificationCenter defaultCenter]
    removeObserver:self
              name:NSMetadataQueryDidFinishGatheringNotification
            object:query];
  self.query = nil;
  [self loadData:query];
  [query enableUpdates];
}

- (BOOL)writeContents:(id)contents
                toURL:(NSURL *)url
     forSaveOperation:(UIDocumentSaveOperation)operation
  originalContentsURL:(NSURL *)originalContentsURL
                error:(NSError **)error
{
  if ([self iCloudOn]) {
    return [super writeContents:contents
                          toURL:url
               forSaveOperation:operation
            originalContentsURL:originalContentsURL
                          error:error];
  } else {
    return YES;
  }
}

- (BOOL)loadFromContents:(id)contents
                  ofType:(NSString *)typeName
                   error:(NSError **)error
{
  if ([contents isKindOfClass:[NSData class]]) {
     NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc]
       initForReadingWithData:contents];
     NSArray *receipts = [archiver decodeObjectForKey:@"data"];
     [archiver finishDecoding];
     if (receipts != nil && [receipts count] > 0) {
       [self.receipts removeAllObjects];
       for (Receipt *receipt in receipts) {
         [self.receipts addObject:receipt];
       }
       return [self saveToLocal];
     } else {
       return NO;
     }
  } else {
    return NO;
  }
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)error
{
  NSMutableData *data = [NSMutableData data];
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]
    initForWritingWithMutableData:data];
  [archiver encodeObject:self.receipts forKey:@"data"];
  [archiver finishEncoding];
  return data;
}

- (void)handleError:(NSError *)error
  userInteractionPermitted:(BOOL)userInteractionPermitted
{
  // pass
}

@end
