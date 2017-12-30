//
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

#import "Receipt.h"
#import "ReceiptManager.h"

#import "WebViewController.h"
#import "AmkViewController.h"
#import "SettingsViewController.h"
#import "ReaderViewController.h"
#import "MasterViewController.h"


static const float kCellHeight = 83.0;
static const int kSegmentedControlTag = 100;
static const int kSegmentProduct = 0;
static const int kSegmentReceipt = 1;

@interface MasterViewController ()

@property (nonatomic, strong, readwrite) Reachability *reachability;
@property (nonatomic, strong, readwrite) NSMutableArray *filtered;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) UITableView *itemsView;
@property (nonatomic, strong, readwrite) UISearchController *search;
@property (nonatomic, strong, readwrite) ReaderViewController *reader;
@property (nonatomic, strong, readwrite) WebViewController *browser;
@property (nonatomic, strong, readwrite) AmkViewController *viewer;
@property (nonatomic, strong, readwrite) SettingsViewController *settings;
// datepicker
@property (nonatomic, strong, readwrite) NSIndexPath *pickerIndexPath;
@property (nonatomic, strong, readwrite) NTMonthYearPicker *datePicker;
@property (nonatomic, strong, readwrite)
  UIPopoverController *popOverForDatePicker;
// import file
@property (nonatomic, assign, readwrite) NSInteger selectedSegmentIndex;

- (void)segmentChanged:(UISegmentedControl *)control;
- (void)layoutToolbar;
- (void)setBarButton:(UIButton *)button enabled:(BOOL)enabled;
- (BOOL)isReachable;
// settings
- (void)settingsButtonTapped:(UIButton *)button;
- (void)openSettings;
// scan (camera)
- (void)scanButtonTapped:(UIButton *)button;
- (void)openReader;
// plus (import)
- (void)plusButtonTapped:(UIButton *)button;
- (void)openImporter;
// item:product
- (void)openWebViewWithURL:(NSURL *)url;
- (void)searchInfoForProduct:(Product *)product;
// item:receipt
- (void)displayInfoForReceipt:(Receipt *)receipt animated:(BOOL)animated;

@end

@implementation MasterViewController

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  _userDefaults = [NSUserDefaults standardUserDefaults];
  _reachability = [Reachability reachabilityForInternetConnection];
  return self;
}

- (void)dealloc
{
  [_filtered removeAllObjects];
  _filtered = nil;
  _userDefaults = nil;
  _reachability = nil;
  [self didReceiveMemoryWarning];
}

- (void)didReceiveMemoryWarning
{
  if ([self isViewLoaded] && [self.view window] == nil) {
    _itemsView = nil;
    _browser = nil;
    _settings = nil;
    _search = nil;
    _pickerIndexPath = nil;
    _datePicker = nil;
    _popOverForDatePicker = nil;
  }
  [super didReceiveMemoryWarning];
}

- (void)loadView
{
  [super loadView];

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  self.itemsView = [[UITableView alloc] initWithFrame:screenBounds];
  self.itemsView.delegate = self;
  self.itemsView.dataSource = self;
  self.itemsView.rowHeight = kCellHeight;
  self.view = self.itemsView;

  [self layoutTableViewSeparator:self.view];
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];

  [self layoutTableViewSeparator:self.itemsView];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  if ([self currentSegmentedType] == kSegmentReceipt) {
    NSArray *receipts = [ReceiptManager sharedManager].receipts;
    self.filtered = [NSMutableArray arrayWithCapacity:[receipts count]];
  } else { // product (default)
    NSArray *products = [ProductManager sharedManager].products;
    self.filtered = [NSMutableArray arrayWithCapacity:[products count]];
  }

  if (self.itemsView && [self.itemsView respondsToSelector:@selector(
      setCellLayoutMarginsFollowReadableWidth:)]) {
    self.itemsView.cellLayoutMarginsFollowReadableWidth = NO;
  }
  // navigation item
  // edit
  self.navigationItem.leftBarButtonItem = self.editButtonItem;
  // segmented control
  UIView *segmentView = [[UIView alloc]
                         initWithFrame:CGRectMake(0, 0, 196, 24)];
  UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]
    initWithItems:[NSArray arrayWithObjects:@"Medikamente", @"Rezepte", nil]];
  segmentedControl.frame = CGRectMake(0, 0, 196, 24);
  segmentedControl.selectedSegmentIndex = 0;
  segmentedControl.tintColor = [Constant activeUIColor];
  segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
  // set initial selected state
  segmentedControl.selectedSegmentIndex = self.selectedSegmentIndex;
  segmentedControl.tag = kSegmentedControlTag;
  [segmentedControl addTarget:self
                       action:@selector(segmentChanged:)
             forControlEvents:UIControlEventValueChanged];
  [segmentView addSubview:segmentedControl];
  self.navigationItem.titleView = segmentView;
  // camera
  UIBarButtonItem *scanButtonItem = [self buildScanButtonItem];
  self.navigationItem.rightBarButtonItem = scanButtonItem;
  // toolbar
  [self layoutToolbar];

  self.search = [[UISearchController alloc]
                 initWithSearchResultsController:nil];
  // searchbar
  self.search.searchBar.tintColor = [UIColor lightGrayColor];
  self.search.searchBar.delegate = self;
  self.search.searchBar.placeholder = @"Suchen";
  // fix ugly rounded field
  UITextField *searchField = [
    self.search.searchBar valueForKey:@"_searchField"];
  searchField.layer.borderColor = [[UIColor whiteColor] CGColor];
  searchField.layer.borderWidth = 3;
  searchField.layer.cornerRadius = 4.0;
  [self.search.searchBar sizeToFit];
  self.itemsView.tableHeaderView = self.search.searchBar;

  self.search.searchResultsUpdater = self;
  self.search.delegate = self;
  self.search.dimsBackgroundDuringPresentation = NO;
  // fix wrong position (fixed position)
  self.search.hidesNavigationBarDuringPresentation = NO;

  self.definesPresentationContext = YES;

  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(didRotate:)
           name:UIDeviceOrientationDidChangeNotification
         object:nil];
  if (self.selectedSegmentIndex == kSegmentReceipt) {
    // notification
    ReceiptManager *manager = [ReceiptManager sharedManager];
    [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(refresh)
             name:@"receiptsDidLoaded"
           object:manager];
  } else {  // product (default)
    // notification
    ProductManager *manager = [ProductManager sharedManager];
    [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(refresh)
             name:@"productsDidLoaded"
           object:manager];
    // reader
    if (!self.reader) {
      self.reader = [[ReaderViewController alloc] init];
    }
    // delay
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(
        DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self openReader];
    });
  }
}

