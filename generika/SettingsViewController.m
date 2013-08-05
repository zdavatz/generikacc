//
//  SettingsViewController.m
//  generika
//
//  Created by Yasuhiro Asaka on 08/05/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//

#import "SettingsViewController.h"

static const float kCellHeight = 44.0; // default = 44.0

@class MasterViewController;
@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateSettings)
                                               name:UIApplicationDidFinishLaunchingNotification object:nil];
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"back"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(goBack)];
  self.navigationItem.leftBarButtonItem = backButton;
  // table view 
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  _optionsView = [[UITableView alloc] initWithFrame:screenBounds style:UITableViewStyleGrouped];
  _optionsView.delegate = self;
  _optionsView.dataSource = self;
  _optionsView.rowHeight = kCellHeight;
  self.view = _optionsView;
}

- (void)viewDidUnload
{
  _optionsView = nil;
  _sectionLabel = nil;
  _nameLabel = nil;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark - Action

- (void)goBack
{
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  //MasterViewController *parent = [self.navigationController.viewControllers objectAtIndex:0];
  //[self.navigationController popToViewController:(UIViewController *)parent animated:YES];
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
  _sectionLabel.textAlignment = UITextAlignmentLeft;
  _sectionLabel.textColor = [UIColor blackColor];
  _sectionLabel.backgroundColor = [UIColor clearColor];
  switch (section) {
    case 0:
      _sectionLabel.text = @"Search Option";
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
  _nameLabel.font = [UIFont boldSystemFontOfSize:14.0];
  _nameLabel.textAlignment = UITextAlignmentLeft;
  _nameLabel.textColor = [UIColor blackColor];
  _nameLabel.backgroundColor = [UIColor clearColor];
  switch (indexPath.row) {
    case 0:
      _nameLabel.text = @"Type";
      break;
    case 1:
      _nameLabel.text = @"Language";
      break;
    default:
      _nameLabel.text = @"";
      break;
  }
  [cell.contentView addSubview:_nameLabel];
  DLog(@"cell %@", cell);
  return cell;
}

@end
