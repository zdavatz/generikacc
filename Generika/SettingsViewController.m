//
//  SettingsViewController.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsDetailViewController.h"
#import "SettingsProfileTableViewController.h"
#import "UIColorBackport.h"
#import "SettingsManager.h"
#import "AmikoDatabase/AmikoDBManager.h"

typedef enum : NSUInteger {
    SettingsViewControllerRowSearch = 0,
    SettingsViewControllerRowLanguage = 1,
    SettingsViewControllerRowICloudSync = 2,
    SettingsViewControllerRowProfile = 3,
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
  _entries = @[@"Search", @"Language", @"iCloud Sync", @"Profile"];

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
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 4;
        case 1:
            return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    if (indexPath.section == 0) {
        NSDictionary *context = [self contextFor:indexPath];
        cell.textLabel.text = [self.entries objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        switch (indexPath.row) {
            case SettingsViewControllerRowProfile:
                cell.detailTextLabel.text = @"";
                break;
                
            default: {
                NSInteger selectedRow = [self.userDefaults
                                         integerForKey:[context objectForKey:@"key"]];
                cell.detailTextLabel.text = [[context objectForKey:@"options"] objectAtIndex:selectedRow];
            }
                break;
        }
    } else if (indexPath.section == 1) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = @"Update Database";
        cell.detailTextLabel.text = @"";
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return [NSString stringWithFormat:@"DB Generated at: %@", [[AmikoDBManager shared] databaseLastUpdate]];
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (indexPath.row == SettingsViewControllerRowProfile) {
            NSDictionary *dict = [[SettingsManager shared] getDictFromKeychain];
            if (dict) {
                SettingsProfileTableViewController *controller = [[SettingsProfileTableViewController alloc] initWithKeychainDict:dict];
                [self.navigationController pushViewController:controller animated:YES];
            }
            return;
        }
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
    } else if (indexPath.section == 1) {
        __weak typeof(self) _self = self;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please wait", @"")
                                                                       message:NSLocalizedString(@"Downloading database now...", @"")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        NSURLSessionDownloadTask *task = [[AmikoDBManager shared] downloadNewDatabase:^(NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:YES completion:^{}];
                if (error && error.code != -999) {
                    UIAlertController *a = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Fehler", @"")
                                                                               message:error.localizedDescription
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                    [a addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction * _Nonnull action) {}]];
                    [_self presentViewController:a animated:YES completion:^{}];
                }
                if (!error) {
                    UIAlertController *a = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Downloaded", @"")
                                                                               message:[[AmikoDBManager shared] dbStat]
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                    [a addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {}]];
                    [_self presentViewController:a animated:YES completion:^{}];
                }
                [_self.settingsView reloadData];
            });
        }];
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        progressView.observedProgress = task.progress;
        

        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction * _Nonnull action) {
            [task cancel];
        }]];

        [self presentViewController:alert animated:YES completion:^{
            [alert.view addSubview:progressView];
            progressView.frame = CGRectMake(0, alert.view.frame.size.height - 45 - progressView.frame.size.height,
                                            alert.view.frame.size.width, progressView.frame.size.height);
        }];
    }
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
      case SettingsViewControllerRowProfile:
          return @{
              // No context for profile
          };
    default:
      return @{}; // unexpected
      break;
  }
}

@end
