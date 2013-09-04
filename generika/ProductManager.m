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

- (void)loadDocument;
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
  //self = [super init];
  NSURL *url = [NSURL fileURLWithPath:[self productsPath]];
  self = [super initWithFileURL:url];
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


#pragma mark - Accessor Methods

- (void)addProduct:(Product *)product
{
  if (!product) {
    return;
  }
  [self.products addObject:product];
}

- (void)insertProduct:(Product *)product atIndex:(unsigned int)index
{
  if (!product) {
    return;
  }
  if (index > [self.products count]) {
    return;
  }
  [self.products insertObject:product atIndex:index];
}

- (Product *)productAtIndex:(unsigned int)index
{
  if (index > ([self.products count] - 1)) {
    return nil;
  }
  return [self.products objectAtIndex:index];
}

- (void)removeProductAtIndex:(unsigned int)index
{
  if (index > ([self.products count] - 1)) {
    return;
  }
  [self.products removeObjectAtIndex:index];
}

- (void)moveProductAtIndex:(unsigned int)fromIndex toIndex:(unsigned int)toIndex
{
  if (fromIndex > ([self.products count] - 1)) {
    return;
  }
  if (toIndex > [self.products count]) {
    return;
  }
  Product *product;
  product = [self.products objectAtIndex:fromIndex];
  [self.products removeObject:product];
  [self.products insertObject:product atIndex:toIndex];
}


#pragma mark - Saving and Loading methods

- (NSString *)productsPath
{
  NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
  if ([self iCloudOn] && ubiq) {
    NSURL *plist = [ubiq URLByAppendingPathComponent:@"products.plist"];
    DLog(@"plist #=> %@", plist);
    return [plist absoluteString];
  } else {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([paths count] < 1) {
      return nil;
    }
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:@"products.plist"];
    return filePath;
  }
}

- (BOOL)iCloudOn
{
  return YES;
}

- (BOOL)saveToLocalFile
{
  NSMutableArray *productDicts = [[NSMutableArray alloc] init];
  NSString *productsPath = [self productsPath];
  for (Product *product in self.products) {
    NSDictionary *productDict = [product dictionaryWithValuesForKeys:[product productKeys]];
    [productDicts addObject:productDict]; 
  }
  return [productDicts writeToFile:productsPath atomically:YES];
}

- (NSString *)save
{
  BOOL saved = false;
  if ([self iCloudOn]) {
    // iCloud
    DLog(@"fileURL #=> %@", [self fileURL]);
    [self saveToURL:[self fileURL]
   forSaveOperation:UIDocumentSaveForCreating
  completionHandler:^(BOOL success) {
      if (success) {
        [self saveToLocalFile];
      }
    }];
  } else {
    saved = [self saveToLocalFile];
  }
  if (saved) {
    return [self productsPath];
  } else {
    return nil;
  }
}

- (void)loadDocument
{
  NSMetadataQuery *query = [[NSMetadataQuery alloc] init];
  self.query = query;
  [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", NSMetadataItemFSNameKey, @"products.plist"];
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
    if ([query resultCount] == 1) {
      NSMetadataItem *item = [query resultAtIndex:0];
      NSURL *url = [item valueForAttribute:NSMetadataItemURLKey];
      DLog(@"url #=> %@", url);
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

- (void)loadFromLocalFile
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *productsPath = [self productsPath];
  BOOL exist = [fileManager fileExistsAtPath:productsPath isDirectory:NO];
  if (exist) {
    NSArray *productDicts = [[NSArray alloc] initWithContentsOfFile:productsPath];
    for (NSDictionary *productDict in productDicts) {
      DLog(@"productDict #=> %@", productDict);
      Product *product = [[Product alloc] init];
      [product setValuesForKeysWithDictionary:productDict];
      [self addProduct:product];
    }
  }
}

- (void)load
{
  if ([self iCloudOn]) {
    [self loadDocument];
  } else {
    [self loadFromLocalFile];
  }
}


#pragma mark - UIDocument

- (BOOL)writeContents:(id)contents
                toURL:(NSURL *)url
     forSaveOperation:(UIDocumentSaveOperation)operation
  originalContentsURL:(NSURL *)originalContentsURL
                error:(NSError **)error
{
  DLog(@"url #=> %@", url);
  DLog(@"contents #=> %@", contents);
  [self.products writeToURL:url atomically:NO];
  //[super writeContents:contents toURL:url forSaveOperation:operation originalContentsURL:originalContentsURL error:error];
  return YES;
}
  
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)error
{
  if ([contents length] > 0) {
    DLog(@"1 contents #=> %@", contents);
  } else {
    DLog(@"0 contents #=> %@", contents);
  }
  return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)error
{
  DLog(@"typeName #=> %@", typeName);
  return self.products;
}

@end
