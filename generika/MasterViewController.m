//
//  MasterViewController.m
//  generika
//
//  Created by Yasuhiro Asaka on 4/11/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import "JSONKit.h"
#import "AFJSONRequestOperation.h"

#import "MasterViewController.h"
#import "WebViewController.h"

@implementation MasterViewController

static float cellHeight = 83.0;

- (void)loadView
{
  [super loadView];
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  _tableView = [[UITableView alloc] initWithFrame:screenBounds];
  _tableView.delegate = self;
  _tableView.dataSource = self;	
  _tableView.rowHeight = cellHeight;
  self.view = _tableView;

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *path = [paths objectAtIndex:0];
  NSString *filePath = [path stringByAppendingPathComponent:@"products.plist"];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL exist = [fileManager fileExistsAtPath:filePath isDirectory:NO];
  DLog(@"products.plist exist: %d", exist);
  if (exist) {
    _objects = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
  } else {
    _objects = [[NSMutableArray alloc] init];
  }
  _reader = [[ZBarReaderViewController alloc] init];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.leftBarButtonItem = self.editButtonItem;

  UIBarButtonItem *scanButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                              target:self
                                                                              action:@selector(scanButtonTapped:)];
  self.navigationItem.rightBarButtonItem = scanButton;
  [self openReader];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  _tableView      = nil;
  _objects        = nil;
  _nameLabel      = nil;
  _sizeLabel      = nil;
  _priceLabel     = nil;
  _deductionLabel = nil;
  _categoryLabel  = nil;
  _eanLabel       = nil;
  _reader = nil;
  _browser = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  NSIndexPath* selection = [_tableView indexPathForSelectedRow];
  if (selection) {
    [_tableView deselectRowAtIndexPath:selection animated:YES];
  }
  [_tableView reloadData];
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [_tableView flashScrollIndicators];
  [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}

- (void)scanButtonTapped:(UIButton*)button
{
  if (!self.editing) {
    [self openReader];
  }
}

- (void)imagePickerController:(UIImagePickerController*)reader
didFinishPickingMediaWithInfo:(NSDictionary*)info
{
  id<NSFastEnumeration> results =
  [info objectForKey: ZBarReaderControllerResults];
  ZBarSymbol *symbol = nil;
  for (symbol in results) {
    break;
  }
  NSString *ean = [NSString stringWithString:symbol.data];
  UIImage *barcode = [info objectForKey: UIImagePickerControllerOriginalImage];
  DLog(@"ean: %@", ean);
  //DLog(@"barcode: %@", barcode);
  NSString *searchURL = [NSString stringWithFormat:@"%@/%@", @"http://ch.oddb.org/de/mobile/api_search/ean", ean];
  NSURL *productSearch = [NSURL URLWithString:searchURL];
  DLog(@"url[productSearch]: %@", productSearch);
  NSURLRequest *request = [NSURLRequest requestWithURL:productSearch];
  AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
      [self didFinishPicking:JSON withEan:ean barcode:barcode];
    }
    failure:^(NSURLRequest *request , NSHTTPURLResponse *response , NSError *error , id JSON) {
      // FIXME
      NSLog(@"error: %@", error);
      NSLog(@"response: %@", response);
    }];
  [operation start];
  if ([ean length] == 13) {
    // open oddb.org
    [self openCompareSearchByEan:ean];
  }
  [_reader dismissModalViewControllerAnimated: YES];
}

- (void)didFinishPicking:(id)json withEan:(NSString*)ean barcode:(UIImage*)barcode
{
  //DLog(@"json: %@", json);
  if (json == nil || [json count] == 0) {
    [self notFoundEan:ean];
  } else {
    // image
    NSString *barcodePath = [self storeBarcode:barcode ofEan:ean];
    DLog(@"barcodePath: %@", barcodePath);
    // text
    NSString *category = [[json valueForKeyPath:@"category"] stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    NSString *price = nil;
    if ([[json valueForKeyPath:@"price"] isEqual:[NSNull null]]) {
      price = [NSString stringWithString:@""];
    } else {
      price = [json valueForKeyPath:@"price"];
    }
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm dd.MM.YY"];
    NSString *dateString = [dateFormat stringFromDate:now];
    DLog(@"date: %@", dateString)
    NSDictionary *product = [NSDictionary dictionaryWithObjectsAndKeys:
      [json valueForKeyPath:@"reg"],       @"reg",
      [json valueForKeyPath:@"seq"],       @"seq",
      [json valueForKeyPath:@"pack"],      @"pack",
      [json valueForKeyPath:@"name"],      @"name",
      [json valueForKeyPath:@"size"],      @"size",
      [json valueForKeyPath:@"deduction"], @"deduction",
      price,       @"price",
      category,    @"category",
      barcodePath, @"barcode",
      ean,         @"ean",
      dateString,  @"datetime",
      nil];
    DLog(@"product: %@", product);
    [_objects insertObject:product atIndex:0];
    //DLog(@"_objects: %@", _objects);
    NSString *productsPath = [self storeProducts];
    DLog(@"productsPath: %@", productsPath);
    // alert
    NSString *publicPrice = nil;
    if ([price isEqualToString:@""]) {
      publicPrice = price;
    } else {
      publicPrice = [NSString stringWithFormat:@"CHF: %@", price];
    }
    NSString *message = [NSString stringWithFormat:@"%@,\n%@\n%@",
                          [product objectForKey:@"name"],
                          [product objectForKey:@"size"],
                          publicPrice];
    UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Generika.cc sagt:"
                                                   message:message
                                                  delegate:self
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
    [alert show];
  }
}

- (void)notFoundEan:(NSString*)ean
{
  NSString *message = [NSString stringWithFormat:@"\"%@\"", ean];
  UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Kein Medikament gefunden auf Generika.cc mit dem folgenden EAN-Code:"
                                                 message:message
                                                delegate:self 
                                       cancelButtonTitle:@"OK" 
                                       otherButtonTitles:nil];
  [alert show];
}

