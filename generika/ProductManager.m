//
//  ProductManager.m
//  generika
//
//  Created by Yasuhiro Asaka on 09/02/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//

#import "ProductManager.h"
#import "Product.h"


@interface ProductManager ()

@property (nonatomic, strong, readwrite) NSMetadataQuery *query;
@property (nonatomic, strong, readwrite) NSFileWrapper *fileWrapper;

- (void)loadRemoteFile;
- (NSString *)productsPath;

@end

@implementation ProductManager

static ProductManager *_sharedInstance = nil;

+ (ProductManager *)sharedManager
{
  if (!_sharedInstance) {
    _sharedInstance = [[ProductManager alloc] init];
  }
  return _sharedInstance;
}

- (id)init
{
  //NSString *path = [self localFilePath];
  //NSURL *pathURL = [NSURL fileURLWithPath:path];
  NSURL *pathURL = [self productsPathURL];
  DLog(@"initial pathURL #=> %@", pathURL);
  self = [super initWithFileURL:pathURL];
  if (!self) {
    return nil;
  }
  _products = [[NSMutableArray array] init];
  return self;
}

- (void)dealloc
{
  _products = nil;
}


#pragma mark - Interface Methods

- (BOOL)addProduct:(Product *)product
{
  if (!product) {
    return false;
  }
  [self.products addObject:product];
  if ([self iCloudOn]) {
    [self updateChangeCount:UIDocumentChangeDone];
  }
  return [self save];
}

- (BOOL)insertProduct:(Product *)product atIndex:(unsigned int)index
{
  if (!product) {
    return false;
  }
  if (index > [self.products count]) {
    return false;
  }
  [self.products insertObject:product atIndex:index];
  if ([self iCloudOn]) {
    [self updateChangeCount:UIDocumentChangeDone];
  }
  return [self save];
}

- (BOOL)removeProductAtIndex:(unsigned int)index
{
  if (index > ([self.products count] - 1)) {
    return false;
  }
  Product *product = [self productAtIndex:index];
  if (product) {
    NSString *barcodePath = product.barcode;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
      [self removeFile:[barcodePath lastPathComponent] fromiCloudDirectory:@"barcodes"];
    });
  }
  [self.products removeObjectAtIndex:index];
  if ([self iCloudOn]) {
    [self updateChangeCount:UIDocumentChangeDone];
  }
  return [self save];
}

- (BOOL)moveProductAtIndex:(unsigned int)fromIndex toIndex:(unsigned int)toIndex
{
  if (fromIndex > ([self.products count] - 1)) {
    return false;
  }
  if (toIndex > [self.products count]) {
    return false;
  }
  Product *product;
  product = [self.products objectAtIndex:fromIndex];
  [self.products removeObject:product];
  [self.products insertObject:product atIndex:toIndex];
  if ([self iCloudOn]) {
    [self updateChangeCount:UIDocumentChangeDone];
  }
  return [self save];
}

- (Product *)productAtIndex:(unsigned int)index
{
  if (index > ([self.products count] - 1)) {
    return nil;
  }
  return [self.products objectAtIndex:index];
}

- (NSString *)storeBarcode:(UIImage *)barcode ofEan:(NSString *)ean
{
  // resize
  CGRect barcodeRect = CGRectMake(0.0, 0.0, 66.0, 83.0);
  UIGraphicsBeginImageContext(barcodeRect.size);
  [barcode drawInRect:barcodeRect];
  UIImage *barcodeImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *path = [documentsDirectory stringByAppendingPathComponent:@"barcodes"];
  NSError *error;
  [fileManager createDirectoryAtPath:path
         withIntermediateDirectories:YES
                          attributes:nil
                               error:&error];
  if (error) { return false; }
  time_t timestamp = (time_t)[[NSDate date] timeIntervalSince1970];
  NSString *fileName = [NSString stringWithFormat:@"%@_%d.png", ean, (int)timestamp];
  NSString *filePath = [path stringByAppendingPathComponent:fileName];
  NSData *barcodeData = UIImagePNGRepresentation(barcodeImage);
  BOOL saved = [barcodeData writeToFile:filePath atomically:YES];
  DLog(@"saved #=> %i", saved);
  if (saved) {
    if ([self iCloudOn]) {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self copyFileInPath:filePath toiCloudDirectory:@"barcodes"];
      });
    }
    return filePath;
  } else {
    return nil;
  }
}

