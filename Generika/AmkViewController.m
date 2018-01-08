//
//  AmkViewController.m
//  Generika
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import "AmkViewController.h"

static const float kMetaCellHeight = 20.0; // default = 44.0
static const float kItemCellHeight = 40.0;

@class MasterViewController;

@interface AmkViewController ()

@property (nonatomic, strong, readwrite) UITableView *metaView;
@property (nonatomic, strong, readwrite) UITableView *itemView;
@property (nonatomic, strong, readwrite) MasterViewController *parent;

- (void)refresh;
- (void)showActions;

@end

@implementation AmkViewController

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  return self;
}

- (void)dealloc
{
  _parent = nil;
  _receipt = nil;
  [self didReceiveMemoryWarning];
}

- (void)didReceiveMemoryWarning
{
  if ([self isViewLoaded] && [self.view window] == nil) {
    // TODO
  }
  [super didReceiveMemoryWarning];
}

- (void)loadView
{
  [super loadView];

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  self.view = [[UIView alloc] initWithFrame:screenBounds];
  [self.view setContentMode:UIViewContentModeScaleAspectFit];
  [self.view setBackgroundColor:[UIColor whiteColor]];

  // meta: operator/patient (sections)
  self.metaView = [[UITableView alloc]
    initWithFrame:screenBounds
            style:UITableViewStyleGrouped];
  self.metaView.delegate = self;
  self.metaView.dataSource = self;
  self.metaView.rowHeight = kMetaCellHeight;
  // item: medications
  self.itemView = [[UITableView alloc]
    initWithFrame:screenBounds
            style:UITableViewStyleGrouped];
  self.itemView.delegate = self;
  self.itemView.dataSource = self;
  self.itemView.rowHeight = kItemCellHeight;

  [self.view addSubview:self.metaView];
  [self.view addSubview:self.itemView];

  [self layoutTableViewSeparator:self.metaView];
  [self layoutTableViewSeparator:self.itemView];
}

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

- (void)viewDidLoad
{
  [super viewDidLoad];
  // navigationbar
  // < back button
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
    initWithTitle:@""
            style:UIBarButtonItemStylePlain
           target:self
           action:@selector(goBack)];
  // action
  UIBarButtonItem *actionButton = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                         target:self
                         action:@selector(showActions)];
  self.navigationItem.rightBarButtonItem = actionButton;
  // orientation
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(didRotate:)
           name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  self.itemView.frame = CGRectMake(
    0,
    CGRectGetMidY(self.view.bounds) + 30.0,
    self.view.bounds.size.width,
    (self.view.bounds.size.height / 2) - 30.0
  );
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.navigationController setToolbarHidden:YES animated:YES];
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self.navigationController setToolbarHidden:NO animated:YES];
  [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == \
      UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}

- (void)didRotate:(NSNotification *)notification
{
  // TODO
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  if (tableView == self.metaView) {
    return 2;
  } else if (tableView == self.itemView) {
    return 1;
  } else { // unexpected
    return 1;
  }
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  if (tableView == self.metaView) {
    return 5;
  } else if (tableView == self.itemView) {
    return [self.receipt.products count];
  } else { // unexpected
    return 0;
  }
}

- (CGFloat)tableView:(UITableView *)tableView
  heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.metaView) {
    return kMetaCellHeight;
  } else if (tableView == self.itemView) {
    return kItemCellHeight;
  } else { // unexpected
    return 0;
  }
}

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
{
  [self layoutCellSeparator:cell];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"Cell";
  UITableViewCell *cell = [[UITableViewCell alloc]
    initWithStyle:UITableViewCellStyleDefault
  reuseIdentifier:cellIdentifier];
  // name
  CGRect nameFrame;
  UIFont *nameFont;
  if (floor(NSFoundationVersionNumber) <= kVersionNumber_iOS_6_1) {
    nameFrame = CGRectMake(10.0, 8.0, 120.0, 25.0);
    nameFont = [UIFont boldSystemFontOfSize:16.0];
  } else { // iOS 7 or later
    nameFrame = CGRectMake(15.0, 10.0, 120.0, 25.0);
    nameFont = [UIFont systemFontOfSize:15.0];
  }
  UILabel *nameLabel = [[UILabel alloc] initWithFrame:nameFrame];
  nameLabel.font = nameFont;
  nameLabel.textAlignment = kTextAlignmentLeft;
  nameLabel.textColor = [UIColor blackColor];
  nameLabel.backgroundColor = [UIColor clearColor];

  [cell.contentView addSubview:nameLabel];
  return cell;
}

- (void)tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // pass
}

# pragma mark - Action

- (void)loadReceipt:(Receipt *)receipt
{
  _receipt = receipt;
  [self refresh];
}

- (void)goBack
{
  MasterViewController *parent = [self.navigationController.viewControllers
                                  objectAtIndex:0];
  [self.navigationController popToViewController:(
      UIViewController *)parent animated:YES];
}

- (void)refresh
{
  [self.metaView reloadData];
  [self.itemView reloadData];
}

- (void)showActions
{
  UIActionSheet *sheet = [[UIActionSheet alloc] init];
  sheet.delegate = self;

  Operator *operator = self.receipt.operator;
  sheet.title = operator.title;

  [sheet addButtonWithTitle:@""];
  [sheet addButtonWithTitle:@"Back to List"];
  [sheet addButtonWithTitle:@"Cancel"];
  sheet.destructiveButtonIndex = 0;
  sheet.cancelButtonIndex      = 2;
  [sheet showInView:self.view];
}

#pragma mark - ActionSheet

- (void)actionSheet:(UIActionSheet *)sheet
  clickedButtonAtIndex:(NSInteger)index
{
  if (index == sheet.destructiveButtonIndex) {
    // TODO
  } else if (index == 1) { // back to list
    MasterViewController *parent = [self.navigationController.viewControllers
                                    objectAtIndex:0];
    [self.navigationController popToViewController:(
        UIViewController *)parent animated:YES];
  }
}

@end
