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

@interface MasterViewController ()

@property (nonatomic, strong, readwrite) Reachability *reachability;
@property (nonatomic, strong, readwrite) ZBarReaderViewController *reader;
@property (nonatomic, strong, readwrite) WebViewController *browser;
@property (nonatomic, strong, readwrite) SettingsViewController *settings;
@property (nonatomic, strong, readwrite) UISearchDisplayController *search;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) UITableView *productsView;
@property (nonatomic, strong, readwrite) NSMutableArray *products;
@property (nonatomic, strong, readwrite) NSMutableArray *filtered;

@end

@implementation MasterViewController

@synthesize reachability = _reachability, userDefaults = _userDefaults;
@synthesize reader = _reader, browser = _browser, settings = _settings;
@synthesize search = _search;
@synthesize productsView = _productsView;
@synthesize products = _products, filtered = _filtered;

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  _userDefaults = [NSUserDefaults standardUserDefaults];
  _reachability = [Reachability reachabilityForInternetConnection];
  // products
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *path = [paths objectAtIndex:0];
  NSString *filePath = [path stringByAppendingPathComponent:@"products.plist"];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL exist = [fileManager fileExistsAtPath:filePath isDirectory:NO];
  if (exist) {
    _products = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
  } else {
    _products = [[NSMutableArray alloc] init];
  }
  _filtered = [NSMutableArray arrayWithCapacity:[_products count]];
  return self;
}

- (void)dealloc
{
  [_products removeAllObjects], _products = nil;
  [_filtered removeAllObjects], _filtered = nil;
  _userDefaults = nil;
  _reachability = nil;
  [self didReceiveMemoryWarning];
}

- (void)didReceiveMemoryWarning
{
  if ([self isViewLoaded] && [self.view window] == nil) {
    _productsView = nil;
    _browser      = nil;
    _settings     = nil;
    _search       = nil;
  }
  [super didReceiveMemoryWarning];
}

- (void)loadView
{
  [super loadView];
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  self.productsView = [[UITableView alloc] initWithFrame:screenBounds];
  self.productsView.delegate = self;
  self.productsView.dataSource = self;
  self.productsView.rowHeight = kCellHeight;
  self.view = self.productsView;
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
  // toolbar
  [self layoutToolbar];
  // searchbar
  UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,self.productsView.frame.size.width, 44.0)];
  searchBar.tintColor = [UIColor lightGrayColor];
  searchBar.delegate = self;
  searchBar.placeholder = @"Medikament";
  [searchBar sizeToFit];
  self.productsView.tableHeaderView = searchBar;
  self.search = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
  self.search.delegate = self;
  self.search.searchResultsDelegate = self;
  self.search.searchResultsDataSource = self;
  // reader
  if (!self.reader) {
    self.reader = [[ZBarReaderViewController alloc] init];
  }
  // delay
  double delayInSeconds = 0.1;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [self openReader];
  });
}

- (void)viewWillAppear:(BOOL)animated
{
  NSIndexPath* selection = [self.productsView indexPathForSelectedRow];
  if (selection) {
    [self.productsView deselectRowAtIndexPath:selection animated:YES];
  }
  [self.productsView reloadData];
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [self.productsView flashScrollIndicators];
  [super viewDidAppear:animated];
}