- (BOOL)save
{
  if ([self saveToLocal]) {
    DLogMethod;
    if ([self iCloudOn]) {
      NSURL *productsPathURL = [self productsPathURL];
      DLog(@"productsPathURL #=> %@", productsPathURL);
      [self saveToURL:productsPathURL
     forSaveOperation:UIDocumentSaveForOverwriting
    completionHandler:^(BOOL success) {
        if (success) {
          DLog(@"saved !!!!!!");
          // TODO
        } else {
          DLog(@"fail !!!!");
        }
        [self closeWithCompletionHandler:NULL];
      }];
    }
    return true;
  } else {
    return false;
  }
}

- (void)load
{
  DLogMethod;
  if ([self iCloudOn]) {
    [self loadRemoteFile:@"products.plist"];
  }
  [self loadFromLocal];
  if ([self iCloudOn]) {
    [self updateChangeCount:UIDocumentChangeDone];
  }
}


#pragma mark - Saving and Loading methods

- (BOOL)iCloudOn
{
  return YES;
}

- (NSString *)iCloudFilePath
{
  NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
  if (ubiq) {
    NSURL *plist = [[ubiq URLByAppendingPathComponent:@"Documents" isDirectory:YES]
                          URLByAppendingPathComponent:@"products.plist"];
    return [plist absoluteString];
  } else {
    return nil;
  }
}

- (NSString *)localFilePath
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  if ([paths count] < 1) {
    return nil;
  }
  NSString *path = [paths objectAtIndex:0];
  NSString *filePath = [path stringByAppendingPathComponent:@"products.plist"];
  return filePath;
}

- (NSURL *)productsPathURL
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

- (NSString *)productsPath
{
  NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
  if ([self iCloudOn] && ubiq) {
    return [self iCloudFilePath];
  } else {
    return [self localFilePath];
  }
}

- (BOOL)saveToLocal
{
  DLogMethod;
  NSMutableArray *productDicts = [[NSMutableArray alloc] init];
  for (Product *product in self.products) {
    DLog(@"product #=> %@", product);
    NSDictionary *productDict = [product dictionaryWithValuesForKeys:[product productKeys]];
    [productDicts addObject:productDict];
  }
  NSString *filePath = [self localFilePath];

  [productDicts writeToFile:filePath atomically:YES];
  NSArray *saved = [[NSArray alloc] initWithContentsOfFile:filePath];
  DLog(@"saved dicts #=> %@", saved);
  return YES;
}

- (void)loadFromLocal
{
  NSString *filePath = [self localFilePath];
  DLog(@"filePath #=> %@", filePath);
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL exist = [fileManager fileExistsAtPath:filePath isDirectory:NO];
  DLog(@"exist #=> %i", exist);
  if (exist) {
    [self.products removeAllObjects];
    NSArray *productDicts = [[NSArray alloc] initWithContentsOfFile:filePath];
    for (NSDictionary *productDict in productDicts) {
      DLog(@"[local] productDict #=> %@", productDict);
      Product *product = [[Product alloc] init];
      [product setValuesForKeysWithDictionary:productDict];
      [self.products addObject:product];
    }
  }
}

