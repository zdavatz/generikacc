//
//  SettingsViewController.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsDetailViewController.h"
#import "UIColorBackport.h"


static const float kCellHeight = 44.0; // default = 44.0

@interface SettingsViewController ()

@property (nonatomic, strong, readwrite) SettingsDetailViewController
  *settingsDetail;
@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) UITableView *settingsView;
@property (nonatomic, strong, readwrite) NSArray *entries;

- (void)closeSettings;
- (NSDictionary *)contextFor:(NSIndexPath *)indexPath;

@end

@implementation SettingsViewController

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  _userDefaults = [NSUserDefaults standardUserDefaults];
  _entries = [NSArray arrayWithObjects:
    @"Search", @"Language", @"iCloud Sync", nil];
  return self;
}

- (void)dealloc
{
  _userDefaults = nil;
  _entries = nil;
  [self didReceiveMemoryWarning];
}

- (void)didReceiveMemoryWarning
{
  if ([self isViewLoaded] && [self.view window] == nil) {
    _settingsView  = nil;
    _settingsDetail = nil;
  }
  [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.settingsView reloadData];
  [super viewWillAppear:animated];
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
  if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
    cell.preservesSuperviewLayoutMargins = NO;
  }
  if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
    cell.layoutMargins = UIEdgeInsetsZero;
  }
}

- (void)loadView
{
    self.view = [[UIView alloc] init];

    self.settingsView = [[UITableView alloc]
                         initWithFrame:CGRectZero
                         style:UITableViewStyleGrouped];
    [self.view addSubview:self.settingsView];

    self.settingsView.delegate = self;
    self.settingsView.dataSource = self;
    self.settingsView.rowHeight = kCellHeight;
    [self layoutTableViewSeparator:self.settingsView];
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];

  [self layoutTableViewSeparator:self.settingsView];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  if (@available(iOS 11, *)) {
    // for iPhone X issue
    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    self.settingsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.settingsView.leadingAnchor
     constraintEqualToAnchor:guide.leadingAnchor].active = YES;
    [self.settingsView.topAnchor
     constraintEqualToAnchor:guide.topAnchor].active = YES;
    [self.settingsView.trailingAnchor
     constraintEqualToAnchor:guide.trailingAnchor].active = YES;
    [self.settingsView.bottomAnchor
     constraintEqualToAnchor:self.bottomLayoutGuide.bottomAnchor].active = YES;

    [self.view layoutIfNeeded];
  }

  UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]
    initWithTitle:@"Close"
            style:UIBarButtonItemStylePlain
           target:self
           action:@selector(closeSettings)];
  self.navigationItem.leftBarButtonItem = closeButton;
}


#pragma mark - Action