- (void)viewWillAppear:(BOOL)animated
{
  NSIndexPath *selection = [self.itemsView indexPathForSelectedRow];
  if (selection) {
    [self.itemsView deselectRowAtIndexPath:selection animated:YES];
  }
  [self refresh];
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [self.itemsView flashScrollIndicators];
  [super viewDidAppear:animated];
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
  if ([self currentSegmentedType] == kSegmentProduct) {
    self.reader.readerView.captureReader.enableReader = NO;
    [self.reader.readerView willRotateToInterfaceOrientation:orient
                                                    duration:0];
  }
  [super willRotateToInterfaceOrientation:orient
                                 duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orient
{
  [super didRotateFromInterfaceOrientation:orient];
  if ([self currentSegmentedType] == kSegmentProduct) {
    self.reader.readerView.captureReader.enableReader = YES;
  }
}

# pragma mark - Components

- (UIBarButtonItem *)buildScanButtonItem
{
    UIButton *scanButton = [UIButton buttonWithType:UIButtonTypeCustom];
    scanButton.frame = CGRectMake(0, 0, 20, 20);
    UIFont *scanFont = [UIFont fontWithName:@"FontAwesome" size:19.0];
    [scanButton.titleLabel setFont:scanFont];
    // FIXME: right margin
    [scanButton setTitle:@"  \uF030" forState:UIControlStateNormal];
    [scanButton setTitleColor:[Constant activeUIColor]
                     forState:UIControlStateNormal];
    [scanButton addTarget:self
                   action:@selector(scanButtonTapped:)
         forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *scanButtonItem = [[UIBarButtonItem alloc]
      initWithCustomView:scanButton];
    scanButtonItem.width = 26;
    return scanButtonItem;
}

- (UIBarButtonItem *)buildPlusButtonItem
{
  UIBarButtonItem *plusButtonItem = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                         target:self
                         action:@selector(plusButtonTapped:)];
  return plusButtonItem;
}

# pragma mark - Layout

- (void)layoutTableViewSeparator:(UITableView *)tableView
{
  if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
    [tableView setSeparatorInset:UIEdgeInsetsZero];
  }
  if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
    [tableView setLayoutMargins:UIEdgeInsetsZero];
  }
  if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
    tableView.cellLayoutMarginsFollowReadableWidth = NO;
  }
}

- (void)layoutCellSeparator:(UITableViewCell *)cell
{
  if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
    cell.separatorInset = UIEdgeInsetsZero;
  }
  if ([cell respondsToSelector:@selector(
    setPreservesSuperviewLayoutMargins:)]) {
    cell.preservesSuperviewLayoutMargins = NO;
  }
  if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
    cell.layoutMargins = UIEdgeInsetsZero;
  }
}

