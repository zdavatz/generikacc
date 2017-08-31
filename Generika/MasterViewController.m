
//  MasterViewController.m
//  Generika
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import "JSONKit.h"
#import "AFHTTPSessionManager.h"
#import "Reachability.h"

#import "NTMonthYearPicker.h"
#import "UIPopoverController+iPhone.h"

#import "Product.h"
#import "ProductManager.h"

#import "MasterViewController.h"
#import "WebViewController.h"
#import "SettingsViewController.h"
#import "ReaderViewController.h"


static const float kCellHeight = 83.0;

@interface MasterViewController ()

@property (nonatomic, strong, readwrite) Reachability *reachability;
@property (nonatomic, strong, readwrite) ReaderViewController *reader;
@property (nonatomic, strong, readwrite) WebViewController *browser;
@property (nonatomic, strong, readwrite) SettingsViewController *settings;
@property (nonatomic, strong, readwrite) UISearchDisplayController *search;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) UITableView *productsView;
@property (nonatomic, strong, readwrite) NSMutableArray *filtered;
// datepicker
@property (nonatomic, strong, readwrite) NSIndexPath *pickerIndexPath;
@property (nonatomic, strong, readwrite) NTMonthYearPicker *datePicker;
@property (nonatomic, strong, readwrite) UIPopoverController *popOverForDatePicker;

- (void)scanButtonTapped:(UIButton *)button;
- (void)settingsButtonTapped:(UIButton *)button;
- (void)openReader;
- (void)openSettings;
- (void)searchInfoForProduct:(Product *)product;
- (void)openWebViewWithURL:(NSURL *)url;
- (void)layoutToolbar;
- (void)setToolbarButton:(UIButton *)button enabled:(BOOL)enabled;
- (BOOL)isReachable;

@end

@implementation MasterViewController

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  _userDefaults = [NSUserDefaults standardUserDefaults];
  _reachability = [Reachability reachabilityForInternetConnection];
  // products
  NSArray *products = [ProductManager sharedManager].products;
  _filtered = [NSMutableArray arrayWithCapacity:[products count]];
  return self;
}

- (void)dealloc
{
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
    _pickerIndexPath      = nil;
    _datePicker           = nil;
    _popOverForDatePicker = nil;
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
  UIBarButtonItem *scanButton = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                         target:self
                         action:@selector(scanButtonTapped:)];
  self.navigationItem.rightBarButtonItem = scanButton;
  // toolbar
  [self layoutToolbar];
  // searchbar
  UISearchBar *searchBar = [[UISearchBar alloc]
    initWithFrame:CGRectMake(0,0,self.productsView.frame.size.width, 44.0)];
  searchBar.tintColor = [UIColor lightGrayColor];
  searchBar.delegate = self;
  searchBar.placeholder = @"Medikament";
  [searchBar sizeToFit];
  self.productsView.tableHeaderView = searchBar;
  self.search = [[UISearchDisplayController alloc]
    initWithSearchBar:searchBar contentsController:self];
  self.search.delegate = self;
  self.search.searchResultsDelegate = self;
  self.search.searchResultsDataSource = self;
  // reader
  if (!self.reader) {
    self.reader = [[ReaderViewController alloc] init];
  }
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(didRotate:)
           name:UIDeviceOrientationDidChangeNotification
         object:nil];
  // notification
  ProductManager *manager = [ProductManager sharedManager];
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(refresh)
           name:@"productsDidLoaded"
         object:manager];
  // delay
  double delayInSeconds = 0.1;
  dispatch_time_t popTime = dispatch_time(
      DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [self openReader];
  });
}

