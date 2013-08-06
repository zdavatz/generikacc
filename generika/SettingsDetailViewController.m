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

@end

@implementation SettingsDetailViewController

@synthesize options = _options;
@synthesize defaultKey = _defaultKey;

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  _userDefaults = [NSUserDefaults standardUserDefaults];
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  NSInteger selectedRow = [_userDefaults integerForKey:_defaultKey];
  //DLog(@"selectedRow = %i", selectedRow);
  _selectedPath = [NSIndexPath indexPathForRow:selectedRow inSection:0];

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  _detailView = [[UITableView alloc] initWithFrame:screenBounds style:UITableViewStyleGrouped];
  _detailView.delegate = self;
  _detailView.dataSource = self;
  _detailView.rowHeight = kCellHeight;
  self.view = _detailView;
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  _options = nil;
  _defaultKey = nil;
  _selectedPath = nil;
  _detailView = nil;
  _nameLabel = nil;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return _options.count;
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

  //DLog(@"indexPath.row = %i", indexPath.row);
  //DLog(@"_selectedPath.row = %i", _selectedPath.row);
  if (indexPath.row == _selectedPath.row) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  // name
  _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 8.0, 100.0, 25.0)];
  _nameLabel.font = [UIFont boldSystemFontOfSize:14.0];
  _nameLabel.textAlignment = UITextAlignmentLeft;
  _nameLabel.textColor = [UIColor blackColor];
  _nameLabel.backgroundColor = [UIColor clearColor];
  _nameLabel.text = [_options objectAtIndex:indexPath.row];
  [cell.contentView addSubview:_nameLabel];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  //DLog(@"indexPath.row = %i", indexPath.row);
  //DLog(@"_selectedPath.row = %i", _selectedPath.row);
  if (indexPath.row != _selectedPath.row) {
    UITableViewCell *prev = [tableView cellForRowAtIndexPath:_selectedPath];
    prev.accessoryType = UITableViewCellAccessoryNone;

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [_userDefaults setInteger:indexPath.row forKey:_defaultKey];
    [_userDefaults synchronize];
    _selectedPath = indexPath;
  }
}

@end