- (void)layoutToolbar
{
  [self.navigationController setToolbarHidden:NO animated:NO];
  // wheel icon button
  UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
  settingsButton.frame = CGRectMake(0, 0, 40, 40);
  UIFont *settingsFont = [UIFont fontWithName:@"FontAwesome" size:22.0];
  [settingsButton.titleLabel setFont:settingsFont];
  [settingsButton setTitle:@"\uF013" forState:UIControlStateNormal];
  [self setBarButton:settingsButton enabled:YES];
  [settingsButton addTarget:self
                     action:@selector(settingsButtonTapped:)
           forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *settingsBarButton = [[UIBarButtonItem alloc]
    initWithCustomView:settingsButton];
  // interaction link
  UIButton *interactionButton = [UIButton buttonWithType:UIButtonTypeCustom];
  interactionButton.frame = CGRectMake(0, 0, 120, 40);
  // balance-scale icon
  UIFont *interactionFont = [UIFont fontWithName:@"FontAwesome" size:18.0];
  [interactionButton.titleLabel setFont:interactionFont];
  [interactionButton setTitle:@"\uF24e" forState:UIControlStateNormal];

  [self setBarButton:interactionButton enabled:YES];
  [interactionButton addTarget:self
                        action:@selector(interactionButtonTapped:)
              forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *interactionBarButton = [[UIBarButtonItem alloc]
    initWithCustomView:interactionButton];

  UIBarButtonItem *space = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                         target:nil
                         action:nil];
  UIBarButtonItem *lMargin = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                         target:nil
                         action:nil];
  lMargin.width = -48;
  UIBarButtonItem *rMargin = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                         target:nil
                         action:nil];
  rMargin.width = -9;
  self.toolbarItems = [NSArray arrayWithObjects:
    lMargin, interactionBarButton, space, settingsBarButton, rMargin, nil];
}

- (void)setBarButton:(UIButton *)button enabled:(BOOL)enabled
{
  if (enabled) {
    if (floor(NSFoundationVersionNumber) <= kVersionNumber_iOS_6_1) {
      [button setTitleColor:[UIColor whiteColor]
                   forState:UIControlStateNormal];
    } else { // iOS 7 or later
      [button setTitleColor:[Constant activeUIColor]
                   forState:UIControlStateNormal];
    }
    button.alpha = 1.0;
  } else { // disabled
    [button setTitleColor:[UIColor grayColor]
                 forState:UIControlStateDisabled];
    button.alpha = 0.6;
  }
  [button setEnabled:enabled];
}

# pragma mark - Util

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

- (int)currentSegmentedType
{
  if (self.navigationItem && self.navigationItem.titleView) {
    UIView *titleView = self.navigationItem.titleView;
    UISegmentedControl *control = (UISegmentedControl *)[
      titleView viewWithTag:kSegmentedControlTag];
    return control.selectedSegmentIndex;
  } else {
    return (int)self.selectedSegmentIndex;
  }
}

# pragma mark - Segmented Control

- (void)segmentChanged:(UISegmentedControl *)control
{
  [self setEditing:NO animated:YES]; // tableview
  if (self.reader) { // dissmiss reader if exists
    [self.reader dismissViewControllerAnimated:NO completion:nil];
  }
  if (self.search) { // cancel search
    [self.search setActive:NO];
  }

  // toolbar: space, interaction, space, settings, space
  UIBarButtonItem *interactionItem = [self.toolbarItems objectAtIndex:1];
  UIButton *interactionButton = (UIButton *)interactionItem.customView;

  if (control.selectedSegmentIndex == kSegmentReceipt) {
    // navigationbar
    // change button camera -> plus
    UIBarButtonItem *plusButtonItem = [self buildPlusButtonItem];
    self.navigationItem.rightBarButtonItem = plusButtonItem;
    // toolbar
    [self setBarButton:interactionButton enabled:NO];
    interactionButton.hidden = YES;
  } else { // product (default)
    // navigationbar
    // change button plus -> camera
    UIBarButtonItem *scanButtonItem = [self buildScanButtonItem];
    self.navigationItem.rightBarButtonItem = scanButtonItem;
    // toolbar
    [self setBarButton:interactionButton enabled:YES];
    interactionButton.hidden = NO;
  }
  _filtered = nil;
  [self refresh];
}

# pragma mark - Interaction Link

- (void)interactionButtonTapped:(UIButton *)button
{
  if (!self.editing) {
    // open in safari
    NSInteger selectedLangIndex = [self.userDefaults
                                   integerForKey:@"search.result.lang"];
    NSString *lang = [[Constant searchLangs] objectAtIndex:selectedLangIndex];
    NSArray *uniqueEANs;
    uniqueEANs = [[ProductManager sharedManager].products
                  valueForKeyPath:@"@distinctUnionOfObjects.ean"];
    NSMutableString *productEANs = [NSMutableString string];
    for (NSString *ean in uniqueEANs) {
      [productEANs appendString:[NSString stringWithFormat:@",%@", ean]];
    }
    if ([productEANs length] != 0) {
      productEANs = [productEANs substringWithRange:NSMakeRange(
        1, ([productEANs length] - 1))];
      NSString *url;
      url = [NSString stringWithFormat:
        @"%@/%@/gcc/home_interactions/%@", kOddbBaseURL, lang, productEANs];
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
  }
}

# pragma mark - Settings View

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
  UINavigationController *settingsNavigation = [[UINavigationController alloc]
    initWithRootViewController: self.settings];
  [self presentViewController:settingsNavigation animated:YES completion:nil];
}

# pragma mark - Plus View

- (void)plusButtonTapped:(UIButton *)button
{
  if (!self.editing) {
    [self openImporter];
  }
}

- (void)openImporter
{
  // TODO
}