- (void)layoutToolbar
{
  [self.navigationController setToolbarHidden:NO animated:NO];
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.frame = CGRectMake(0, 0, 40, 40);
  UIFont *font = [UIFont fontWithName:@"FontAwesome" size:20.0];
  [button.titleLabel setFont:font];
  [button setTitle:@"\uF013" forState:UIControlStateNormal];
  if (floor(NSFoundationVersionNumber) <= kVersionNumber_iOS_6_1) {
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  } else { // iOS 7 or later
    [button setTitleColor:[UIColor colorWithRed:6/255.0 green:121/255.0 blue:251/255.0 alpha:1.0]
                 forState:UIControlStateNormal];
  }
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

- (BOOL)isReachable
{
  NetworkStatus status = [self.reachability currentReachabilityStatus];
  switch (status) {
    case NotReachable:
      return NO;
      break;
    case ReachableViaWWAN:
      return YES;
      break;
    case ReachableViaWiFi:
      return YES;
      break;
  }
  return NO;
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
  self.reader.readerView.captureReader.enableReader = NO;
  [self.reader.readerView willRotateToInterfaceOrientation:orient
                                              duration:0];
  [super willRotateToInterfaceOrientation:orient
                                 duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orient
{
  [super didRotateFromInterfaceOrientation:orient];
  self.reader.readerView.captureReader.enableReader = YES;
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
  if (!self.settings) {
    self.settings = [[SettingsViewController alloc] init];
  }
  self.settings.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  UINavigationController *settingsNavigation = [[UINavigationController alloc] initWithRootViewController: self.settings];
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
  NSInteger selectedTypeIndex = [self.userDefaults integerForKey:@"search.result.type"];
  NSString *type = [[Constant searchTypes] objectAtIndex:selectedTypeIndex];
  if ([ean length] != 13) {
    [self notFoundEan:ean];
  } else {
    // API Request
    UIImage *barcode = [info objectForKey: UIImagePickerControllerOriginalImage];
    NSString *searchURL = [NSString stringWithFormat:@"%@/%@", kOddbProductSearchBaseURL, ean];
    NSURL *productSearch = [NSURL URLWithString:searchURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:productSearch];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
      success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSUInteger before = [self.products count];
        [self didFinishPicking:JSON withEan:ean barcode:barcode];
        NSUInteger after = [self.products count];
        if ([type isEqualToString:@"PI"] && before < after) {
          NSDictionary *product = [self.products objectAtIndex:0];
          [self searchInfoForProduct:product];
        }
      }
      failure:^(NSURLRequest *request , NSHTTPURLResponse *response , NSError *error , id JSON) {
        // pass
      }];
    [operation start];
    // open oddb.org
    if (![type isEqualToString:@"PI"]) {
      NSDictionary *product = [NSDictionary dictionaryWithObjectsAndKeys:
                                ean, @"ean",
                                nil];
      [self searchInfoForProduct:product];
    } else {
      [operation waitUntilFinished];
    }
  }
  [self.reader dismissViewControllerAnimated:YES completion:nil];
}

- (void)didFinishPicking:(id)json withEan:(NSString *)ean barcode:(UIImage *)barcode
{
  if (json == nil || [json count] == 0) {
    [self notFoundEan:ean];
  } else {
    // image
    NSString *barcodePath = [self storeBarcode:barcode ofEan:ean];
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
    [self.products insertObject:product atIndex:0];
    NSString *productsPath = [self storeProducts];
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
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Generika.cc sagt:"
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
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Kein Medikament gefunden auf Generika.cc mit dem folgenden EAN-Code:"
                                                  message:message
                                                 delegate:self
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
  [alert show];
}

- (void)openReader
{
  self.reader.readerDelegate = self;
  self.reader.supportedOrientationsMask = ZBarOrientationMaskAll;
  ZBarImageScanner *scanner = self.reader.scanner;
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
  [self presentViewController:self.reader animated:YES completion:nil];
}

- (void)searchInfoForProduct:(NSDictionary *)product
{
  NSString *ean = [NSString stringWithString:[product objectForKey:@"ean"]];

  NSInteger selectedTypeIndex = [self.userDefaults integerForKey:@"search.result.type"];
  NSString *type = [[Constant searchTypes] objectAtIndex:selectedTypeIndex];
  NSInteger selectedLangIndex = [self.userDefaults integerForKey:@"search.result.lang"];
  NSString *lang = [[Constant searchLangs] objectAtIndex:selectedLangIndex];

  NSString *url;
  if ([type isEqualToString:@"Preisvergleich"]) {
    url = [NSString stringWithFormat:@"%@/%@/mobile/compare/ean13/%@", kOddbBaseURL, lang, ean];
  } else if ([type isEqualToString:@"PI"]) {
    NSString *reg = [self extractRegistrationNumberFromEan:ean];
    NSString *seq = [NSString stringWithString:[product objectForKey:@"seq"]];
    url = [NSString stringWithFormat:@"%@/%@/mobile/patinfo/reg/%@/seq/%@", kOddbBaseURL, lang, reg, seq];
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
    registrationNumber = @"";
  } else {
    NSTextCheckingResult *match =
      [regexp firstMatchInString:ean options:0 range:NSMakeRange(0, ean.length)];
    if (match.numberOfRanges > 1) {
      registrationNumber = [ean substringWithRange:[match rangeAtIndex:1]];
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
  NSDictionary *dictionnary = [NSDictionary dictionaryWithObjectsAndKeys:userAgent, @"UserAgent", nil];
  [_userDefaults registerDefaults:dictionnary];

  if (!self.browser) {
    self.browser = [[WebViewController alloc] init];
  }
  [self.browser loadURL:url];
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
  time_t timestamp = (time_t)[[NSDate date] timeIntervalSince1970];
  NSString *fileName = [NSString stringWithFormat:@"%@_%d.png", ean, (int)timestamp];
  NSString *filePath = [path stringByAppendingPathComponent:fileName];
  NSData *barcodeData = UIImagePNGRepresentation(barcodeImage);
  BOOL saved = [barcodeData writeToFile:filePath atomically:YES];
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
  BOOL saved = [self.products writeToFile:filePath atomically:YES];
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
  if (tableView == self.search.searchResultsTableView) {
    return self.filtered.count;
  } else {
    return self.products.count;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"Cell";
  CGRect cellFrame = CGRectMake(0, 0, tableView.frame.size.width, 100);
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:cellIdentifier];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  UIView *productView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, cellFrame.size.width, cellFrame.size.height)];
  [cell.contentView addSubview:productView];

  NSDictionary *product;
  if (tableView == self.search.searchResultsTableView) {
    product = [self.filtered objectAtIndex:indexPath.row];
  } else {
    product = [self.products objectAtIndex:indexPath.row];
  }
  NSString *barcodePath = [product objectForKey:@"barcode"];
  if (barcodePath) { // replace absolute path
    NSRange range = [barcodePath rangeOfString:@"/Documents/"];
    if (range.location != NSNotFound) { // like stringByAbbreviatingWithTildeInPath
      barcodePath = [NSString stringWithFormat:@"~%@",
        [barcodePath substringFromIndex:range.location]];
    }
    barcodePath = [barcodePath stringByExpandingTildeInPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exist = [fileManager fileExistsAtPath:barcodePath isDirectory:NO];
    if (exist) {
      UIImage *barcodeImage = [[UIImage alloc] initWithContentsOfFile:barcodePath];
      UIImageView *barcodeView = [[UIImageView alloc] initWithImage:barcodeImage];
      [cell.contentView addSubview:barcodeView];
    }
  }
  // name
  UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 2.0, 230.0, 25.0)];
  nameLabel.font = [UIFont boldSystemFontOfSize:14.0];
  nameLabel.textAlignment = kTextAlignmentLeft;
  nameLabel.textColor = [UIColor blackColor];
  nameLabel.text = [NSString stringWithString:[product objectForKey:@"name"]];
  [cell.contentView addSubview:nameLabel];
  // size
  UILabel *sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 27.0, 110.0, 16.0)];
  sizeLabel.font = [UIFont boldSystemFontOfSize:12.0];
  sizeLabel.textAlignment = kTextAlignmentLeft;
  sizeLabel.textColor = [UIColor blackColor];
  sizeLabel.text = [NSString stringWithString:[product objectForKey:@"size"]];
  [cell.contentView addSubview:sizeLabel];
  // datetime
  if ([product objectForKey:@"datetime"]) {
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(170.0, 27.0, 100.0, 16.0)];
    dateLabel.font = [UIFont systemFontOfSize:12.0];
    dateLabel.textAlignment = kTextAlignmentLeft;
    dateLabel.textColor = [UIColor grayColor];
    dateLabel.text = [NSString stringWithString:[product objectForKey:@"datetime"]];
    [cell.contentView addSubview:dateLabel];
  }
  // price
  UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 45.0, 60.0, 16.0)];
  priceLabel.font = [UIFont systemFontOfSize:12.0];
  priceLabel.textAlignment = kTextAlignmentLeft;
  priceLabel.textColor = [UIColor grayColor];
  NSString *price = [NSString stringWithString:[product objectForKey:@"price"]];
  if (![price isEqualToString:@"k.A."]) {
    priceLabel.text = price;
  }
  [cell.contentView addSubview:priceLabel];
  // deduction
  UILabel *deductionLabel = [[UILabel alloc] initWithFrame:CGRectMake(120.0, 45.0, 60.0, 16.0)];
  deductionLabel.font = [UIFont systemFontOfSize:12.0];
  deductionLabel.textAlignment = kTextAlignmentLeft;
  deductionLabel.textColor = [UIColor grayColor];
  NSString *deduction = [NSString stringWithString:[product objectForKey:@"deduction"]];
  if (![deduction isEqualToString:@"k.A."]) {
    deductionLabel.text = deduction;
  }
  [cell.contentView addSubview:deductionLabel];
  // category
  UILabel *categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(171.0, 45.0, 190.0, 16.0)];
  categoryLabel.font = [UIFont systemFontOfSize:12.0];
  categoryLabel.textAlignment = kTextAlignmentLeft;
  categoryLabel.textColor = [UIColor grayColor];
  categoryLabel.text = [NSString stringWithString:[product objectForKey:@"category"]];
  [cell.contentView addSubview:categoryLabel];
  // ean
  UILabel *eanLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 62.0, 260.0, 16.0)];
  eanLabel.font = [UIFont systemFontOfSize:12.0];
  eanLabel.textAlignment = kTextAlignmentLeft;
  eanLabel.textColor = [UIColor grayColor];
  eanLabel.text = [NSString stringWithString:[product objectForKey:@"ean"]];
  [cell.contentView addSubview:eanLabel];

  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.search.searchResultsTableView) {
    return NO;
  } else {
    return YES;
  }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                            forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    NSDictionary *product = [self.products objectAtIndex:indexPath.row];
    NSString *barcodePath = [product objectForKey:@"barcode"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:barcodePath error:&error];
    [self.products removeObjectAtIndex:indexPath.row];
    [self storeProducts];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  [super setEditing:editing animated:YES];
  [self.productsView setEditing:editing animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.search.searchResultsTableView) {
    return NO;
  } else {
    return YES;
  }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
  if (fromIndexPath.section == toIndexPath.section) {
    if (self.products && toIndexPath.row < [self.products count]) {
      NSDictionary  *product = [self.products objectAtIndex:fromIndexPath.row];
      [self.products removeObject:product];
      [self.products insertObject:product atIndex:toIndexPath.row];
      [self storeProducts];
    }
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSDictionary *product;
  if (tableView == self.search.searchResultsTableView) {
    product = [self.filtered objectAtIndex:indexPath.row];
  } else {
    product = [self.products objectAtIndex:indexPath.row];
  }
  // open oddb.org
  [self searchInfoForProduct:product];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Searchbar

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
  [self.filtered removeAllObjects];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K contains[cd] %@", @"name", searchText];
  self.filtered = [NSMutableArray arrayWithArray:[self.products filteredArrayUsingPredicate:predicate]];
}


#pragma mark - UISearchDisplaycontroller delegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
  [self filterContentForSearchText:searchString
                             scope:[[self.search.searchBar scopeButtonTitles]
                     objectAtIndex:[self.search.searchBar selectedScopeButtonIndex]]];
  return YES;
}

@end
