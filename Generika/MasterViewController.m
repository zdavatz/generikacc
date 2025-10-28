//
//  MasterViewController.m
//  Generika
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import "Reachability.h"
#import "UIColorBackport.h"

#import "NTMonthYearPicker.h"
#import "UIPopoverController+iPhone.h"

#import "Product.h"
#import "ProductManager.h"

#import "Receipt.h"
#import "ReceiptManager.h"

#import "WebViewController.h"
#import "SettingsViewController.h"
#import "ReceiptViewController.h"
#import "ReceiptUsageViewController.h"
#import "ScannerViewController.h"
#import "MasterViewController.h"
#import "VisionKit/VisionKit.h"
#import "MessageUI/MessageUI.h"

#import "AmikoDatabase/AmikoDBManager.h"
#import "AmikoDatabase/AmikoDBPriceComparison.h"
#import "PriceComparisonViewController.h"
#import "PatinfoViewController.h"

static const float kCellHeight = 83.0;
static const int kSegmentedControlTag = 100;
static const int kSegmentProduct = 0;
static const int kSegmentReceipt = 1;

#define kPaperSizeA4 CGSizeMake(595.2,841.8)

@interface MasterViewController () <ScannerViewControllerDelegate, VNDocumentCameraViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong, readwrite) Reachability *reachability;
@property (nonatomic, strong, readwrite) NSMutableArray *filtered;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) UITableView *itemsView;
@property (nonatomic, strong, readwrite) UISearchController *search;
@property (nonatomic, strong, readwrite) WebViewController *browser;
@property (nonatomic, strong, readwrite) SettingsViewController *settings;
@property (nonatomic, strong, readwrite) ReceiptViewController *viewer;
@property (nonatomic, strong, readwrite) ReceiptUsageViewController *usage;
@property (nonatomic, assign, readwrite) NSInteger selectedSegmentIndex;
// reader
@property (nonatomic, strong, readwrite) ReaderViewController *reader;
// file import
@property (nonatomic, strong, readwrite)
  //UIDocumentMenuViewController *documentPicker;
  UIDocumentPickerViewController *documentPicker;
// datepicker
@property (nonatomic, strong, readwrite) NSIndexPath *pickerIndexPath;
@property (nonatomic, strong, readwrite) NTMonthYearPicker *datePicker;
@property (nonatomic, strong, readwrite)
  UIPopoverController *popOverForDatePicker;