# pragma mark - Scan View

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
    UIAlertView *alert = [[UIAlertView alloc]
      initWithTitle:@"Keine Verbindung zum Internet!"
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
  NSInteger selectedTypeIndex = [self.userDefaults
    integerForKey:@"search.result.type"];
  NSString *type = [[Constant searchTypes] objectAtIndex:selectedTypeIndex];
  if ([ean length] != 13) {
    [self notFoundEan:ean];
  } else {
    // API Request
    UIImage *barcode = [info objectForKey:
      UIImagePickerControllerOriginalImage];
    NSString *searchURL = [NSString stringWithFormat:
      @"%@/%@", kOddbProductSearchBaseURL, ean];
    NSURL *productSearch = [NSURL URLWithString:searchURL];
    // https://github.com/AFNetworking/AFNetworking/wiki/ \
    //   AFNetworking-3.0-Migration-Guide#afnetworking-3x-1
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
    session.requestSerializer = [AFJSONRequestSerializer serializer];
    [session GET:[productSearch absoluteString]
      parameters:nil
         success:^(NSURLSessionTask *task, id responseObject) {
           ProductManager *manager = [ProductManager sharedManager];
           NSUInteger before = [manager.products count];
           [self didFinishPicking:responseObject withEan:ean barcode:barcode];
           NSUInteger after = [manager.products count];
           if ([type isEqualToString:@"PI"] && before < after) {
             Product *product = [manager productAtIndex:0];
             [self searchInfoForProduct:product];
           }
         }
         failure:^(NSURLSessionTask *task, NSError *error) {
            // pass
         }
    ];
    // open oddb.org
    if (![type isEqualToString:@"PI"]) {
      Product *product = [[Product alloc] initWithEan:ean];
      [self searchInfoForProduct:product];
    }
  }
  [self.reader dismissViewControllerAnimated:YES completion:nil];
}

