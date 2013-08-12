//
//  SettingsViewController.m
//  generika
//
//  Created by Yasuhiro Asaka on 08/05/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsDetailViewController.h"

static const float kCellHeight = 44.0; // default = 44.0

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  _userDefaults = [NSUserDefaults standardUserDefaults];
  return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [_settingsView reloadData];
  [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateSettings)
                                               name:UIApplicationDidFinishLaunchingNotification object:nil];
  UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"close"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(closeSettings)];
  self.navigationItem.leftBarButtonItem = closeButton;
  // contents
  _settings = [NSArray arrayWithObjects:@"Search", @"Language", nil];
  // table view
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  _settingsView = [[UITableView alloc] initWithFrame:screenBounds style:UITableViewStyleGrouped];
  _settingsView.delegate = self;
  _settingsView.dataSource = self;
  _settingsView.rowHeight = kCellHeight;
  self.view = _settingsView;
}

- (void)viewDidUnload
{
  _settingsDetail = nil;
  _settingsView = nil;
  _settings = nil;
  _sectionLabel = nil;
  _nameLabel = nil;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Action

- (void)closeSettings
{
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateSettings
{
  // TODO
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return kCellHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  CGRect headerRect = CGRectMake(0, 0, 300, 40);  
  UIView *headerView = [[UIView alloc] initWithFrame:headerRect];
  headerView.backgroundColor = [UIColor clearColor];
  _sectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 5.0, 300.0, 45.0)];
  _sectionLabel.font = [UIFont boldSystemFontOfSize:18.0];
  _sectionLabel.textAlignment = kTextAlignmentLeft;
  _sectionLabel.textColor = [UIColor blackColor];
  _sectionLabel.backgroundColor = [UIColor clearColor];
  switch (section) {
    case 0:
      _sectionLabel.text = @"Settings";
      break;
    default:
      _sectionLabel.text = @"";
      break;
  }
  [headerView addSubview:_sectionLabel];
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  return 50.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  //DLog(@"indexPath: %@", indexPath);
  static NSString *cellIdentifier = @"Cell";
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:cellIdentifier];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  // name
  _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 8.0, 100.0, 25.0)];
  _nameLabel.font = [UIFont boldSystemFontOfSize:16.0];
  _nameLabel.textAlignment = kTextAlignmentLeft;
  _nameLabel.textColor = [UIColor blackColor];
  _nameLabel.backgroundColor = [UIColor clearColor];
  _nameLabel.text = [_settings objectAtIndex:indexPath.row];
  // option
  _optionLabel = [[UILabel alloc] initWithFrame:CGRectMake(160.0, 8.0, 110.0, 25.0)];
  _optionLabel.font = [UIFont systemFontOfSize:16.0];
  _optionLabel.textAlignment = kTextAlignmentRight;
  _optionLabel.textColor = [UIColor colorWithRed:0.2 green:0.33 blue:0.5 alpha:1.0];
  _optionLabel.backgroundColor = [UIColor clearColor];

  NSDictionary *context = [self contextFor:indexPath];
  NSInteger selectedRow = [_userDefaults integerForKey:[context objectForKey:@"key"]];
  //DLog(@"selectedRow = %i", selectedRow);
  //DLog(@"options = %@", [context objectForKey:@"options"]);
  _optionLabel.text = [[context objectForKey:@"options"] objectAtIndex:selectedRow];
  [cell.contentView addSubview:_nameLabel];
  [cell.contentView addSubview:_optionLabel];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  // next
  _settingsDetail = [[SettingsDetailViewController alloc] init];
  _settingsDetail.title = [_settings objectAtIndex:indexPath.row];
  //DLog(@"indexPath.row = %i", indexPath.row);
  NSDictionary *context = [self contextFor:indexPath];
  _settingsDetail.options = [context objectForKey:@"options"];
  _settingsDetail.defaultKey = [context objectForKey:@"key"];
  [self.navigationController pushViewController:_settingsDetail animated:YES];
}

- (NSDictionary *)contextFor:(NSIndexPath *)indexPath
{
  //DLog(@"indexPath.row = %i", indexPath.row)
  switch (indexPath.row) {
    case 0:
      //DLog("%@", [Constant searchTypes]);
      return [NSDictionary dictionaryWithObjectsAndKeys:
                              [Constant searchTypes], @"options",
                              @"search.result.type", @"key",
                              nil];
      break;
    case 1:
      //DLog("%@", [Constant searchLanguages]);
      return [NSDictionary dictionaryWithObjectsAndKeys:
                              [Constant searchLanguages], @"options",
                              @"search.result.lang", @"key",
                              nil];
      break;
    default:
      // unexpected
      return [NSDictionary dictionaryWithObjectsAndKeys:nil];
      break;
  }
}

@end
