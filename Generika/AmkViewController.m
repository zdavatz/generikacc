//
//  AmkViewController.m
//  Generika
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import "AmkViewController.h"


@class MasterViewController;

@interface AmkViewController ()

@property (nonatomic, strong, readwrite) UIView *receiptView;
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
  self.receiptView = [[UIView alloc] initWithFrame:screenBounds];
  [self.receiptView setContentMode:UIViewContentModeScaleAspectFit];
  [self.receiptView setBackgroundColor:[UIColor whiteColor]];

  // patient
  UIView *patientView = [[UIView alloc] initWithFrame:CGRectMake(
      0,  0, (int)screenBounds.size.width / 2, 80)];

  UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(
      70.0, 2.0, 230.0, 25.0)];
  nameLabel.font = [UIFont boldSystemFontOfSize:14.0];
  nameLabel.textAlignment = kTextAlignmentLeft;
  nameLabel.text = @"patient";
  [patientView addSubview:nameLabel];

  // doctor
  UIView *doctorView = [[UIView alloc] initWithFrame:CGRectMake(
      0, 0, (int)screenBounds.size.width / 2, 80)];

  // products
  // TODO

  [self.receiptView addSubview:patientView];
  [self.receiptView addSubview:doctorView];
  self.view = self.receiptView;
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

# pragma mark - Action

- (void)loadReceipt:(Receipt *)receipt
{
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
  // TODO
}

- (void)showActions
{
  UIActionSheet *sheet = [[UIActionSheet alloc] init];
  sheet.delegate = self;
  // TODO
  // set receipt title
  sheet.title = @"";
  [sheet addButtonWithTitle:@"Archive"];
  [sheet addButtonWithTitle:@"Back to List"];
  [sheet addButtonWithTitle:@"Cancel"];
  sheet.destructiveButtonIndex = 0;
  sheet.cancelButtonIndex      = 2;
  [sheet showInView:self.receiptView];
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