- (void)segmentChanged:(UISegmentedControl *)control;
- (void)layoutSearchbar;
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
    _viewer = nil;
    _usage = nil;
    _settings = nil;
    _documentPicker = nil;
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
  UIView *backgroundView = [[UIView alloc] init];
  backgroundView.backgroundColor = [UIColorBackport systemBackgroundColor];
  self.itemsView.backgroundView = backgroundView;
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
  segmentedControl.tintColor = [Helper activeUIColor];
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
    self.navigationItem.rightBarButtonItems = [self buildScanButtonItems];
  // toolbar
  [self layoutToolbar];

  // search
  [self layoutSearchbar];

  self.definesPresentationContext = YES;
  self.extendedLayoutIncludesOpaqueBars = NO;

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
  [self layoutToolbar];

  [self refresh];
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [self.itemsView flashScrollIndicators];
  [super viewDidAppear:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(
           id<UIViewControllerTransitionCoordinator>)coordinator {
  // fix wrong serchbar position at back from landscape mode
  // see also positionForBar of <UIBarPositioningDelegate>
  [self.search dismissViewControllerAnimated:YES completion:nil];
  for (int i = 0; i < [[self.search.searchBar subviews] count]; i++) {
    UIView *subView = [[self.search.searchBar subviews] objectAtIndex:i];
    if ([[NSString stringWithFormat:@"%@", [subView class]]
         isEqualToString:@"UINavigationButton"]) {
        UIButton *cancelButton = (UIButton *)subView;
        cancelButton.enabled = YES;
    }
  }
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
  // fix for iPhone X landscape
  [self layoutToolbar];

  // redraw via reload
  [self.itemsView performSelectorOnMainThread:@selector(reloadData)
                                   withObject:nil
                                waitUntilDone:YES];
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
  [self layoutToolbar];
  [super willRotateToInterfaceOrientation:orient
                                 duration:duration];
}


#pragma mark - Components

- (NSArray<UIBarButtonItem *> *)buildScanButtonItems
{
    UIButton *scanButton = [UIButton buttonWithType:UIButtonTypeCustom];
    scanButton.frame = CGRectMake(0, 0, 20, 20);
    UIFont *scanFont = [UIFont fontWithName:@"FontAwesome" size:19.0];
    [scanButton.titleLabel setFont:scanFont];
    // FIXME: right margin
    [scanButton setTitle:@"  \uF030" forState:UIControlStateNormal];
    [scanButton setTitleColor:[Helper activeUIColor]
                     forState:UIControlStateNormal];
    [scanButton addTarget:self
                   action:@selector(scanButtonTapped:)
         forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *scanButtonItem = [[UIBarButtonItem alloc]
      initWithCustomView:scanButton];
    scanButtonItem.width = 26;
    
    UIBarButtonItem *scanDocumentItem = [[UIBarButtonItem alloc] init];
    [scanDocumentItem setImage:[UIImage systemImageNamed:@"doc.text.magnifyingglass"]];
    [scanDocumentItem setTitle:@"Scan Doc"];
    [scanDocumentItem setTarget:self];
    [scanDocumentItem setAction:@selector(scanDocumentButtonTapped:)];
    
    return @[scanButtonItem, scanDocumentItem];
}

- (UIBarButtonItem *)buildPlusButtonItem
{
  UIBarButtonItem *plusButtonItem = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                         target:self
                         action:@selector(plusButtonTapped:)];
  return plusButtonItem;
}


#pragma mark - Layout

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
    if (self == self.navigationController.topViewController) {
        [self.navigationController setToolbarHidden:NO animated:NO];
    }

  UIButton *settingsButton;
  if ([self currentSegmentedType] == kSegmentReceipt) {
    // disable
    UIBarButtonItem *settingsItem = [self.toolbarItems objectAtIndex:3];
    settingsButton = (UIButton *)settingsItem.customView;
    settingsButton.enabled = NO;
    settingsButton.hidden = YES;
  } else {
    settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    // wheel icon button
    settingsButton.frame = CGRectMake(0, 0, 40, 40);
    UIFont *settingsFont = [UIFont fontWithName:@"FontAwesome" size:22.0];
    [settingsButton.titleLabel setFont:settingsFont];
    [settingsButton setTitle:@"\uF013" forState:UIControlStateNormal];
    [self setBarButton:settingsButton enabled:YES];
    [settingsButton addTarget:self
                       action:@selector(settingsButtonTapped:)
             forControlEvents:UIControlEventTouchUpInside];
  }
  // (balance|help) link button
  UIButton *utilButton = [UIButton buttonWithType:UIButtonTypeCustom];
  utilButton.frame = CGRectMake(0, 0, 120, 40);

  UIFont *utilFont = [UIFont fontWithName:@"FontAwesome" size:18.0];
  [utilButton.titleLabel setFont:utilFont];
  if ([self currentSegmentedType] == kSegmentReceipt) { // receipt
    // info icon (default)
    [utilButton setTitle:@"\uF129" forState:UIControlStateNormal];
  } else { // product
    // balance-scale icon (default)
    [utilButton setTitle:@"\uF24e" forState:UIControlStateNormal];
  }

  [self setBarButton:utilButton enabled:YES];
  [utilButton addTarget:self
                        action:@selector(utilButtonTapped:)
              forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *utilBarButton = [[UIBarButtonItem alloc]
    initWithCustomView:utilButton];

  UIBarButtonItem *space = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                         target:nil
                         action:nil];
  UIBarButtonItem *lMargin = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                         target:nil
                         action:nil];
  lMargin.width = -48;
  if (isLandscape && @available(iOS 11, *)) {  // fix iPhone X landscape mode
    if ([UIDevice currentDevice].userInterfaceIdiom == \
          UIUserInterfaceIdiomPhone &&
        UIScreen.mainScreen.nativeBounds.size.height == 2436) {
      lMargin.width -= 48;
    }
  }
  UIBarButtonItem *rMargin = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                         target:nil
                         action:nil];
  rMargin.width = -9;
  UIBarButtonItem *settingsBarButton = [[UIBarButtonItem alloc]
    initWithCustomView:settingsButton];
  self.toolbarItems = [NSArray arrayWithObjects:
    lMargin, utilBarButton, space, settingsBarButton, rMargin, nil];
}

- (void)layoutSearchbar
{
  self.search = [[UISearchController alloc]
                 initWithSearchResultsController:nil];
  // searchbar
  self.search.searchBar.tintColor = [UIColor lightGrayColor];
  self.search.searchBar.delegate = self;
  self.search.searchBar.placeholder = @"Suchen";
  self.search.searchBar.translucent = NO;
  // fix wrong position (fixed position)
  [self.search.searchBar sizeToFit];
  self.itemsView.tableHeaderView = self.search.searchBar;

  self.search.searchResultsUpdater = self;
  self.search.delegate = self;
  self.search.dimsBackgroundDuringPresentation = NO;
  self.search.hidesNavigationBarDuringPresentation = NO;
}