- (void)viewWillAppear:(BOOL)animated
{
  NSIndexPath *selection = [self.productsView indexPathForSelectedRow];
  if (selection) {
    [self.productsView deselectRowAtIndexPath:selection animated:YES];
  }
  [self refresh];
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
  [self setToolbarButton:button enabled:YES];
  [button addTarget:self
             action:@selector(settingsButtonTapped:)
   forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *settingsBarButton = [[UIBarButtonItem alloc]
    initWithCustomView:button];
  UIBarButtonItem *space = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                         target:nil
                         action:nil];
  UIBarButtonItem *margin = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                         target:nil
                         action:nil];
  margin.width = -12;
  self.toolbarItems = [NSArray arrayWithObjects:
    space, settingsBarButton, margin, nil];
}

- (void)setToolbarButton:(UIButton *)button enabled:(BOOL)enabled
{
  if (enabled) {
    if (floor(NSFoundationVersionNumber) <= kVersionNumber_iOS_6_1) {
      [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else { // iOS 7 or later
      [button setTitleColor:[UIColor colorWithRed:6/255.0
                                            green:121/255.0
                                             blue:251/255.0
                                            alpha:1.0]
                   forState:UIControlStateNormal];
    }
  } else {
    [button setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
  }
  [button setEnabled:enabled];
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)didRotate:(NSNotification *)notification
{
  // pass
}

// iOS <= 5
- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] ==
      UIUserInterfaceIdiomPhone) {
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


#pragma mark - Util

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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Keine Verbindung zum Internet!"
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
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
    session.requestSerializer = [AFJSONRequestSerializer serializer];
    [session GET:[productSearch absoluteString]
      parameters:nil
      success:^(NSURLSessionDataTask *task, id responseObject) {
        ProductManager *manager = [ProductManager sharedManager];
        NSUInteger before = [manager.products count];
        [self didFinishPicking:responseObject withEan:ean barcode:barcode];
        NSUInteger after = [manager.products count];
        if ([type isEqualToString:@"PI"] && before < after) {
          Product *product = [manager productAtIndex:0];
          [self searchInfoForProduct:product];
        }
      }
      failure:^(NSURLSessionDataTask *task, NSError *error) {
        // pass
      }];
    // open oddb.org
    if (![type isEqualToString:@"PI"]) {
      Product *product = [[Product alloc] initWithEan:ean];
      [self searchInfoForProduct:product];
    }
  }
  [self.reader dismissViewControllerAnimated:YES completion:nil];
}

