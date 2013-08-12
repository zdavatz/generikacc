//
//  MasterViewController.m
//  generika
//
//  Created by Yasuhiro Asaka on 4/11/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import "JSONKit.h"
#import "AFJSONRequestOperation.h"
#import "Reachability.h"

#import "MasterViewController.h"
#import "WebViewController.h"
#import "SettingsViewController.h"

static const float kCellHeight = 83.0;

@implementation MasterViewController

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  _userDefaults = [NSUserDefaults standardUserDefaults];
  return self;
}

- (void)loadView
{
  [super loadView];
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  _tableView = [[UITableView alloc] initWithFrame:screenBounds];
  _tableView.delegate = self;
  _tableView.dataSource = self;
  _tableView.rowHeight = kCellHeight;
  self.view = _tableView;

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *path = [paths objectAtIndex:0];
  NSString *filePath = [path stringByAppendingPathComponent:@"products.plist"];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL exist = [fileManager fileExistsAtPath:filePath isDirectory:NO];
  //DLog(@"products.plist exist: %d", exist);
  if (exist) {
    _objects = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
  } else {
    _objects = [[NSMutableArray alloc] init];
  }
  _reader = [[ZBarReaderViewController alloc] init];
  _reachability = [Reachability reachabilityForInternetConnection];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // navigation item
  self.navigationItem.leftBarButtonItem = self.editButtonItem;

  UIBarButtonItem *scanButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                              target:self
                                                                              action:@selector(scanButtonTapped:)];
  self.navigationItem.rightBarButtonItem = scanButton;
  // tool bar
  [self layoutToolbar];

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
  _settings = nil;
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

- (void)layoutToolbar
{
  [self.navigationController setToolbarHidden:NO animated:YES];
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.frame = CGRectMake(0, 0, 40, 40);
  UIFont *font = [UIFont fontWithName:@"FontAwesome" size:20.0];
  [button.titleLabel setFont:font];
  [button setTitle:@"\uF013" forState:UIControlStateNormal];
  [button addTarget:self
             action:@selector(settingsButtonTapped:)
   forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *settingsBarButton = [[UIBarButtonItem alloc] initWithCustomView:button];
  UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                         target:nil
                                                                         action:nil];
  UIBarButtonItem *margin = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                          target:nil
                                                                          action:nil];
  margin.width = -12;
  self.toolbarItems = [NSArray arrayWithObjects:space, settingsBarButton, margin, nil];
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskAllButUpsideDown;
}