- (void)openReader
{
  _reader.readerDelegate = self;
  _reader.supportedOrientationsMask = ZBarOrientationMaskAll;
  ZBarImageScanner *scanner = _reader.scanner;
  // disable
  [scanner setSymbology:ZBAR_I25
                 config:ZBAR_CFG_ENABLE
                     to:0];
  [scanner setSymbology:ZBAR_UPCA
                 config:ZBAR_CFG_ENABLE
                     to:0];
  [scanner setSymbology:ZBAR_UPCE
                 config:ZBAR_CFG_ENABLE
                     to:0];
  [scanner setSymbology:ZBAR_ISBN10 
                 config:ZBAR_CFG_ENABLE
                     to:0];
  [scanner setSymbology:ZBAR_ISBN13
                 config:ZBAR_CFG_ENABLE
                     to:0];
  [scanner setSymbology:ZBAR_QRCODE
                 config:ZBAR_CFG_ENABLE
                     to:0];
  _reader.readerView.zoom = 2.25; //default 1.25
  [self presentModalViewController:_reader
                          animated:YES];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orient
                                duration:(NSTimeInterval) duration
{
  _reader.readerView.captureReader.enableReader = NO;
  [_reader.readerView willRotateToInterfaceOrientation:orient
                                              duration: 0];
  [super willRotateToInterfaceOrientation:orient
                                 duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orient
{
  [super didRotateFromInterfaceOrientation:orient];
  _reader.readerView.captureReader.enableReader = YES;
}

- (void)openCompareSearchByEan:(NSString*)ean
{
  NSString *webURL = [NSString stringWithFormat:@"%@/%@", @"http://ch.oddb.org/de/mobile/compare/ean13", ean];
  NSURL *compareSearch = [NSURL URLWithString:webURL];
  DLog(@"url[compareSearch]: %@", compareSearch);
  _browser = [[WebViewController alloc] init];
  [_browser loadURL:compareSearch];
  [self.navigationController pushViewController: _browser
                                       animated: YES];
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
  //DLog(@"error: %@", error);
  time_t timestamp = (time_t)[[NSDate date] timeIntervalSince1970];
  DLog(@"timestamp, %d", (int)timestamp);
  NSString *fileName = [NSString stringWithFormat:@"%@-%d.png", ean, (int)timestamp];
  NSString *filePath = [path stringByAppendingPathComponent:fileName];
  NSData *barcodeData = UIImagePNGRepresentation(barcodeImage);
  DLog(@"filePath: %@", filePath);
  BOOL saved = [barcodeData writeToFile:filePath atomically:YES];
  DLog(@"image saved: %d", saved);
  if (saved) {
    return filePath;
  } else {
    return nil;
  }
}

- (NSString *)storeProducts
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *path = [paths objectAtIndex:0];
  NSString *filePath = [path stringByAppendingPathComponent:@"products.plist"];
  DLog(@"filePath: %@", filePath);
  //DLog(@"_objects: %@", _objects);
  BOOL saved = [_objects writeToFile:filePath atomically:YES];
  DLog(@"plist saved: %d", saved);
  if (saved) {
    return filePath;
  } else {
    return nil;
  }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  DLog(@"objects count: %d", _objects.count);
  return _objects.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  //DLog(@"indexPath: %@", indexPath);
  static NSString *cellIdentifier = @"Cell";
  CGRect cellFrame = CGRectMake(0, 0, tableView.frame.size.width, 100);
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:cellIdentifier];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  UIView *productView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, cellFrame.size.width, cellFrame.size.height)];
  [cell.contentView addSubview:productView];

  NSDictionary *product = [_objects objectAtIndex:indexPath.row];
  //DLog(@"product %@", product);
  if ([product objectForKey:@"barcode"]) {
    //DLog(@"barcode: %@", [product objectForKey:@"barcode"]);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exist = [fileManager fileExistsAtPath:[product objectForKey:@"barcode"] isDirectory:NO];
    //DLog(@"image exist: %d", exist);
    if (exist) {
      UIImage *barcodeImage = [[UIImage alloc] initWithContentsOfFile:[product objectForKey:@"barcode"]];
      UIImageView *barcodeView = [[UIImageView alloc] initWithImage:barcodeImage];
      [cell.contentView addSubview:barcodeView];
    }
  }
  // name
  _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 2.0, 230.0, 25.0)];
  _nameLabel.font = [UIFont boldSystemFontOfSize:14.0];
  _nameLabel.textAlignment = UITextAlignmentLeft;
  _nameLabel.textColor = [UIColor blackColor];
  _nameLabel.text = [NSString stringWithString:[product objectForKey:@"name"]];
  [cell.contentView addSubview:_nameLabel];
  // size
  /*
  CGSize nameSize = [[_nameLabel text] sizeWithFont:[_nameLabel font]];
  CGRect sizeRect = CGRectMake(70 + _nameLabel.frame.size.width + 5.0, 7.0, 100.0, 30.0);
  if (nameSize.width < _nameLabel.frame.size.width) {
    sizeRect.origin.x = 70 + nameSize.width + 5.0;
  }
  */
  //DLog(@"nameSize = %f", nameSize.width);
  _sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 27.0, 110.0, 16.0)];
  _sizeLabel.font = [UIFont boldSystemFontOfSize:12.0];
  _sizeLabel.textAlignment = UITextAlignmentLeft;
  _sizeLabel.textColor = [UIColor blackColor];
  _sizeLabel.text = [NSString stringWithString:[product objectForKey:@"size"]];
  [cell.contentView addSubview:_sizeLabel];
  // datetime
  if ([product objectForKey:@"datetime"]) {
    _dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(170.0, 27.0, 100.0, 16.0)];
    _dateLabel.font = [UIFont systemFontOfSize:12.0];
    _dateLabel.textAlignment = UITextAlignmentLeft;
    _dateLabel.textColor = [UIColor grayColor];
    _dateLabel.text = [NSString stringWithString:[product objectForKey:@"datetime"]];
    [cell.contentView addSubview:_dateLabel];
  }
  // price
  _priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 45.0, 60.0, 16.0)];
  _priceLabel.font = [UIFont systemFontOfSize:12.0];
  _priceLabel.textAlignment = UITextAlignmentLeft;
  _priceLabel.textColor = [UIColor grayColor];
  NSString *price = [NSString stringWithString:[product objectForKey:@"price"]];
  //DLog(@"price: %@", price);
  if (![price isEqualToString:@"k.A."]) {
    _priceLabel.text = price;
  }
  [cell.contentView addSubview:_priceLabel];
  // deduction
  _deductionLabel = [[UILabel alloc] initWithFrame:CGRectMake(120.0, 45.0, 60.0, 16.0)];
  _deductionLabel.font = [UIFont systemFontOfSize:12.0];
  _deductionLabel.textAlignment = UITextAlignmentLeft;
  _deductionLabel.textColor = [UIColor grayColor];
  NSString *deduction = [NSString stringWithString:[product objectForKey:@"deduction"]];
  //DLog(@"deduction: %@", deduction);
  if (![deduction isEqualToString:@"k.A."]) {
    _deductionLabel.text = deduction;
  }
  [cell.contentView addSubview:_deductionLabel];
  // category
  _categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(171.0, 45.0, 190.0, 16.0)];
  _categoryLabel.font = [UIFont systemFontOfSize:12.0];
  _categoryLabel.textAlignment = UITextAlignmentLeft;
  _categoryLabel.textColor = [UIColor grayColor];
  _categoryLabel.text = [NSString stringWithString:[product objectForKey:@"category"]];
  [cell.contentView addSubview:_categoryLabel];
  // ean
  _eanLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 62.0, 260.0, 16.0)];
  _eanLabel.font = [UIFont systemFontOfSize:12.0];
  _eanLabel.textAlignment = UITextAlignmentLeft;
  _eanLabel.textColor = [UIColor grayColor];
  _eanLabel.text = [NSString stringWithString:[product objectForKey:@"ean"]];
  [cell.contentView addSubview:_eanLabel];

  //DLog(@"cell %@", cell);
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Return NO if you do not want the specified item to be editable.
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                            forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    NSDictionary *product = [_objects objectAtIndex:indexPath.row];
    NSString *barcodePath = [product objectForKey:@"barcode"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:barcodePath error:&error];
    DLog(@"remove image error: %@", error);
    [_objects removeObjectAtIndex:indexPath.row];
    [self storeProducts];
    [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  DLog(@"editing: %d", editing);
  [super setEditing:editing animated:YES];
  [_tableView setEditing:editing animated:YES];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
  if (fromIndexPath.section == toIndexPath.section) {
    if (_objects && toIndexPath.row < [_objects count]) {
      NSDictionary  *product = [_objects objectAtIndex:fromIndexPath.row];
      [_objects removeObject:product];
      [_objects insertObject:product atIndex:toIndexPath.row];
      [self storeProducts];
    }
  }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
  return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // open browser
  NSDictionary *object = [_objects objectAtIndex:indexPath.row];
  [self openCompareSearchByEan:[NSString stringWithString:[object objectForKey:@"ean"]]];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