- (void)didFinishPicking:(id)json withEan:(NSString *)ean barcode:(UIImage *)barcode
{
  if (json == nil || [(NSArray *)json count] == 0) {
    [self notFoundEan:ean];
  } else {
    Product *product = [[Product alloc] init];
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm dd.MM.YY"];
    NSString *datetime = [dateFormat stringFromDate:now];
    ProductManager *manager = [ProductManager sharedManager];
    // more values
    NSDictionary *dict = @{
      @"reg"       : [json valueForKeyPath:@"reg"],
      @"seq"       : [json valueForKeyPath:@"seq"],
      @"pack"      : [json valueForKeyPath:@"pack"],
      @"name"      : [json valueForKeyPath:@"name"],
      @"size"      : [json valueForKeyPath:@"size"],
      @"deduction" : [json valueForKeyPath:@"deduction"],
      @"price"     : [json valueForKeyPath:@"price"],
      @"category"  : [[json valueForKeyPath:@"category"] stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "],
      @"barcode"   : [manager storeBarcode:barcode ofEan:ean to:@"both"],
      @"ean"       : ean,
      @"datetime"  : datetime,
      @"expiresAt" : @""
    };
    for (NSString *key in [dict allKeys]) {
      NSString *value = nil;
      if ([dict[key] isEqual:[NSNull null]]) {
        value = @"";
      } else {
        value = dict[key];
      }
      [product setValue:value forKey:key];
    }
    BOOL saved = [manager insertProduct:product atIndex:0];
    if (saved) {
      // alert
      NSString *publicPrice = nil;
      if ([product.price isEqualToString:@""]) {
        publicPrice = product.price;
      } else {
        publicPrice = [NSString stringWithFormat:@"CHF: %@", product.price];
      }
      NSString *message = [NSString stringWithFormat:@"%@,\n%@\n%@", product.name, product.size, publicPrice];
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

  [self presentViewController:self.reader animated:YES completion: nil];
}

- (void)searchInfoForProduct:(Product *)product
{
  NSInteger selectedTypeIndex = [self.userDefaults integerForKey:@"search.result.type"];
  NSString *type = [[Constant searchTypes] objectAtIndex:selectedTypeIndex];
  NSInteger selectedLangIndex = [self.userDefaults integerForKey:@"search.result.lang"];
  NSString *lang = [[Constant searchLangs] objectAtIndex:selectedLangIndex];
  NSString *url;
  if ([type isEqualToString:@"Preisvergleich"]) {
    url = [NSString stringWithFormat:@"%@/%@/mobile/compare/ean13/%@", kOddbBaseURL, lang, product.ean];
  } else if ([type isEqualToString:@"PI"]) {
    url = [NSString stringWithFormat:@"%@/%@/mobile/patinfo/reg/%@/seq/%@", kOddbBaseURL, lang, product.reg, product.seq];
  } else if ([type isEqualToString:@"FI"]) {
    url = [NSString stringWithFormat:@"%@/%@/mobile/fachinfo/reg/%@", kOddbBaseURL, lang, product.reg];
  }
  [self openWebViewWithURL:[NSURL URLWithString:url]];
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
  [self.navigationController pushViewController:self.browser
                                       animated:YES];
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
    return [[ProductManager sharedManager].products count];
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
  cell.preservesSuperviewLayoutMargins = true;
  cell.contentView.preservesSuperviewLayoutMargins = true;

  UIView *productView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, cellFrame.size.width, cellFrame.size.height)];
  [cell.contentView addSubview:productView];
  [tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];

  // gesture
  UILongPressGestureRecognizer *longPressGesture;
  if (tableView == self.search.searchResultsTableView) {
    // TODO (currently does nothing)
    longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:nil];
    longPressGesture.minimumPressDuration = 0.9; // seconds
    longPressGesture.delegate = self;
  } else {
    longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    longPressGesture.minimumPressDuration = 1.2; // seconds
    longPressGesture.delegate = self;
  }
  [cell addGestureRecognizer:longPressGesture];

  Product *product;
  if (tableView == self.search.searchResultsTableView) {
    product = [self.filtered objectAtIndex:indexPath.row];
  } else {
    product = [[ProductManager sharedManager] productAtIndex:indexPath.row];
  }
  NSString *barcodePath = product.barcode;
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
  nameLabel.text = product.name;
  [cell.contentView addSubview:nameLabel];
  // size
  UILabel *sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 26.0, 110.0, 16.0)];
  sizeLabel.font = [UIFont boldSystemFontOfSize:12.0];
  sizeLabel.textAlignment = kTextAlignmentLeft;
  sizeLabel.textColor = [UIColor blackColor];
  sizeLabel.text = product.size;
  [cell.contentView addSubview:sizeLabel];
  // datetime
  if (product.datetime) {
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(170.0, 27.0, 100.0, 16.0)];
    dateLabel.font = [UIFont systemFontOfSize:12.0];
    dateLabel.textAlignment = kTextAlignmentLeft;
    dateLabel.textColor = [UIColor grayColor];
    dateLabel.text = product.datetime;
    [cell.contentView addSubview:dateLabel];
  }
  // price
  UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 45.0, 60.0, 16.0)];
  priceLabel.font = [UIFont systemFontOfSize:12.0];
  priceLabel.textAlignment = kTextAlignmentLeft;
  priceLabel.textColor = [UIColor grayColor];
  NSString *price = product.price;
  if (![price isEqualToString:@"k.A."]) {
    priceLabel.text = price;
  }
  [cell.contentView addSubview:priceLabel];
  // deduction
  UILabel *deductionLabel = [[UILabel alloc] initWithFrame:CGRectMake(120.0, 45.0, 60.0, 16.0)];
  deductionLabel.font = [UIFont systemFontOfSize:12.0];
  deductionLabel.textAlignment = kTextAlignmentLeft;
  deductionLabel.textColor = [UIColor grayColor];
  NSString *deduction = product.deduction;
  if (![deduction isEqualToString:@"k.A."]) {
    deductionLabel.text = deduction;
  }
  [cell.contentView addSubview:deductionLabel];
  // category
  UILabel *categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(171.0, 45.0, 190.0, 16.0)];
  categoryLabel.font = [UIFont systemFontOfSize:12.0];
  categoryLabel.textAlignment = kTextAlignmentLeft;
  categoryLabel.textColor = [UIColor grayColor];
  categoryLabel.text = product.category;
  [cell.contentView addSubview:categoryLabel];
  // ean
  UILabel *eanLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 62.0, 110.0, 16.0)];
  eanLabel.font = [UIFont systemFontOfSize:12.0];
  eanLabel.textAlignment = kTextAlignmentLeft;
  eanLabel.textColor = [UIColor grayColor];
  eanLabel.text = product.ean;
  [cell.contentView addSubview:eanLabel];
  // expires_at
  UILabel *expiresAtLabel = [[UILabel alloc] initWithFrame:CGRectMake(170.0, 62.0, 100.0, 16.0)];
  expiresAtLabel.textAlignment = kTextAlignmentLeft;
  expiresAtLabel.tag = 7;
  if (product.expiresAt && [product.expiresAt length] != 0) {
    expiresAtLabel.text = product.expiresAt;
    expiresAtLabel.font = [UIFont systemFontOfSize:12.0];
    // comparison for color
    NSDate *current = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormat setDateFormat:@"dd.MM.yyyy HH:mm:ss"];
    NSDate *expiresAt = [dateFormat dateFromString:[NSString stringWithFormat:@"01.%@ 00:00:00", product.expiresAt]];
    if ([current compare: expiresAt] == NSOrderedDescending) {
      // current date is already later than expiration date
      expiresAtLabel.textColor = [UIColor redColor];
    } else {
      expiresAtLabel.textColor = [UIColor greenColor];
    }
  } else {
    expiresAtLabel.text = @"✚ (EXP; Verfalldatum)";
    expiresAtLabel.font = [UIFont systemFontOfSize:9.0];
    expiresAtLabel.textColor = [UIColor grayColor];
  }

  [cell.contentView addSubview:expiresAtLabel];

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
    Product *product = [[ProductManager sharedManager] productAtIndex:indexPath.row];
    NSString *barcodePath = product.barcode;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    [fileManager removeItemAtPath:barcodePath error:&error];
    ProductManager* manager = [ProductManager sharedManager];
    // manager removes product
    //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [manager removeProductAtIndex:indexPath.row];
    [self refresh];
    [self setEditing:NO animated:YES];
  }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  [super setEditing:editing animated:animated];
  [self.productsView setEditing:editing animated:animated];
  UIBarButtonItem *settingsBarButtonItem = [self.toolbarItems objectAtIndex:1];
  UIButton *button = (UIButton *)settingsBarButtonItem.customView;
  if (editing) {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self setToolbarButton:button enabled:NO];
  } else {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self setToolbarButton:button enabled:YES];
  }
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
    ProductManager *manager = [ProductManager sharedManager];
    if (manager.products && toIndexPath.row < [manager.products count]) {
      [manager moveProductAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
    }
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  Product *product;
  if (tableView == self.search.searchResultsTableView) {
    product = [self.filtered objectAtIndex:indexPath.row];
  } else {
    product = [[ProductManager sharedManager] productAtIndex:indexPath.row];
  }
  self.navigationItem.rightBarButtonItem.enabled = YES;
  // open oddb.org
  [self searchInfoForProduct:product];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath: (NSIndexPath *)indexPath
{
  self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)refresh
{
  [self.productsView reloadData];
}

#pragma mark - Gesture

- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
  if (gesture.state == UIGestureRecognizerStateBegan) {
    UITableViewCell *cell = (UITableViewCell *)[gesture view];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    self.pickerIndexPath = indexPath;
    
    UIViewController *viewc = [[UIViewController alloc] init];
    if (!self.datePicker) {
      self.datePicker = [[NTMonthYearPicker alloc] initWithFrame:CGRectMake(0, 0, 300, 140)];
      self.datePicker.hidden = NO;
    }
    Product *product;
    if (self.view == self.search.searchResultsTableView) {
      product = [self.filtered objectAtIndex:indexPath.row];
    } else {
      product = [[ProductManager sharedManager] productAtIndex:indexPath.row];
    }
    // set date as initial value
    if (product.expiresAt && [product.expiresAt length] != 0) {
      NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
      [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
      [dateFormat setDateFormat:@"dd.MM.yyyy HH:mm:ss"];
      NSDate *expiresAt = [dateFormat dateFromString:[NSString stringWithFormat:@"01.%@ 00:00:00", product.expiresAt]];
      self.datePicker.date = expiresAt;
    } else {
      self.datePicker.date = [NSDate date];
    }
    [self.datePicker addTarget:self action:@selector(changeDate:) forControlEvents:UIControlEventValueChanged];
    UIView *viewForDatePicker = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 140)];
    [viewForDatePicker addSubview:self.datePicker];
    [viewc.view addSubview:viewForDatePicker];

    self.popOverForDatePicker = [[UIPopoverController alloc] initWithContentViewController:viewc];
    [self.popOverForDatePicker setPopoverContentSize:CGSizeMake(300, 140) animated:NO];
    [self.popOverForDatePicker presentPopoverFromRect:cell.frame inView:self.view permittedArrowDirections:(UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown) animated:YES];
  }
}