- (void)didFinishPicking:(id)json
                 withEan:(NSString *)ean
                 barcode:(UIImage *)barcode
{
  if (json == nil || [(NSArray *)json count] == 0) {
    [self notFoundEan:ean];
  } else {
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm dd.MM.YY"];
    NSString *datetime = [dateFormat stringFromDate:now];
    ProductManager *manager = [ProductManager sharedManager];

    NSString *barcodePath = [manager storeBarcode:barcode
                                            ofEan:ean
                                               to:@"both"];
    NSDictionary *dict = @{
      @"regnrs"       : [json valueForKeyPath:@"reg"],
      @"seq"          : [json valueForKeyPath:@"seq"],
      @"package"      : [json valueForKeyPath:@"pack"],
      @"product_name" : [json valueForKeyPath:@"name"],
      @"size"         : [json valueForKeyPath:@"size"],
      @"deduction"    : [json valueForKeyPath:@"deduction"],
      @"price"        : [json valueForKeyPath:@"price"],
      @"category"     : [[json valueForKeyPath:@"category"]
        stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "],
      @"eancode"      : ean
    };
    Product *product = [Product importFromDict:dict];
    // additional values
    [product setValue:barcodePath forKey:@"barcode"];
    [product setValue:@"" forKey:@"expiresAt"];
    [product setValue:datetime forKey:@"datetime"];

    BOOL saved = [manager insertProduct:product atIndex:0];
    if (saved) {
      // alert
      NSString *publicPrice = nil;
      if ([product.price isEqualToString:@""]) {
        publicPrice = product.price;
      } else {
        publicPrice = [NSString stringWithFormat:@"CHF: %@", product.price];
      }
      NSString *message = [NSString stringWithFormat:
        @"%@,\n%@\n%@", product.name, product.size, publicPrice];
      UIAlertView *alert = [[UIAlertView alloc]
          initWithTitle:@"Generika.cc sagt:"
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
  UIAlertView *alert = [[UIAlertView alloc]
    initWithTitle:
    @"Kein Medikament gefunden auf Generika.cc mit dem folgenden EAN-Code:"
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

# pragma mark - Product

- (void)searchInfoForProduct:(Product *)product
{
  NSInteger selectedTypeIndex = [self.userDefaults integerForKey:
    @"search.result.type"];
  NSString *type = [[Constant searchTypes] objectAtIndex:selectedTypeIndex];
  NSInteger selectedLangIndex = [self.userDefaults integerForKey:
    @"search.result.lang"];
  NSString *lang = [[Constant searchLangs] objectAtIndex:selectedLangIndex];
  NSString *url;
  if ([type isEqualToString:@"Preisvergleich"]) {
    url = [NSString stringWithFormat:@"%@/%@/mobile/compare/ean13/%@",
           kOddbBaseURL, lang, product.ean];
  } else if ([type isEqualToString:@"PI"]) {
    url = [NSString stringWithFormat:@"%@/%@/mobile/patinfo/reg/%@/seq/%@",
           kOddbBaseURL, lang, product.reg, product.seq];
  } else if ([type isEqualToString:@"FI"]) {
    url = [NSString stringWithFormat:@"%@/%@/mobile/fachinfo/reg/%@",
           kOddbBaseURL, lang, product.reg];
  }
  [self openWebViewWithURL:[NSURL URLWithString:url]];
}

- (void)openWebViewWithURL:(NSURL *)url
{
  // User-Agent
  NSString *originAgent = [[NSURLRequest requestWithURL:url]
                           valueForHTTPHeaderField:@"User-Agent"];
  NSString *userAgent = [NSString stringWithFormat:
    @"%@ %@", originAgent, kOddbMobileFlavorUserAgent];
  NSDictionary *dictionnary = [NSDictionary
    dictionaryWithObjectsAndKeys:userAgent, @"UserAgent", nil];
  [self.userDefaults registerDefaults:dictionnary];

  if (!self.browser) {
    self.browser = [[WebViewController alloc] init];
  }
  [self.browser loadURL:url];
  [self.navigationController pushViewController:self.browser
                                       animated:YES];
}

# pragma mark - Receipt

- (void)displayInfoForReceipt:(Receipt *)receipt animated:(BOOL)animated
{
  // If animated is NO (at boot), This generates `Unbalanced calls to
  // begin/end appearance transitions for ...`. But, it's trivial matter,
  // here :-D
  if (!self.viewer) {
    self.viewer = [[AmkViewController alloc] init];
  }
  [self.viewer loadReceipt:receipt];
  if (!self.viewer.isViewLoaded || !self.viewer.view.window) {
    [self.navigationController pushViewController:self.viewer
                                         animated:animated];
  }
}

# pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
{
  [self layoutCellSeparator:cell];
}

- (NSInteger)tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
  if (self.search.active) {
    return self.filtered.count;
  }
  if ([self currentSegmentedType] == kSegmentReceipt) {
    return [[ReceiptManager sharedManager].receipts count];
  }
  // product (default)
  return [[ProductManager sharedManager].products count];
}

- (CGFloat)tableView:(UITableView *)tableView
  heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"Cell";
  CGRect cellFrame = CGRectMake(0, 0, tableView.frame.size.width, 100);
  UITableViewCell *cell = [[UITableViewCell alloc]
    initWithStyle:UITableViewCellStyleDefault
  reuseIdentifier:cellIdentifier];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

  UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(
      0.0, 0.0, cellFrame.size.width, cellFrame.size.height)];
  [cell.contentView addSubview:itemView];

  // build cell
  if ([self currentSegmentedType] == kSegmentReceipt) {
    Receipt *receipt;
    if (self.search.active) {
      receipt = [self.filtered objectAtIndex:indexPath.row];
    } else {
      receipt = [[ReceiptManager sharedManager] receiptAtIndex:indexPath.row];
    }
    // datetime (imported at)
    if (receipt.datetime) {
      UILabel *datetimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(
          175.0, 27.0, 100.0, 16.0)];
      datetimeLabel.font = [UIFont systemFontOfSize:12.0];
      datetimeLabel.textAlignment = kTextAlignmentLeft;
      datetimeLabel.textColor = [UIColor grayColor];
      datetimeLabel.text = receipt.datetime;
      [cell.contentView addSubview:datetimeLabel];
    }
    // place date
    UILabel *placeDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        175.0, 62.0, 100.0, 16.0)];
    placeDateLabel.textAlignment = kTextAlignmentLeft;
    placeDateLabel.tag = 7;
    NSString *placeDate = receipt.placeDate;
    if (placeDate && [placeDate length] != 0) {
      placeDateLabel.text = placeDate;
      placeDateLabel.font = [UIFont boldSystemFontOfSize:12.0];
    }
    [cell.contentView addSubview:placeDateLabel];
  } else {  // product
    // gesture
    UILongPressGestureRecognizer *longPressGesture;
    if (self.search.active) {
      // TODO (currently does nothing)
      longPressGesture = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:nil];
      longPressGesture.minimumPressDuration = 0.9; // seconds
      longPressGesture.delegate = self;
    } else {
      longPressGesture = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(longPress:)];
      longPressGesture.minimumPressDuration = 1.2; // seconds
      longPressGesture.delegate = self;
    }
    [cell addGestureRecognizer:longPressGesture];

    Product *product;
    if (self.search.active) {
      product = [self.filtered objectAtIndex:indexPath.row];
    } else {
      product = [[ProductManager sharedManager] productAtIndex:indexPath.row];
    }
    NSString *barcodePath = product.barcode;
    if (barcodePath) { // replace absolute path
      NSRange range = [barcodePath rangeOfString:@"/Documents/"];
      // like stringByAbbreviatingWithTildeInPath
      if (range.location != NSNotFound) {
        barcodePath = [NSString stringWithFormat:@"~%@",
          [barcodePath substringFromIndex:range.location]];
      }
      barcodePath = [barcodePath stringByExpandingTildeInPath];
      NSFileManager *fileManager = [NSFileManager defaultManager];
      BOOL exist = [fileManager fileExistsAtPath:barcodePath isDirectory:NO];
      if (exist) {
        UIImage *barcodeImage = [[UIImage alloc]
          initWithContentsOfFile:barcodePath];
        UIImageView *barcodeView = [[UIImageView alloc]
          initWithImage:barcodeImage];
        [cell.contentView addSubview:barcodeView];
      }
    }
    // name
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        70.0, 2.0, 230.0, 25.0)];
    nameLabel.font = [UIFont boldSystemFontOfSize:14.0];
    nameLabel.textAlignment = kTextAlignmentLeft;
    nameLabel.textColor = [UIColor blackColor];
    nameLabel.text = product.name;
    [cell.contentView addSubview:nameLabel];
    // size
    UILabel *sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        70.0, 26.0, 110.0, 16.0)];
    sizeLabel.font = [UIFont boldSystemFontOfSize:12.0];
    sizeLabel.textAlignment = kTextAlignmentLeft;
    sizeLabel.textColor = [UIColor blackColor];
    sizeLabel.text = product.size;
    [cell.contentView addSubview:sizeLabel];
    // datetime
    if (product.datetime) {
      UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(
          175.0, 27.0, 100.0, 16.0)];
      dateLabel.font = [UIFont systemFontOfSize:12.0];
      dateLabel.textAlignment = kTextAlignmentLeft;
      dateLabel.textColor = [UIColor grayColor];
      dateLabel.text = product.datetime;
      [cell.contentView addSubview:dateLabel];
    }
    // price
    UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        70.0, 45.0, 60.0, 16.0)];
    priceLabel.font = [UIFont systemFontOfSize:12.0];
    priceLabel.textAlignment = kTextAlignmentLeft;
    priceLabel.textColor = [UIColor grayColor];
    NSString *price = product.price;
    if (![price isEqualToString:@"k.A."]) {
      priceLabel.text = price;
    }
    [cell.contentView addSubview:priceLabel];
    // deduction
    UILabel *deductionLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        125.0, 45.0, 60.0, 16.0)];
    deductionLabel.font = [UIFont systemFontOfSize:12.0];
    deductionLabel.textAlignment = kTextAlignmentLeft;
    deductionLabel.textColor = [UIColor grayColor];
    NSString *deduction = product.deduction;
    if (![deduction isEqualToString:@"k.A."]) {
      deductionLabel.text = deduction;
    }
    [cell.contentView addSubview:deductionLabel];
    // category
    UILabel *categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        176.0, 45.0, 190.0, 16.0)];
    categoryLabel.font = [UIFont systemFontOfSize:12.0];
    categoryLabel.textAlignment = kTextAlignmentLeft;
    categoryLabel.textColor = [UIColor grayColor];
    categoryLabel.text = product.category;
    [cell.contentView addSubview:categoryLabel];
    // ean
    UILabel *eanLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        70.0, 62.0, 110.0, 16.0)];
    eanLabel.font = [UIFont systemFontOfSize:12.0];
    eanLabel.textAlignment = kTextAlignmentLeft;
    eanLabel.textColor = [UIColor grayColor];
    eanLabel.text = product.ean;
    [cell.contentView addSubview:eanLabel];
    // expires_at
    UILabel *expiresAtLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        175.0, 62.0, 100.0, 16.0)];
    expiresAtLabel.textAlignment = kTextAlignmentLeft;
    expiresAtLabel.tag = 7;
    if (product.expiresAt && [product.expiresAt length] != 0) {
      expiresAtLabel.text = product.expiresAt;
      expiresAtLabel.font = [UIFont boldSystemFontOfSize:12.0];
      // comparison for color
      NSDate *current = [NSDate date];
      NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
      [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
      [dateFormat setDateFormat:@"dd.MM.yyyy HH:mm:ss"];
      NSDate *expiresAt = [dateFormat
        dateFromString:[NSString stringWithFormat:
                        @"01.%@ 02:00:00", product.expiresAt]];
      if ([current compare:expiresAt] == NSOrderedDescending) {
        // current date is already later than expiration date
        expiresAtLabel.textColor = [UIColor redColor];
      } else {
        expiresAtLabel.textColor = [UIColor greenColor];
      }
    } else {
      expiresAtLabel.text = @"+ EXP; Verfalldatum";
      expiresAtLabel.font = [UIFont systemFontOfSize:9.0];
      expiresAtLabel.textColor = [UIColor grayColor];
    }
    [cell.contentView addSubview:expiresAtLabel];
  }
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView
  canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (self.search.active) {
    return NO;
  } else {
    return YES;
  }
}