- (void)setBarButton:(UIButton *)button enabled:(BOOL)enabled
{
  if (enabled) {
    if (floor(NSFoundationVersionNumber) <= kVersionNumber_iOS_6_1) {
      [button setTitleColor:[UIColor whiteColor]
                   forState:UIControlStateNormal];
    } else { // iOS 7 or later
      [button setTitleColor:[Helper activeUIColor]
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


#pragma mark - Segmented Control

- (void)segmentChanged:(UISegmentedControl *)control
{
  [self setEditing:NO animated:YES]; // tableview
  if (self.search) { // cancel search
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [self.search setActive:NO];
  }

  // toolbar: space, util(interaction|help), space, settings, space
  UIBarButtonItem *utilItem = [self.toolbarItems objectAtIndex:1];
  UIButton *utilButton = (UIButton *)utilItem.customView;

  UIBarButtonItem *settingsItem = [self.toolbarItems objectAtIndex:3];
  UIButton *settingsButton = (UIButton *)settingsItem.customView;

  if (control.selectedSegmentIndex == kSegmentReceipt) {
    // navigationbar
    // change button camera -> plus
    UIBarButtonItem *plusButtonItem = [self buildPlusButtonItem];
    self.navigationItem.rightBarButtonItems = @[plusButtonItem];
    // toolbar
    // info icon
    [utilButton setTitle:@"\uF129" forState:UIControlStateNormal];
    settingsButton.hidden = YES;
  } else { // product (default)
    // navigationbar
    // change button plus -> camera

      self.navigationItem.rightBarButtonItems = [self buildScanButtonItems];
    // toolbar
    // balance-scale icon (default)
    [utilButton setTitle:@"\uF24e" forState:UIControlStateNormal];
    settingsButton.hidden = NO;
  }
  _filtered = nil;
  [self refresh];
}


#pragma mark - Util Link

- (void)utilButtonTapped:(UIButton *)button
{
  if (!self.editing) {
    if ([self currentSegmentedType] == kSegmentReceipt) { // receipt
      if (!self.usage) {
        self.usage = [[ReceiptUsageViewController alloc] init];
      }
      if (!self.usage.isViewLoaded || !self.usage.view.window) {
        self.usage.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        UINavigationController *usageNavigation = [
          [UINavigationController alloc]
            initWithRootViewController:self.usage];
        [self presentViewController:usageNavigation
                           animated:YES
                         completion:nil];
      }
    } else { // product
      // open in safari
      NSInteger selectedLangIndex = [self.userDefaults
                                     integerForKey:@"search.result.lang"];
      NSString *lang = [[Constant searchLangs]
                        objectAtIndex:selectedLangIndex];
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
          @"%@/%@/generika/home_interactions/%@", kOddbBaseURL, lang, productEANs];
          NSURL *urlToOpen = [NSURL URLWithString:url];

          if (urlToOpen) {
              [[UIApplication sharedApplication] openURL:urlToOpen
                                                 options:@{}
                                       completionHandler:^(BOOL success) {
                  if (success) {
                      NSLog(@"Successfully opened the URL.");
                  } else {
                      NSLog(@"Failed to open the URL.");
                  }
              }];
          }
      }
    }
  }
}


#pragma mark - Settings View

- (void)settingsButtonTapped:(UIButton *)button
{
  if (!self.editing) {
    UIBarButtonItem *settingsItem = [self.toolbarItems objectAtIndex:3];
    UIButton *settingsButton = (UIButton *)settingsItem.customView;
    if (settingsButton.hidden) {
      return;
    }
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
    initWithRootViewController:self.settings];
  [self presentViewController:settingsNavigation animated:YES completion:nil];
}


#pragma mark - Plus View

- (void)plusButtonTapped:(UIButton *)button
{
  if (!self.editing) {
    [self openImporter];
  }
}

- (void)openImporter
{
  self.documentPicker = [[UIDocumentPickerViewController alloc]
    initWithDocumentTypes:@[@"org.oddb.generika.amk"]
                   inMode:UIDocumentPickerModeImport];
  self.documentPicker.delegate = self;
  self.documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
  [self presentViewController:self.documentPicker animated:YES completion:nil];
}


#pragma mark - Scan View

- (void)scanButtonTapped:(UIButton *)button
{
  if (!self.editing) {
    [self openReader];
  }
}

- (void)scannerViewController:(id)sender didScannedEan13:(NSString *)ean withImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(),^{
        [self didScanProductWithEan:ean
                          expiresAt:nil
                          lotNumber:nil
                              image:image];
        [sender dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)scannerViewController:(id)sender didScannedDataMatrix:(DataMatrixResult *)result withImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(),^{
        [self didScanProductWithEan:result.gtin
                          expiresAt:result.expiryDate
                          lotNumber:result.batchOrLotNumber
                              image:image];
        [sender dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)scannerViewController:(id)sender
             didEPrescription:(EPrescription *)result
                    withImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        [sender dismissViewControllerAnimated:YES completion:^{
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH.mm.ss";
            [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
            NSString *amkFilename = [NSString stringWithFormat:@"RZ_%@.amk", [dateFormatter stringFromDate:[NSDate date]]];
            Receipt *r = [[ReceiptManager sharedManager] importReceiptFromAMKDict:[result amkDict] fileName:amkFilename];
            BOOL saved = [[ReceiptManager sharedManager] insertReceipt:r atIndex:0];
            NSDictionary *keychainDict = [[SettingsManager shared] getDictFromKeychainCached:false];
            if (!keychainDict) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                               message:@"ZSR und ZR-Kundennummer nicht abrufbar"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }
            if (![(NSString*)keychainDict[KEYCHAIN_KEY_ZSR] length] || ![(NSString*)keychainDict[KEYCHAIN_KEY_ZR_CUSTOMER_NUMBER] length]) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                               message:NSLocalizedString(@"Bitte in den Einstellungen die ZR Kundennummer ausfüllen", @"") preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                return;
            }
            UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Senden an ZurRose?", @"")
                                                                                message:nil
                                                                         preferredStyle:UIAlertControllerStyleAlert];
            [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Senden", @"")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                ZurRosePrescription *p = [result toZurRosePrescriptionWithKeychainDict:keychainDict];
                [p sendToZurRoseWithCompletion:^(NSHTTPURLResponse * _Nonnull res, NSError * _Nonnull error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error || res.statusCode != 200) {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                                           message:[error localizedDescription] ?: [NSString stringWithFormat:NSLocalizedString(@"Error Code: %ld", @""), res.statusCode]
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:nil]];
                            [self presentViewController:alert animated:YES completion:nil];
                        } else {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                                           message:NSLocalizedString(@"Rezept wurde an ZurRose übermittelt.", @"")
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                      style:UIAlertActionStyleDefault
                                                                    handler:nil]];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    });
                }];
            }]];
            [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Abbrechen", @"")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil]];
            [self presentViewController:controller animated:YES completion:nil];
        }];
    });
}