- (BOOL)copyFileInPath:(NSString *)filePath toiCloudDirectory:(NSString *)directory
{
  BOOL saved = false;
  NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
  if (ubiq) {
    NSURL *dir = [[ubiq URLByAppendingPathComponent:@"Documents" isDirectory:YES]
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
    saved = [fileManager copyItemAtURL:[NSURL fileURLWithPath:filePath]
                                 toURL:[dir URLByAppendingPathComponent:fileName]
                                 error:&copyError];
    DLog(@"saved #=> %i", saved);
    DLog(@"itemAtURL #=> %@", [NSURL fileURLWithPath:filePath]);
    DLog(@"destinationURL #=> %@", [dir URLByAppendingPathComponent:fileName]);
    if (copyError != nil) {
      DLog(@"copyError #=> %@", [copyError localizedDescription]);
    }
  }
  return saved;
}

- (BOOL)removeFile:(NSString *)fileName fromiCloudDirectory:(NSString *)directory
{
  DLogMethod;
  BOOL saved = false;
  NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
  if (ubiq) {
    NSURL *dir = [[ubiq URLByAppendingPathComponent:@"Documents" isDirectory:YES]
                        URLByAppendingPathComponent:directory isDirectory:YES];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    saved = [fileManager removeItemAtURL:[dir URLByAppendingPathComponent:fileName]
                                   error:&error];
    DLog(@"error #=> %@", error);
    DLog(@"saved #=> %i", saved);
  }
  return saved;
}

#pragma mark - UIDocument

- (void)loadRemoteFile:(NSString *)fileName
{
  NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
  self.query = query;
  [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", NSMetadataItemFSNameKey, fileName];
  [query setPredicate:predicate];
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(queryDidFinishGathering:)
           name:NSMetadataQueryDidFinishGatheringNotification
         object:query];
  [query startQuery];
}

- (void)loadData:(NSMetadataQuery *)query
{
  DLogMethod;
  DLog("count #=> %i", [query resultCount]);
  DLog("query #=> %@", query);
  if ([query resultCount] == 1) {
    NSMetadataItem *item = [query resultAtIndex:0];
    NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
    DLog(@"url #=> %@", url);
    if ([[url lastPathComponent] isEqualToString:@"products.plist"]) {
      NSData *data = [[NSData alloc] initWithContentsOfURL:url];
      NSArray *productDicts = [NSKeyedUnarchiver unarchiveObjectWithData:data];
      if (productDicts != nil && [productDicts count] > 0) {
        [self.products removeAllObjects];
        for (NSDictionary *productDict in productDicts) {
          DLog(@"[iCloud] productDict #=> %@", productDict);
          Product *product = [[Product alloc] init];
          [product setValuesForKeysWithDictionary:productDict];
          NSString *barcode = product.barcode;
          if (barcode) {
            [self loadRemoteFile:[barcode lastPathComponent]];
          }
          [self addProduct:product];
        }
        [self saveToLocal];
        // refresh HERE
      }
    } else { // barcode image
      DLog(@"barcode #=> %@", url);
    }
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
}

- (BOOL)writeContents:(id)contents
                toURL:(NSURL *)url
     forSaveOperation:(UIDocumentSaveOperation)operation
  originalContentsURL:(NSURL *)originalContentsURL
                error:(NSError **)error
{
  DLog(@"url #=> %@", url);
  DLog(@"contents #=> %@", [contents class]);
  DLog(@"original ContentsURL #=> %@", originalContentsURL);
  if ([self iCloudOn]) {
    return [super writeContents:contents toURL:url forSaveOperation:operation originalContentsURL:originalContentsURL error:error];
  } else {
    return YES;
  }
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)error
{
  DLogMethod;
  DLog(@"typeName #=> %@", typeName);
  if ([contents length] > 0) {
    DLog(@"1 contents #=> %@", contents);
  } else {
    DLog(@"0 contents #=> %@", contents);
  }
  return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)error
{
  NSMutableData *data = [NSMutableData data];
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
  [archiver encodeObject:self.products forKey:@"data"];
  [archiver finishEncoding];
  return data;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
  DLogMethod;
  DLog(@"error #=> %@", [error localizedDescription]);
  DLog(@"userInfo #=> %@", [error userInfo]);
}

@end