- (void)closeSettings
{
  [self.presentingViewController dismissViewControllerAnimated:YES
                                                    completion:nil];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
  return 3;
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

- (UIView *)tableView:(UITableView *)tableView
  viewForHeaderInSection:(NSInteger)section
{
  CGFloat width  = tableView.frame.size.width;
  CGFloat height = [self tableView:tableView heightForHeaderInSection:section];
  CGRect headerRect = CGRectMake(0, 0, width, height);
  UIView *headerView = [[UIView alloc] initWithFrame:headerRect];
  headerView.backgroundColor = [UIColor clearColor];
  float leftMargin = (tableView.frame.size.width -
                      CGSizeMake(
                        tableView.frame.size.width - 40.0, MAXFLOAT
                      ).width) / 2;
  UIFont  *sectionFont;
  UIColor *sectionColor;
  if (floor(NSFoundationVersionNumber) <= kVersionNumber_iOS_6_1) {
    sectionFont = [UIFont boldSystemFontOfSize:17.0];
      sectionColor = [UIColorBackport labelColor];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { // iPad
      leftMargin += 30.0;
    }
  } else { // iOS 7 or later
    sectionFont = [UIFont systemFontOfSize:15.0];
    sectionColor = [UIColor grayColor];
    leftMargin -= 5.0;
  }
  UILabel *sectionLabel = [[UILabel alloc]
    initWithFrame:CGRectMake(leftMargin, 0, 300.0, height)];
  sectionLabel.font = sectionFont;
  sectionLabel.textColor = sectionColor;
  sectionLabel.textAlignment = kTextAlignmentLeft;
  sectionLabel.backgroundColor = [UIColor clearColor];
  switch (section) {
    case 0:
      sectionLabel.text = @"Settings";
      break;
    default:
      sectionLabel.text = @"";
      break;
  }
  [headerView addSubview:sectionLabel];
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView
  heightForHeaderInSection:(NSInteger)section
{
  return 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"Cell";
  UITableViewCell *cell = [[UITableViewCell alloc]
    initWithStyle:UITableViewCellStyleDefault
  reuseIdentifier:cellIdentifier];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  CGRect frame = cell.frame;
  // name
  CGRect nameFrame;
  UIFont *nameFont;
  if (floor(NSFoundationVersionNumber) <= kVersionNumber_iOS_6_1) {
    nameFrame = CGRectMake(frame.origin.x + 10.0, frame.origin.x + 8.0,
                           frame.size.width - 20.0, 25.0);
    nameFont =[UIFont boldSystemFontOfSize:16.0];
  } else { // iOS 7 or later
    nameFrame = CGRectMake(frame.origin.x + 15.0, frame.origin.x + 10.0,
                           frame.size.width - 20.0, 25.0);
    nameFont = [UIFont systemFontOfSize:15.0];
  }
  UILabel *nameLabel = [[UILabel alloc] initWithFrame:nameFrame];
  nameLabel.font = nameFont;
  nameLabel.textAlignment = kTextAlignmentLeft;
  nameLabel.textColor = [UIColorBackport labelColor];
  [nameLabel setAutoresizingMask:
   UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
  nameLabel.backgroundColor = [UIColor clearColor];
  nameLabel.text = [self.entries objectAtIndex:indexPath.row];
  [cell.contentView addSubview:nameLabel];
  // option
  CGRect optionFrame;
  UIFont *optionFont;
  UIColor *optionColor;
  if (floor(NSFoundationVersionNumber) <= kVersionNumber_iOS_6_1) {
    optionFrame = CGRectMake(frame.origin.x + 10.0, frame.origin.y + 8.0,
                             frame.size.width - 25.0, 25.0);
    optionFont = [UIFont systemFontOfSize:16.0];
    optionColor = [UIColor colorWithRed:0.2 green:0.33 blue:0.5 alpha:1.0];
  } else { // iOS 7 or later
    optionFrame = CGRectMake(frame.origin.x + 25.0, frame.origin.y + 10.0,
                             frame.size.width - 25.0, 25.0);
    optionFont = [UIFont systemFontOfSize:15.0];
    optionColor = [UIColorBackport secondaryLabelColor];
  }
  UILabel *optionLabel = [[UILabel alloc] initWithFrame:optionFrame];
  optionLabel.font = optionFont;
  optionLabel.textAlignment = kTextAlignmentRight;
  optionLabel.textColor = optionColor;
  optionLabel.backgroundColor = [UIColor clearColor];
  [optionLabel setAutoresizingMask:
   UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
  NSDictionary *context = [self contextFor:indexPath];
  NSInteger selectedRow = [self.userDefaults
                           integerForKey:[context objectForKey:@"key"]];
  optionLabel.text = [[context objectForKey:@"options"]
                      objectAtIndex:selectedRow];
  [cell.contentView addSubview:optionLabel];
  return cell;
}

- (void)tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  // next
  self.settingsDetail = [[SettingsDetailViewController alloc] init];
  self.settingsDetail.title = [self.entries objectAtIndex:indexPath.row];
  NSDictionary *context = [self contextFor:indexPath];
  NSString *label = [context objectForKey:@"label"];
  if (label) {
    self.settingsDetail.label = label;
  }
  self.settingsDetail.options    = [context objectForKey:@"options"];
  self.settingsDetail.defaultKey = [context objectForKey:@"key"];
  [self.navigationController
   pushViewController:self.settingsDetail animated:YES];
}

- (NSDictionary *)contextFor:(NSIndexPath *)indexPath
{
  switch (indexPath.row) {
    case 0:
      return [NSDictionary dictionaryWithObjectsAndKeys:
                              [Constant searchTypes], @"options",
                              @"search.result.type",  @"key",
                              nil];
      break;
    case 1:
      return [NSDictionary dictionaryWithObjectsAndKeys:
                              [Constant searchLanguages], @"options",
                              @"search.result.lang",      @"key",
                              nil];
      break;
    case 2:
      return [NSDictionary dictionaryWithObjectsAndKeys: // switch
                              @[@"Off", @"On"], @"options",
                              @"sync.icloud",   @"key",
                              @"iCloud Sync",   @"label",
                              nil];
      break;
    default:
      return @{}; // unexpected
      break;
  }
}

@end