- (void)tableView:(UITableView *)tableView
  commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
   forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([self currentSegmentedType] == kSegmentReceipt) {
      // TODO remove signature
      //Receipt *receipt = [[ReceiptManager sharedManager]
      //  receiptAtIndex:indexPath.row];
      //NSError *error;
      //[fileManager removeItemAtPath:barcodePath error:&error];
      ReceiptManager* manager = [ReceiptManager sharedManager];
      [manager removeReceiptAtIndex:indexPath.row];
    } else { // product
      Product *product = [[ProductManager sharedManager]
        productAtIndex:indexPath.row];
      NSString *barcodePath = product.barcode;
      NSError *error;

      [fileManager removeItemAtPath:barcodePath error:&error];
      ProductManager* manager = [ProductManager sharedManager];
      [manager removeProductAtIndex:indexPath.row];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self refresh];
  } else {
    [self setEditing:NO animated:YES];
  }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  [super setEditing:editing animated:animated];
  [self.itemsView setEditing:editing animated:animated];
  UIView *titleView = self.navigationItem.titleView;
  UISegmentedControl *control = (UISegmentedControl *)[
    titleView viewWithTag:kSegmentedControlTag];
  // toolbar: space, interaction, space, settings, space
  UIBarButtonItem *interactionItem = [self.toolbarItems objectAtIndex:1];
  UIBarButtonItem *settingsItem = [self.toolbarItems objectAtIndex:3];
  UIButton *interactionButton = (UIButton *)interactionItem.customView;
  UIButton *settingsButton = (UIButton *)settingsItem.customView;
  if (editing) {
    control.userInteractionEnabled = NO;
    control.tintColor = [UIColor grayColor];
    control.alpha = 0.5;

    [self setBarButton:settingsButton enabled:NO];

    self.navigationItem.rightBarButtonItem.enabled = NO;

    if ([self currentSegmentedType] == kSegmentProduct) {
      UIButton *scanButton = [self.navigationItem.rightBarButtonItem
                              customView];
      [scanButton setTitleColor:[UIColor grayColor]
                       forState:UIControlStateDisabled];
      scanButton.alpha = 0.5;
      [self setBarButton:interactionButton enabled:NO];
    }
  } else {
    control.userInteractionEnabled = YES;
    control.tintColor = [Constant activeUIColor];
    control.alpha = 1.0;

    [self setBarButton:settingsButton enabled:YES];

    self.navigationItem.rightBarButtonItem.enabled = YES;

    if ([self currentSegmentedType] == kSegmentProduct) {
      UIButton *scanButton = [self.navigationItem.rightBarButtonItem
                              customView];
      [scanButton setTitleColor:[Constant activeUIColor]
                       forState:UIControlStateNormal];
      scanButton.alpha = 1.0;
      [self setBarButton:interactionButton enabled:YES];
    }
  }
}

