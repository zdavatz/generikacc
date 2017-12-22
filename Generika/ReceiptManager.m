//
//  ReceiptManager.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "ReceiptManager.h"
#import "Receipt.h"


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
  if (error) { return false; }
  time_t timestamp = (time_t)[[NSDate date] timeIntervalSince1970];

  // create file `RZ_timestamp.amk`
  NSString *amkFile = [NSString stringWithFormat:
    @"%@_%d.amk", @"RZ", (int)timestamp];
  NSString *amkFilePath = [path stringByAppendingPathComponent:amkFile];
  DLog(@".amk file path -> %@", amkFilePath);
  BOOL amkSaved = [amkData writeToFile:amkFilePath atomically:YES];

  // create signature `RZ_signature.png`
  BOOL pngSaved = true;
  error = nil;
  NSDictionary *json = [NSJSONSerialization
    JSONObjectWithData:amkData
               options:NSJSONReadingMutableContainers
                 error:&error];
  // signature key is required
  NSData *sigData;
  if (error != nil) {
    DLog(@"%@", error);
    return nil;
  } else {
    NSDictionary *operator = [json valueForKey:@"operator"];
    if (operator != nil) {
      NSString *signature = [operator valueForKey:@"signature"];
      NSData *sigData = [NSKeyedArchiver archivedDataWithRootObject:signature];
    }
  }
  
  // if amk data has signature (image as png)
  if (sigData != nil) {
    NSString *pngFile = [NSString stringWithFormat:
      @"%@_%d.png", @"RZ", (int)timestamp];
    NSString *pngFilePath = [path stringByAppendingPathComponent:pngFile];
    DLog(@".png file path -> %@", pngFilePath);
    pngSaved = [sigData writeToFile:pngFilePath atomically:YES];
  }

  if (amkSaved && pngSaved) {
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


#pragma mark - Saving and Loading methods

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
  DLogMethod;
  NSMutableArray *receiptDicts = [[NSMutableArray alloc] init];
  for (Receipt *receipt in self.receipts) {
    NSDictionary *receiptDict = [receipt
      dictionaryWithValuesForKeys:[receipt receiptKeys]];
    [receiptDicts addObject:receiptDict];
  }
  NSString *filePath = [self localFilePath];
  [receiptDicts writeToFile:filePath atomically:YES];
  NSArray *saved = [[NSArray alloc] initWithContentsOfFile:filePath];
  DLog(@"%@", saved);
  if ([saved count] > 0) {
    return YES;
  } else {
    return NO;
  }
}

- (void)loadFromLocal
{
  DLogMethod;
  NSString *filePath = [self localFilePath];
  NSFileManager *fileManager = [NSFileManager defaultManager];

  DLog(@"%@", filePath);

  if ([fileManager fileExistsAtPath:filePath]) {
    [self.receipts removeAllObjects];
    NSArray *receiptDicts = [[NSArray alloc] initWithContentsOfFile:filePath];
    for (NSDictionary *receiptDict in receiptDicts) {
      Receipt *receipt = [[Receipt alloc] init];
      [receipt setValuesForKeysWithDictionary:receiptDict];
      [self.receipts addObject:receipt];
    }
  } else {
    BOOL created = [fileManager createFileAtPath:filePath
                                        contents:nil
                                      attributes:nil];
    if (created) {
      [self.receipts removeAllObjects];
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
  DLogMethod;
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
  DLogMethod;
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
