//
//  SettingsViewController.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsDetailViewController.h"
#import "UIColorBackport.h"

typedef enum : NSUInteger {
    SettingsViewControllerRowSearch = 0,
    SettingsViewControllerRowLanguage = 1,
    SettingsViewControllerRowICloudSync = 2,
} SettingsViewControllerRow;

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

  self.title = @"Settings";
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

- (void)loadView
{
    self.view = [[UIView alloc] init];

    self.settingsView = [[UITableView alloc]
                         initWithFrame:CGRectZero
                         style:UITableViewStyleGrouped];
    [self.view addSubview:self.settingsView];

    self.settingsView.delegate = self;
    self.settingsView.dataSource = self;
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
  self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
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

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSDictionary *context = [self contextFor:indexPath];
    NSInteger selectedRow = [self.userDefaults
                             integerForKey:[context objectForKey:@"key"]];
    
    cell.textLabel.text = [self.entries objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = [[context objectForKey:@"options"] objectAtIndex:selectedRow];
    
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
    case SettingsViewControllerRowSearch:
          return @{
              @"options": [Constant searchTypes],
              @"key": @"search.result.type",
          };

      break;
      case SettingsViewControllerRowLanguage:
          return @{
              @"options": [Constant searchLanguages],
              @"key": @"search.result.lang",
          };
      break;
      case SettingsViewControllerRowICloudSync:
          return @{
              @"options": @[@"Off", @"On"],
              @"key": @"sync.icloud",
              @"label": @"iCloud Sync",
          };
      break;
    default:
      return @{}; // unexpected
      break;
  }
}

@end
