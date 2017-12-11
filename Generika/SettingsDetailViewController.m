//
//  SettingsDetailViewController.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "SettingsDetailViewController.h"
#import "ProductManager.h"


static const float kCellHeight = 44.0; // default = 44.0

@interface SettingsDetailViewController ()

@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) UITableView *detailView;
@property (nonatomic, strong, readwrite) NSIndexPath *selectedPath;

- (BOOL)isSwitch;
- (void)changeSwitch:(UISwitch *)toggleSwitch;

@end

@implementation SettingsDetailViewController

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  _userDefaults = [NSUserDefaults standardUserDefaults];
  return self;
}

- (void)dealloc
{
  _userDefaults = nil;
  _options      = nil;
  _defaultKey   = nil;
  _label        = nil;
  _selectedPath = nil;
  [self didReceiveMemoryWarning];
}

- (void)didReceiveMemoryWarning
{
  if ([self isViewLoaded] && [self.view window] == nil) {
    _detailView = nil;
  }
  [super didReceiveMemoryWarning];
}

- (void)loadView
{
  [super loadView];

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  self.detailView = [[UITableView alloc]
    initWithFrame:screenBounds
            style:UITableViewStyleGrouped];
  self.detailView.delegate = self;
  self.detailView.dataSource = self;
  self.detailView.rowHeight = kCellHeight;

  // attach detailView as self.view
  self.view = self.detailView;
  [self layoutTableViewSeparator:self.detailView];
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];

  [self layoutTableViewSeparator:self.detailView];
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
  NSInteger selectedRow = [self.userDefaults integerForKey:self.defaultKey];
  self.selectedPath = [NSIndexPath indexPathForRow:selectedRow inSection:0];
}


#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  if ([self isSwitch]) {
    return 1;
  } else {
    return self.options.count;
  }
}

- (CGFloat)tableView:(UITableView *)tableView
  heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return kCellHeight;
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
  if (![self isSwitch]) {
    nameLabel.text = [self.options objectAtIndex:indexPath.row];
    if (indexPath.row == self.selectedPath.row) {
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
      cell.accessoryType = UITableViewCellAccessoryNone;
    }
  } else {
    nameLabel.text = self.label;
    UISwitch *toggleSwitch = [[UISwitch alloc] init];
    toggleSwitch.frame = CGRectMake(1.0, 1.0, 20.0, 20.0);
    NSNumber *value = [NSNumber numberWithInt:self.selectedPath.row];
    toggleSwitch.on = [value boolValue];
    [toggleSwitch addTarget:self
                     action:@selector(changeSwitch:)
           forControlEvents:UIControlEventValueChanged];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = toggleSwitch;
  }
  [cell.contentView addSubview:nameLabel];
  return cell;
}

- (void)tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (![self isSwitch]) {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row != self.selectedPath.row) {
      // uncheck
      UITableViewCell *prev = [tableView
        cellForRowAtIndexPath:self.selectedPath];
      prev.accessoryType = UITableViewCellAccessoryNone;
      // check & store
      UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
      [self.userDefaults setInteger:indexPath.row forKey:self.defaultKey];
      [self.userDefaults synchronize];
      self.selectedPath = indexPath;
    }
  }
}


#pragma mark - UI

- (BOOL)isSwitch
{
  return [self.options isEqualToArray:@[@"Off", @"On"]];
}

- (void)changeSwitch:(UISwitch *)toggleSwitch
{
  NSNumber *value = [NSNumber numberWithBool:toggleSwitch.on];
  [self.userDefaults setInteger:[value intValue] forKey:self.defaultKey];
  [self.userDefaults synchronize];
  if ([value boolValue]) {
    ProductManager *manager = [ProductManager sharedManager];
    dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
      ^(void) {
        [manager load];
      }
    );
  }
}

@end
