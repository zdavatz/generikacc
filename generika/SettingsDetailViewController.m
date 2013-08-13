//
//  SettingsDetailViewController.m
//  generika
//
//  Created by Yasuhiro Asaka on 08/06/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//

#import "SettingsDetailViewController.h"

static const float kCellHeight = 44.0; // default = 44.0

@interface SettingsDetailViewController ()

@property (nonatomic, strong, readwrite) NSUserDefaults *userDefaults;
@property (nonatomic, strong, readwrite) UITableView *detailView;
@property (nonatomic, strong, readwrite) NSIndexPath *selectedPath;

@end

@implementation SettingsDetailViewController

@synthesize options = _options, defaultKey = _defaultKey;

@synthesize userDefaults = _userDefaults;
@synthesize detailView = _detailView;
@synthesize selectedPath = _selectedPath;

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
  _defaultkey   = nil;
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
  self.detailView = [[UITableView alloc] initWithFrame:screenBounds style:UITableViewStyleGrouped];
  self.detailView.delegate = self;
  self.detailView.dataSource = self;
  self.detailView.rowHeight = kCellHeight;
  self.view = self.detailView;
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.options.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return kCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"Cell";
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:cellIdentifier];
  if (indexPath.row == self.selectedPath.row) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  // name
  UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 8.0, 120.0, 25.0)];
  nameLabel.font = [UIFont boldSystemFontOfSize:16.0];
  nameLabel.textAlignment = kTextAlignmentLeft;
  nameLabel.textColor = [UIColor blackColor];
  nameLabel.backgroundColor = [UIColor clearColor];
  nameLabel.text = [self.options objectAtIndex:indexPath.row];
  [cell.contentView addSubview:nameLabel];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (indexPath.row != self.selectedPath.row) {
    // uncheck
    UITableViewCell *prev = [tableView cellForRowAtIndexPath:self.selectedPath];
    prev.accessoryType = UITableViewCellAccessoryNone;
    // check & store
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self.userDefaults setInteger:indexPath.row forKey:self.defaultKey];
    [self.userDefaults synchronize];
    self.selectedPath = indexPath;
  }
}

@end