- (BOOL)tableView:(UITableView *)tableView
  canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (self.search.active) {
    return NO;
  } else {
    return YES;
  }
}

- (void)tableView:(UITableView *)tableView
  moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
         toIndexPath:(NSIndexPath *)toIndexPath
{
  if (fromIndexPath.section == toIndexPath.section) {
    if ([self currentSegmentedType] == kSegmentReceipt) {
      ReceiptManager *manager = [ReceiptManager sharedManager];
      if (manager.receipts && toIndexPath.row < [manager.receipts count]) {
        [manager moveReceiptAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
      }
    } else { // product (default)
      ProductManager *manager = [ProductManager sharedManager];
      if (manager.products && toIndexPath.row < [manager.products count]) {
        [manager moveProductAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
      }
    }
  }
}

- (void)tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([self currentSegmentedType] == kSegmentReceipt) {
    Receipt *receipt;
    if (self.search.active) {
      receipt = [self.filtered objectAtIndex:indexPath.row];
    } else {
      receipt = [[ReceiptManager sharedManager] receiptAtIndex:indexPath.row];
    }
    [self displayInfoForReceipt:receipt animated:YES];
  } else {  // product (default)
    Product *product;
    if (self.search.active) {
      product = [self.filtered objectAtIndex:indexPath.row];
    } else {
      product = [[ProductManager sharedManager] productAtIndex:indexPath.row];
    }
    self.navigationItem.rightBarButtonItem.enabled = YES;
    // open oddb.org
    [self searchInfoForProduct:product];
  }
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView
  didDeselectRowAtIndexPath: (NSIndexPath *)indexPath
{
  self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)refresh
{
  [self.itemsView reloadData];
}

# pragma mark - Gesture

- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
  if (gesture.state == UIGestureRecognizerStateBegan) {
    UITableViewCell *cell = (UITableViewCell *)[gesture view];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    self.pickerIndexPath = indexPath;

    if (!self.datePicker) {
      self.datePicker = [[NTMonthYearPicker alloc] initWithFrame:CGRectMake(
          0, 0, 300, 140)];
      self.datePicker.hidden = NO;
    }
    Product *product;
    if (self.search.active) {
      product = [self.filtered objectAtIndex:indexPath.row];
    } else {
      product = [[ProductManager sharedManager] productAtIndex:indexPath.row];
    }
    // for min value
    NSCalendar *calendar = [[NSCalendar alloc]
      initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *currentDate = [NSDate date];
    NSDateComponents *dateComponents = [calendar components:(
        NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
			  fromDate:currentDate];
    // set 01.01.2017 as minimum date
    [dateComponents setYear:-(dateComponents.year - 2017)];
    [dateComponents setMonth:-(dateComponents.month - 1)];
    [dateComponents setDay:-(dateComponents.day - 1)];
    NSDate *minDate = [calendar dateByAddingComponents:dateComponents
                                                toDate:currentDate
                                               options:0];
    [self.datePicker setMinimumDate:minDate];
    // set date as initial value
    if (product.expiresAt && [product.expiresAt length] != 0) {
      NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
      [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
      [dateFormat setDateFormat:@"dd.MM.yyyy HH:mm:ss"];
      NSDate *expiresAt = [dateFormat dateFromString:[NSString
        stringWithFormat:@"01.%@ 00:00:00", product.expiresAt]];
      self.datePicker.date = expiresAt;
    } else {
      self.datePicker.date = currentDate;
    }

    [self.datePicker addTarget:self
                        action:@selector(changeDate:)
              forControlEvents:UIControlEventValueChanged];
    UIView *viewForDatePicker = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, 300, 140)];
    [viewForDatePicker addSubview:self.datePicker];
    UIViewController *viewController = [[UIViewController alloc] init];
    [viewController.view addSubview:viewForDatePicker];

    self.popOverForDatePicker = [[UIPopoverController alloc]
      initWithContentViewController:viewController];
    [self.popOverForDatePicker
      setPopoverContentSize:CGSizeMake(300, 140)
                   animated:NO];
    [self.popOverForDatePicker
      presentPopoverFromRect:cell.frame
                      inView:self.view
    permittedArrowDirections:(
        UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown)
                    animated:YES];
  }
}

- (void)changeDate:(id)sender
{
  NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
  [dateFormat setDateFormat:@"MM.YYYY"];
  NSString *value = [NSString stringWithFormat:@"%@",
    [dateFormat stringFromDate:self.datePicker.date]];

  if (self.popOverForDatePicker) {
    NSIndexPath *indexPath = self.pickerIndexPath;
    UITableViewCell *cell = [self.itemsView
                             cellForRowAtIndexPath:indexPath];
    if (cell) {
      ProductManager *manager = [ProductManager sharedManager];
      Product *product;
      if (self.search.active) {
	      product = [self.filtered objectAtIndex:indexPath.row];
      } else {
	      product = [manager productAtIndex:indexPath.row];
      }
      if (value && [value length] != 0) {
        product.expiresAt = value;
        [manager save];

        // expires_at
        UILabel *expiresAtLabel = [cell.contentView viewWithTag:7];
              expiresAtLabel.font = [UIFont boldSystemFontOfSize:12.0];
        expiresAtLabel.textAlignment = kTextAlignmentLeft;
        expiresAtLabel.text = value;
      }
    }
  }
}

# pragma mark - Searchbar

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
  [self setEditing:NO animated:YES];
}

- (void)filterContentForSearchText:(NSString *)searchText
                             scope:(NSString *)scope
{
  [self.filtered removeAllObjects];

  if ([self currentSegmentedType] == kSegmentReceipt) {
    // receipt - placeDate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
      @"%K contains[cd] %@", @"placeDate", searchText];
    self.filtered = [NSMutableArray arrayWithArray:[
      [ReceiptManager sharedManager].receipts
        filteredArrayUsingPredicate:predicate]];
  } else {
    // product - name
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
      @"%K contains[cd] %@", @"name", searchText];
    self.filtered = [NSMutableArray arrayWithArray:[
      [ProductManager sharedManager].products
        filteredArrayUsingPredicate:predicate]];
  }
}