- (void)changeDate:(id)sender
{
  NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
  [dateFormat setDateFormat:@"MM.YYYY"];
  NSString *value = [NSString stringWithFormat:@"%@", [dateFormat stringFromDate:self.datePicker.date]];

  if (self.popOverForDatePicker) {
    NSIndexPath *indexPath = self.pickerIndexPath;
    UITableViewCell *cell = [self.productsView cellForRowAtIndexPath:indexPath];
    if (cell) {
      ProductManager *manager = [ProductManager sharedManager];
      Product *product;
      if (self.view == self.search.searchResultsTableView) {
	product = [self.filtered objectAtIndex:indexPath.row];
      } else {
	product = [manager productAtIndex:indexPath.row];
      }
      if (value && [value length] != 0) {
	product.expiresAt = value;
	[manager save];

	// expires_at
	UILabel *expiresAtLabel = [cell.contentView viewWithTag:7];
	expiresAtLabel.font = [UIFont systemFontOfSize:12.0];
	expiresAtLabel.textAlignment = kTextAlignmentLeft;
	expiresAtLabel.text = value;
	// // comparison for color
	// NSDate *current = [NSDate date];
	// NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	// [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	// [dateFormat setDateFormat:@"dd.MM.yyyy HH:mm:ss"];
	// NSDate *expiresAt = [dateFormat dateFromString:[NSString stringWithFormat:@"01.%@ 00:00:00", product.expiresAt]];
	// if ([current compare: expiresAt] == NSOrderedDescending) {
	//   // current date is already later than expiration date
	//   expiresAtLabel.textColor = [UIColor redColor];
	// } else {
	//   expiresAtLabel.textColor = [UIColor greenColor];
	// }
      }
    }
  }
}

#pragma mark - Searchbar

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
  [self.filtered removeAllObjects];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K contains[cd] %@", @"name", searchText];
  self.filtered = [NSMutableArray arrayWithArray:[[ProductManager sharedManager].products filteredArrayUsingPredicate:predicate]];
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