// iOS <= 5
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orient
                                duration:(NSTimeInterval) duration
{
  _reader.readerView.captureReader.enableReader = NO;
  [_reader.readerView willRotateToInterfaceOrientation:orient
                                              duration:0];
  [super willRotateToInterfaceOrientation:orient
                                 duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orient
{
  [super didRotateFromInterfaceOrientation:orient];
  _reader.readerView.captureReader.enableReader = YES;
}

- (BOOL)isReachable
{
  NetworkStatus status = [_reachability currentReachabilityStatus];
  switch (status) {
    case NotReachable:
      //DLog(@"Reachable: No");
      return NO;
      break;
    case ReachableViaWWAN:
      //DLog(@"Reachable: WWAN");
      return YES;
      break;
    case ReachableViaWiFi:
      //DLog(@"Reachable: WiFi");
      return YES;
      break;
  }
  return NO;
}


#pragma mark - Settings View

- (void)settingsButtonTapped:(UIButton *)button
{
  if (!self.editing) {
    [self openSettings];
  }
}

- (void)openSettings
{
  _settings = [[SettingsViewController alloc] init];
  _settings.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  UINavigationController *settingsNavigation = [[UINavigationController alloc] initWithRootViewController: _settings];
  [self presentViewController:settingsNavigation animated:YES completion:nil];
}

#pragma mark - Scan View

- (void)scanButtonTapped:(UIButton *)button
{
  if (!self.editing) {
    [self openReader];
  }
}

- (void)imagePickerController:(UIImagePickerController *)reader
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  if (![self isReachable]) {
    UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Keine Verbindung zum Internet!"
                                                   message:nil
                                                  delegate:self
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
    [alert show];
    return;
  }
  id<NSFastEnumeration> results =
  [info objectForKey: ZBarReaderControllerResults];
  ZBarSymbol *symbol = nil;
  for (symbol in results) {
    break;
  }
  NSString *ean = [NSString stringWithString:symbol.data];
  //DLog(@"ean: %@", ean);
  if ([ean length] != 13) {
    // FIXME Not EAN
    [self notFoundEan:ean];
  } else {
    // API Request
    UIImage *barcode = [info objectForKey: UIImagePickerControllerOriginalImage];
    NSString *searchURL = [NSString stringWithFormat:@"%@/%@", kOddbProductSearchBaseURL, ean];
    NSURL *productSearch = [NSURL URLWithString:searchURL];
    //DLog(@"url[productSearch]: %@", productSearch);
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
    // open oddb.org
    [self searchWebWithEan:ean];
  }
  [_reader dismissViewControllerAnimated:YES completion:nil];
}

- (void)didFinishPicking:(id)json withEan:(NSString *)ean barcode:(UIImage *)barcode
{
  //DLog(@"json: %@", json);
  if (json == nil || [json count] == 0) {
    [self notFoundEan:ean];
  } else {
    // image
    NSString *barcodePath = [self storeBarcode:barcode ofEan:ean];
    //DLog(@"barcodePath: %@", barcodePath);
    // text
    NSString *category = [[json valueForKeyPath:@"category"] stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    NSString *price = nil;
    if ([[json valueForKeyPath:@"price"] isEqual:[NSNull null]]) {
      price = @"";
    } else {
      price = [json valueForKeyPath:@"price"];
    }
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm dd.MM.YY"];
    NSString *dateString = [dateFormat stringFromDate:now];
    //DLog(@"date: %@", dateString)
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
    //DLog(@"product: %@", product);
    [_objects insertObject:product atIndex:0];
    //DLog(@"_objects: %@", _objects);
    NSString *productsPath = [self storeProducts];
    //DLog(@"productsPath: %@", productsPath);
    if (productsPath) {
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
}

- (void)notFoundEan:(NSString *)ean
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
  //_reader.readerView.zoom = 2.25; //default 1.25
  [self presentViewController:_reader animated:YES completion:nil];
}

- (void)searchWebWithEan:(NSString *)ean
{
  NSInteger selectedTypeIndex = [_userDefaults integerForKey:@"search.result.type"];
  NSString *type = [[Constant searchTypes] objectAtIndex:selectedTypeIndex];
  NSInteger selectedLangIndex = [_userDefaults integerForKey:@"search.result.lang"];
  NSString *lang = [[Constant searchLangs] objectAtIndex:selectedLangIndex];

  NSString *url;
  if ([type isEqualToString:@"Preisvergleich"]) {
    url = [NSString stringWithFormat:@"%@/%@/mobile/compare/ean13/%@", kOddbBaseURL, lang, ean];
  } else if ([type isEqualToString:@"PI"]) {
    NSString *reg = [self extractRegistrationNumberFromEan:ean];
    // always open sequence as 01
    url = [NSString stringWithFormat:@"%@/%@/mobile/patinfo/reg/%@/seq/01", kOddbBaseURL, lang, reg];
  } else if ([type isEqualToString:@"FI"]) {
    NSString *reg = [self extractRegistrationNumberFromEan:ean];
    url = [NSString stringWithFormat:@"%@/%@/mobile/fachinfo/reg/%@", kOddbBaseURL, lang, reg];
  }
  [self openWebViewWithURL:[NSURL URLWithString:url]];
}

- (NSString *)extractRegistrationNumberFromEan:(NSString *)ean
{
  NSError *error = nil;
  NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"7680(\\d{5}).+"
                                                                          options:0
                                                                            error:&error];
  NSString *registrationNumber;
  if (error != nil) {
    DLog(@"error = %@", error);
    registrationNumber = @"";
  } else {
    NSTextCheckingResult *match =
      [regexp firstMatchInString:ean options:0 range:NSMakeRange(0, ean.length)];
    //DLog("match count = %i", match.numberOfRanges);
    if (match.numberOfRanges > 1) {
      registrationNumber = [ean substringWithRange:[match rangeAtIndex:1]];
      //DLog("matched text = %@", registrationNumber);
    } else {
      registrationNumber = @"";
    }
  }
  return registrationNumber;
}

- (void)openWebViewWithURL:(NSURL *)url
{
  // User-Agent
  NSString *originAgent = [[NSURLRequest requestWithURL:url] valueForHTTPHeaderField:@"User-Agent"];
  NSString *userAgent = [NSString stringWithFormat:@"%@ %@", originAgent, kOddbMobileFlavorUserAgent];
  //DLog(@"userAgent: %@", userAgent);
  NSDictionary *dictionnary = [NSDictionary dictionaryWithObjectsAndKeys:userAgent, @"UserAgent", nil];
  [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];

  _browser = [[WebViewController alloc] init];
  [_browser loadURL:url];
  [self.navigationController pushViewController:_browser
                                       animated:YES];
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
  //DLog(@"timestamp, %d", (int)timestamp);
  NSString *fileName = [NSString stringWithFormat:@"%@_%d.png", ean, (int)timestamp];
  NSString *filePath = [path stringByAppendingPathComponent:fileName];
  NSData *barcodeData = UIImagePNGRepresentation(barcodeImage);
  //DLog(@"filePath: %@", filePath);
  BOOL saved = [barcodeData writeToFile:filePath atomically:YES];
  //DLog(@"image saved: %d", saved);
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
  //DLog(@"filePath: %@", filePath);
  //DLog(@"_objects: %@", _objects);
  BOOL saved = [_objects writeToFile:filePath atomically:YES];
  //DLog(@"plist saved: %d", saved);
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
  //DLog(@"objects count: %d", _objects.count);
  return _objects.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kCellHeight;
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
  _nameLabel.textAlignment = kTextAlignmentLeft;
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
  _sizeLabel.textAlignment = kTextAlignmentLeft;
  _sizeLabel.textColor = [UIColor blackColor];
  _sizeLabel.text = [NSString stringWithString:[product objectForKey:@"size"]];
  [cell.contentView addSubview:_sizeLabel];
  // datetime
  if ([product objectForKey:@"datetime"]) {
    _dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(170.0, 27.0, 100.0, 16.0)];
    _dateLabel.font = [UIFont systemFontOfSize:12.0];
    _dateLabel.textAlignment = kTextAlignmentLeft;
    _dateLabel.textColor = [UIColor grayColor];
    _dateLabel.text = [NSString stringWithString:[product objectForKey:@"datetime"]];
    [cell.contentView addSubview:_dateLabel];
  }
  // price
  _priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 45.0, 60.0, 16.0)];
  _priceLabel.font = [UIFont systemFontOfSize:12.0];
  _priceLabel.textAlignment = kTextAlignmentLeft;
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
  _deductionLabel.textAlignment = kTextAlignmentLeft;
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
  _categoryLabel.textAlignment = kTextAlignmentLeft;
  _categoryLabel.textColor = [UIColor grayColor];
  _categoryLabel.text = [NSString stringWithString:[product objectForKey:@"category"]];
  [cell.contentView addSubview:_categoryLabel];
  // ean
  _eanLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 62.0, 260.0, 16.0)];
  _eanLabel.font = [UIFont systemFontOfSize:12.0];
  _eanLabel.textAlignment = kTextAlignmentLeft;
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
    //DLog(@"remove image error: %@", error);
    [_objects removeObjectAtIndex:indexPath.row];
    [self storeProducts];
    [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  //DLog(@"editing: %d", editing);
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
  NSDictionary *object = [_objects objectAtIndex:indexPath.row];
  NSString *ean = [NSString stringWithString:[object objectForKey:@"ean"]];
  // open oddb.org
  [self searchWebWithEan:ean];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