- (void)didScanProductWithEan:(NSString *)ean
                    expiresAt:(NSString *)expiresAt
                    lotNumber:(NSString *)lotNumber
                        image:(UIImage *)image {
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
  NSInteger selectedTypeIndex = [self.userDefaults
    integerForKey:@"search.result.type"];
  NSString *type = [[Constant searchTypes] objectAtIndex:selectedTypeIndex];
  if ([ean length] != 13) {
    [self notFoundEan:ean];
  } else {
    // API Request
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
           [self didFinishPicking:responseObject withEan:ean expiresAt:expiresAt lotNumber:lotNumber barcode:image];
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
}

- (void)didFinishPicking:(id)json
                 withEan:(NSString *)ean
               expiresAt:(NSString *)expiresAt
               lotNumber:(NSString *)lotNumber
                 barcode:(UIImage *)barcode
{
  if (json == nil || [(NSArray *)json count] == 0) {
    [self notFoundEan:ean];
  } else {
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm dd.MM.YYYY"];
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
    [product setValue:expiresAt ?: @"" forKey:@"expiresAt"];
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
      @"%@, %@\n%@\n%@", product.name, lotNumber ?: @"", product.size, publicPrice];
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
    ScannerViewController *scannerViewController = [[ScannerViewController alloc] init];
    scannerViewController.delegate = self;
    [self presentViewController:scannerViewController
                       animated:YES
                     completion:nil];
}

- (void)scanDocumentButtonTapped:(id)sender
{
    VNDocumentCameraViewController* documentCameraViewController = [[VNDocumentCameraViewController alloc] init];
    documentCameraViewController.delegate = self;
    [self presentViewController:documentCameraViewController animated:YES completion:nil];
}

- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller didFinishWithScan:(VNDocumentCameraScan *)scan {
    if (![scan pageCount]) return;
    
    NSMutableData *pdfData = [NSMutableData data];
    UIGraphicsBeginPDFContextToData(pdfData, CGRectMake(0, 0, kPaperSizeA4.width, kPaperSizeA4.height), nil);

    for (int i = 0; i < [scan pageCount]; i++) {
        UIImage *image = [scan imageOfPageAtIndex:i];
        CGFloat scale = MIN(kPaperSizeA4.width/image.size.width, kPaperSizeA4.height / image.size.height);
        CGRect rect = CGRectMake((kPaperSizeA4.width - image.size.width * scale)/2,
                                 (kPaperSizeA4.height - image.size.height * scale)/2,
                                 image.size.width * scale,
                                 image.size.height * scale);
        
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, kPaperSizeA4.width, kPaperSizeA4.height), nil);
        [image drawInRect:rect];
    }
    UIGraphicsEndPDFContext();

    [controller dismissModalViewControllerAnimated:YES];
    
    NSDictionary *keychainDict = [[SettingsManager shared] getDictFromKeychainCached:false];
    if (!keychainDict) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                       message:@"ZSR und ZR-Kundennummer nicht abrufbar"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
    [mailVC setSubject:[NSString stringWithFormat:@"ZSR: %@, GLN: %@, ZR-Kundennummer: %@",
                        keychainDict[KEYCHAIN_KEY_ZSR],
                        [[NSUserDefaults standardUserDefaults] stringForKey:@"profile.gln"],
                        keychainDict[KEYCHAIN_KEY_ZR_CUSTOMER_NUMBER]
                       ]];
    [mailVC setToRecipients:@[@"servicecare@zurrose.ch"]];
    NSString *timestamp = [NSISO8601DateFormatter stringFromDate:[NSDate date]
                                                        timeZone:[NSTimeZone systemTimeZone]
                                                   formatOptions:NSISO8601DateFormatWithYear | NSISO8601DateFormatWithMonth | NSISO8601DateFormatWithDay | NSISO8601DateFormatWithTime];
    NSString *filename = [NSString stringWithFormat:@"%@_%@.pdf", keychainDict[KEYCHAIN_KEY_ZR_CUSTOMER_NUMBER], timestamp];
    [mailVC addAttachmentData:pdfData mimeType:@"application/pdf" fileName:filename];
    [mailVC setMailComposeDelegate:self];
    [self presentViewController:mailVC animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error {
    [controller dismissModalViewControllerAnimated:YES];
}


#pragma mark - Product

- (void)searchInfoForProduct:(Product *)product
{
  NSInteger selectedTypeIndex = [self.userDefaults integerForKey:
    @"search.result.type"];
  NSString *type = [[Constant searchTypes] objectAtIndex:selectedTypeIndex];
  NSInteger selectedLangIndex = [self.userDefaults integerForKey:
    @"search.result.lang"];
  NSString *lang = [[Constant searchLangs] objectAtIndex:selectedLangIndex];
    NSString *url = nil;
  if ([type isEqualToString:@"Preisvergleich"]) {
      NSArray<AmikoDBPriceComparison*> *comparisons = [AmikoDBPriceComparison comparePrice:product.ean];
      if (![comparisons count]) {
          url = [NSString stringWithFormat:@"%@/%@/generika/compare/ean13/%@",
                 kOddbBaseURL, lang, product.ean];
      } else {
          PriceComparisonViewController *comparisonController = [[PriceComparisonViewController alloc] init];
          comparisonController.comparisons = comparisons;
          
          [self.navigationController pushViewController:comparisonController
                                               animated:YES];
      }
  } else if ([type isEqualToString:@"PI"]) {
      NSArray<AmikoDBRow *> *rows = [[AmikoDBManager shared] findWithGtin:product.ean];
      if ([rows count]) {
          PatinfoViewController *controller = [[PatinfoViewController alloc] initWithRow:rows.firstObject];
          [self.navigationController pushViewController:controller animated:YES];
      } else {
          url = [NSString stringWithFormat:@"%@/%@/generika/patinfo/reg/%@/seq/%@",
                 kOddbBaseURL, lang, product.reg, product.seq];
      }
  } else if ([type isEqualToString:@"FI"]) {
    url = [NSString stringWithFormat:@"%@/%@/generika/fachinfo/reg/%@",
           kOddbBaseURL, lang, product.reg];
  }
    if (url) {
        [self openWebViewWithURL:[NSURL URLWithString:url]];
    }
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


#pragma mark - Receipt

- (void)displayInfoForReceipt:(Receipt *)receipt animated:(BOOL)animated
{
  // If animated is NO (at boot), This generates `Unbalanced calls to
  // begin/end appearance transitions for ...`. But, it's trivial matter,
  // here :-D
  if (!self.viewer) {
    self.viewer = [[ReceiptViewController alloc] init];
  }
  [self.viewer loadReceipt:receipt];
  if (!self.viewer.isViewLoaded || !self.viewer.view.window) {
    [self.navigationController pushViewController:self.viewer
                                         animated:animated];
  }
}


#pragma mark - Table View

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
    // place date
    if (![receipt.placeDate isEqualToString:@""]) {
      UILabel *placeDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        7.2, 8.0, itemView.frame.size.width - 22.0, 14.0)];
      placeDateLabel.font = [UIFont boldSystemFontOfSize:13.0];
      placeDateLabel.textAlignment = kTextAlignmentLeft;
      placeDateLabel.textColor = [UIColorBackport labelColor];
      placeDateLabel.backgroundColor = [UIColor clearColor];
      placeDateLabel.text = receipt.placeDate;
      [cell.contentView addSubview:placeDateLabel];
    }

    Operator *operator = receipt.operator;
    CGFloat width = CGRectGetMaxX(tableView.frame) -
      CGRectGetMinX(tableView.frame);
    CGFloat labelWidth = (width / 2) - 30.2;
    if (operator) {
      // title + given_name + family_name
      UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        7.2, 26.5, labelWidth, 14.0)];
      if (isLandscape) {
        CGRect nameFrame = nameLabel.frame;
        nameFrame.size.width = 222.0;
        [nameLabel setFrame:nameFrame];
      }
      nameLabel.font = [UIFont systemFontOfSize:11.5];
      nameLabel.textAlignment = kTextAlignmentLeft;
      nameLabel.textColor = [UIColorBackport labelColor];
      nameLabel.backgroundColor = [UIColor clearColor];
      nameLabel.text = [NSString stringWithFormat:@"%@ %@",
        operator.givenName, operator.familyName, nil];
      if (![operator.title isEqualToString:@""]) {
        nameLabel.text = [operator.title stringByAppendingString:[
          NSString stringWithFormat:@" %@", nameLabel.text]];
      }
      [cell.contentView addSubview:nameLabel];
      // phone
      UILabel *phoneLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        7.2, 44.5, labelWidth, 14.0)];
      if (isLandscape) {
        CGRect phoneFrame = phoneLabel.frame;
        phoneFrame.size.width = 222.0;
        [phoneLabel setFrame:phoneFrame];
      }
      phoneLabel.font = [UIFont systemFontOfSize:11.5];
      phoneLabel.textAlignment = kTextAlignmentLeft;
      phoneLabel.textColor = [UIColorBackport labelColor];
      phoneLabel.backgroundColor = [UIColor clearColor];
      phoneLabel.text = operator.phone;
      [cell.contentView addSubview:phoneLabel];
      // email
      UILabel *emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        7.2, 61.0, labelWidth, 14.0)];
      if (isLandscape) {
        CGRect emailFrame = emailLabel.frame;
        emailFrame.size.width = 222.0;
        [emailLabel setFrame:emailFrame];
      }
      emailLabel.font = [UIFont systemFontOfSize:11.5];
      emailLabel.textAlignment = kTextAlignmentLeft;
      emailLabel.textColor = [UIColorBackport labelColor];
      emailLabel.backgroundColor = [UIColor clearColor];
      emailLabel.text = operator.email;
      [cell.contentView addSubview:emailLabel];
    }
    // right side section
    // original filename
    if (![receipt.filename isEqualToString:@""]) {
      UILabel *filenameLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        labelWidth + 13.5, 27.0, labelWidth, 14.0)];
      if (isLandscape) {
        CGRect filenameFrame = filenameLabel.frame;
        filenameFrame.origin.x = 237.0;
        filenameFrame.size.width = 258.0;
        [filenameLabel setFrame:filenameFrame];
      }
      filenameLabel.font = [UIFont systemFontOfSize:10.5];
      filenameLabel.textAlignment = kTextAlignmentLeft;
      filenameLabel.textColor = [UIColorBackport secondaryLabelColor];
      filenameLabel.backgroundColor = [UIColor clearColor];
      filenameLabel.text = [receipt.filename lastPathComponent];
      [cell.contentView addSubview:filenameLabel];
    }
    // datetime (imported at)
    UILabel *datetimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(
      labelWidth + 13.5, 45.0, labelWidth, 14.0)];
    if (isLandscape) {
      CGRect datetimeFrame = datetimeLabel.frame;
      datetimeFrame.origin.x = 237.0;
      datetimeFrame.size.width = 258.0;
      [datetimeLabel setFrame:datetimeFrame];
    }
    datetimeLabel.font = [UIFont systemFontOfSize:10.5];
    datetimeLabel.textAlignment = kTextAlignmentLeft;
    datetimeLabel.textColor = [UIColorBackport secondaryLabelColor];
    datetimeLabel.backgroundColor = [UIColor clearColor];
    datetimeLabel.text = receipt.importedAt;
    [cell.contentView addSubview:datetimeLabel];
    // medications
    UILabel *productsLabel = [[UILabel alloc] initWithFrame:CGRectMake(
      labelWidth + 14.0, 61.0, labelWidth, 14.0)];
    if (isLandscape) {
      CGRect productsFrame = productsLabel.frame;
      productsFrame.origin.x = 237.0;
      productsFrame.size.width = 258.0;
      [productsLabel setFrame:productsFrame];
    }
    productsLabel.font = [UIFont systemFontOfSize:10.5];
    productsLabel.textAlignment = kTextAlignmentLeft;
    productsLabel.textColor = [UIColorBackport secondaryLabelColor];
    productsLabel.backgroundColor = [UIColor clearColor];
    NSInteger count = [receipt.products count];
    NSString *format = @"%d Medikamente";
    if (count < 2) {
      format = @"%d Medikament";
    }
    productsLabel.text = [NSString stringWithFormat:format, count, nil];
    [cell.contentView addSubview:productsLabel];
  } else {  // product
    // gesture
    UILongPressGestureRecognizer *longPressGesture;
    if (self.search.active) {
      // It does nothing (action: nil)
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
    nameLabel.textColor = [UIColorBackport labelColor];
    nameLabel.text = product.name;
    [cell.contentView addSubview:nameLabel];
    // size
    UILabel *sizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(
      70.0, 26.0, 110.0, 16.0)];
    sizeLabel.font = [UIFont boldSystemFontOfSize:12.0];
    sizeLabel.textAlignment = kTextAlignmentLeft;
    sizeLabel.textColor = [UIColorBackport labelColor];
    sizeLabel.text = product.size;
    [cell.contentView addSubview:sizeLabel];
    // datetime
    if (product.datetime) {
      UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        175.0, 27.0, 100.0, 16.0)];
      dateLabel.font = [UIFont systemFontOfSize:12.0];
      dateLabel.textAlignment = kTextAlignmentLeft;
      dateLabel.textColor = [UIColorBackport secondaryLabelColor];
      dateLabel.text = product.datetime;
      [cell.contentView addSubview:dateLabel];
    }
    // price
    UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(
      70.0, 45.0, 60.0, 16.0)];
    priceLabel.font = [UIFont systemFontOfSize:12.0];
    priceLabel.textAlignment = kTextAlignmentLeft;
    priceLabel.textColor = [UIColorBackport secondaryLabelColor];
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
    deductionLabel.textColor = [UIColorBackport secondaryLabelColor];
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
    categoryLabel.textColor = [UIColorBackport secondaryLabelColor];
    categoryLabel.text = product.category;
    [cell.contentView addSubview:categoryLabel];
    // ean
    UILabel *eanLabel = [[UILabel alloc] initWithFrame:CGRectMake(
      70.0, 62.0, 110.0, 16.0)];
    eanLabel.font = [UIFont systemFontOfSize:12.0];
    eanLabel.textAlignment = kTextAlignmentLeft;
    eanLabel.textColor = [UIColorBackport secondaryLabelColor];
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
        expiresAtLabel.textColor = [UIColorBackport systemRedColor];
      } else {
        expiresAtLabel.textColor = [UIColorBackport systemGreenColor];
      }
    } else {
      expiresAtLabel.text = @"+ EXP; Verfalldatum";
      expiresAtLabel.font = [UIFont systemFontOfSize:9.0];
      expiresAtLabel.textColor = [UIColorBackport secondaryLabelColor];
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
      Receipt *receipt = [[ReceiptManager sharedManager]
        receiptAtIndex:indexPath.row];
      NSString *amkfilePath = receipt.amkfile;
      NSError *error;
      [fileManager removeItemAtPath:amkfilePath error:&error];
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
  // toolbar: space, (interaction|help), space, settings, space
  UIBarButtonItem *utilItem = [self.toolbarItems objectAtIndex:1];
  UIBarButtonItem *settingsItem = [self.toolbarItems objectAtIndex:3];
  UIButton *utilButton = (UIButton *)utilItem.customView;
  UIButton *settingsButton = (UIButton *)settingsItem.customView;
  if (editing) {
    control.userInteractionEnabled = NO;
    control.tintColor = [UIColor grayColor];
    control.alpha = 0.5;

    [self setBarButton:settingsButton enabled:NO];
    [self setBarButton:utilButton enabled:NO];

    self.navigationItem.rightBarButtonItem.enabled = NO;
    if ([self currentSegmentedType] == kSegmentProduct) {
      UIButton *scanButton = [self.navigationItem.rightBarButtonItem
                              customView];
      [scanButton setTitleColor:[UIColor grayColor]
                       forState:UIControlStateDisabled];
      scanButton.alpha = 0.5;
    }
  } else {
    control.userInteractionEnabled = YES;
    control.tintColor = [Helper activeUIColor];
    control.alpha = 1.0;

    [self setBarButton:settingsButton enabled:YES];
    [self setBarButton:utilButton enabled:YES];

    self.navigationItem.rightBarButtonItem.enabled = YES;
    if ([self currentSegmentedType] == kSegmentProduct) {
      UIButton *scanButton = [self.navigationItem.rightBarButtonItem
                              customView];
      [scanButton setTitleColor:[Helper activeUIColor]
                       forState:UIControlStateNormal];
      scanButton.alpha = 1.0;
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


#pragma mark - Gesture

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


#pragma mark - Searchbar

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
  self.navigationItem.leftBarButtonItem.enabled = NO;
  [self setEditing:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
  self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)filterContentForSearchText:(NSString *)searchText
                             scope:(NSString *)scope
{
  if ([searchText length] < 2) {
    return;
  }
  [self.filtered removeAllObjects];

  if ([self currentSegmentedType] == kSegmentReceipt) {
    // receipt - placeDate
    NSPredicate *source0 = [NSPredicate predicateWithFormat:
      @"%K contains[cd] %@", @"placeDate", searchText];
    // receipt.operator - familyName
    NSPredicate *source1 = [NSPredicate predicateWithFormat:
      @"%K contains[cd] %@", @"operator.familyName", searchText];
    // receipt.operator - givenName
    NSPredicate *source2 = [NSPredicate predicateWithFormat:
      @"%K contains[cd] %@", @"operator.givenName", searchText];
    // receipt.operator - phone
    NSPredicate *source3 = [NSPredicate predicateWithFormat:
      @"%K contains[cd] %@", @"operator.phone", searchText];
    // receipt.operator - email
    NSPredicate *source4 = [NSPredicate predicateWithFormat:
      @"%K contains[cd] %@", @"operator.email", searchText];
    // OR
    NSPredicate *predicate = [NSCompoundPredicate
      orPredicateWithSubpredicates:@[
        source0, source1, source2, source3, source4]];
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

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)searchBar
{
  // UIBarPositioningDelegate
  // for fixing wrong searchbar position issue after back from landscape
  return UIBarPositionAny;
}


#pragma mark - Search Results

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


#pragma mark - File Importing

- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentAtURL:(NSURL *)url
{
  [[self presentingViewController] dismissViewControllerAnimated:NO
                                                      completion:nil];
  if (controller.documentPickerMode == UIDocumentPickerModeImport) {
    [self handleOpenAmkFileURL:url animated:YES];
  }
}

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

  NSString *filename = [url lastPathComponent];

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
             NSLocalizedDescriptionKey:[NSString
               stringWithFormat:@"You have already imported %@", filename]
      }];
    }
  }
  @catch (NSException *exception) {
    error = [NSError errorWithDomain:@"receipt"
                                code:100
                            userInfo:@{
           NSLocalizedDescriptionKey:[NSString
               stringWithFormat:@"Invalid file %@", filename]
    }];
  }
  if (error) {
    UIAlertView *alert = [[UIAlertView alloc]
        initWithTitle:@"Import Error"
              message:[error localizedDescription]
             delegate:self
    cancelButtonTitle:@"OK"
    otherButtonTitles:nil];
    [alert show];
    return;
  }
  BOOL saved = [manager insertReceipt:receipt atIndex:0];
  if (saved) {
    [self displayInfoForReceipt:receipt animated:animated];
    // success alert
    NSString *alertMessage = [NSString
      stringWithFormat:@"Successfully imported %@", filename];
    dispatch_async(dispatch_get_main_queue(), ^{
      UIAlertController *alertController = [UIAlertController
      alertControllerWithTitle:@"Import"
                       message:alertMessage
                preferredStyle:UIAlertControllerStyleAlert];
      [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                           style:UIAlertActionStyleDefault
                         handler:nil]];
      [self presentViewController:alertController animated:YES completion:nil];
    });
  }
}

@end