# pragma mark - Search Results

- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController
{
  NSString *searchString = searchController.searchBar.text;
  [self filterContentForSearchText:searchString
                             scope:[[self.search.searchBar scopeButtonTitles]
                     objectAtIndex:
    [self.search.searchBar selectedScopeButtonIndex]]];
  [self refresh];
}

# pragma mark - File Importing

- (void)setSelectedSegmentIndex:(NSInteger)index
{
  _selectedSegmentIndex = index;

  // invoke `segmentChanged:control` manually
  if (self.navigationItem && self.navigationItem.titleView) {
    UIView *titleView = self.navigationItem.titleView;
    UISegmentedControl *control = (UISegmentedControl *)[
      titleView viewWithTag:kSegmentedControlTag];
    control.selectedSegmentIndex = _selectedSegmentIndex;
    [self segmentChanged:control];
  }
}

- (void)handleOpenAmkFileURL:(NSURL *)url animated:(BOOL)animated
{
  [self setSelectedSegmentIndex:(NSInteger)kSegmentReceipt];

  ReceiptManager *manager = [ReceiptManager sharedManager];
  Receipt *receipt;

  NSError *error;
  @try {
    receipt = [manager importReceiptFromURL:url];
    if (receipt == nil) {
      @throw [NSException exceptionWithName:@"Import Error"
                                     reason:@"Invalid keys or values"
                                   userInfo:nil];
    } else if ([receipt isEqual:[NSNull null]]) {
      error = [NSError errorWithDomain:@"receipt"
                                  code:99
                              userInfo:@{
             NSLocalizedDescriptionKey:@"Already imported"
                              }];
    }
  }
  @catch (NSException *exception) {
    error = [NSError errorWithDomain:@"receipt"
                                code:100
                            userInfo:@{
           NSLocalizedDescriptionKey:@"Invalid .amk file"
                            }];
  }
  if (error) {
    UIAlertView *alert = [[UIAlertView alloc]
        initWithTitle:[error localizedDescription]
              message:nil
             delegate:self
    cancelButtonTitle:@"OK"
    otherButtonTitles:nil];
    [alert show];
    return;
  }
  BOOL saved = [manager insertReceipt:receipt atIndex:0];
  if (saved) {
    [self displayInfoForReceipt:receipt animated:animated];
  }
}

@end
