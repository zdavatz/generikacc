//
//  AmkViewController.m
//  Generika
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import "AmkViewController.h"
#import "Product.h"

static const float kInfoCellHeight = 20.0; // default = 44.0
static const float kItemCellHeight = 44.0;

static const float kSectionHeaderHeight = 27.0;
static const int kSectionMeta     = 0;
static const int kSectionOperator = 1;
static const int kSectionPatient  = 2;

@class MasterViewController;

@interface AmkViewController ()

@property (nonatomic, strong, readwrite) UITableView *infoView;
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

- (void)loadView
{
  [super loadView];

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  self.view = [[UIView alloc] initWithFrame:screenBounds];
  [self.view setContentMode:UIViewContentModeScaleAspectFit];
  [self.view setBackgroundColor:[UIColor whiteColor]];

  // info: meta, operator and patient (sections)
  self.infoView = [[UITableView alloc]
    initWithFrame:screenBounds
            style:UITableViewStyleGrouped];
  self.infoView.delegate = self;
  self.infoView.dataSource = self;
  self.infoView.rowHeight = kInfoCellHeight;
  self.infoView.backgroundColor = [UIColor whiteColor];
  self.infoView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.infoView.scrollEnabled = YES;

  // item: medications
  self.itemView = [[UITableView alloc]
    initWithFrame:screenBounds
            style:UITableViewStylePlain];
  self.itemView.delegate = self;
  self.itemView.dataSource = self;
  self.itemView.rowHeight = kItemCellHeight;
  self.itemView.backgroundColor = [UIColor whiteColor];

  [self.view addSubview:self.infoView];
  [self.view addSubview:self.itemView];

  [self layoutTableViewSeparator:self.infoView];
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

  const float kHeight = 65.0;
  CGRect infoFrame = self.infoView.frame;
  infoFrame.size.width = self.view.bounds.size.width;
  infoFrame.size.height = (self.view.bounds.size.height / 2) + kHeight;
  [self.infoView setFrame:infoFrame];

  CGRect itemFrame = CGRectMake(
    0,
    CGRectGetMidY(self.view.bounds) + kHeight,
    self.view.bounds.size.width,
    (self.view.bounds.size.height / 2) - kHeight
  );
  [self.itemView setFrame:itemFrame];
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
  [self viewDidLayoutSubviews];
  // redraw
  [self.infoView performSelectorOnMainThread:@selector(reloadData)
                                  withObject:nil
                               waitUntilDone:NO];
  [self.itemView performSelectorOnMainThread:@selector(reloadData)
                                  withObject:nil
                               waitUntilDone:NO];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  if (tableView == self.infoView) {
    return 3;
  } else if (tableView == self.itemView) {
    return 1;
  } else { // unexpected
    return 1;
  }
}

- (CGFloat)tableView:(UITableView *)tableView
  heightForHeaderInSection:(NSInteger)section
{
  // default value: UITableViewAutomaticDimension;
  if (tableView == self.infoView) {
    if (section == kSectionMeta) {
      return kSectionHeaderHeight / 2.5;
    } else { // operator|patient
      return kSectionHeaderHeight;
    }
  } else {
    return kSectionHeaderHeight + 1.6;
  }
}

- (UIView *)tableView:(UITableView *)tableView
viewForHeaderInSection:(NSInteger)section
{
  // set height by section
  CGRect frame = CGRectMake(
    0, 0, CGRectGetWidth(tableView.frame), 0);
  UIView *view = [[UIView alloc] initWithFrame:frame];
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 2, 200, 25)];
  label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightLight];
  label.textColor = [UIColor darkGrayColor];
  frame.size.height = 25;
  if (tableView == self.infoView) {
    if (section == kSectionOperator) {
      label.text = @"Arzt";
    } else if (section == kSectionPatient) {
      label.text = @"Patient";
    } else { // meta
      frame.size.height = 0;
      label.text = @"";
    }
  } else {
    label.text = @"Medikamente";
    [view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
  }
  [view addSubview:label];
  return view;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  if (tableView == self.infoView) {
    if (section == kSectionMeta) {
      return 1;
    } else if (section == kSectionOperator) {
      return 5;
    } else if (section == kSectionPatient) {
      return 4;
    }
  } else if (tableView == self.itemView) {
    return [self.receipt.products count];
  }
  return 0; // unexpected
}

- (CGFloat)tableView:(UITableView *)tableView
  heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.infoView) {
    return kInfoCellHeight;
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
  if (tableView == self.infoView) {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    CGRect frame = CGRectMake(
      12.0, 0, self.view.bounds.size.width, 25.0);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    if (indexPath.section == kSectionMeta) {
      // place_date
      label.font = [UIFont systemFontOfSize:13.8];
      label.textAlignment = kTextAlignmentLeft;
      label.textColor = [UIColor blackColor];
      label.backgroundColor = [UIColor clearColor];
      label.text = self.receipt.placeDate;
    } else if (indexPath.section == kSectionOperator) {
      Operator *operator = self.receipt.operator;
      if (operator) {
        label.font = [UIFont systemFontOfSize:13.0];
        label.textAlignment = kTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        if (indexPath.row == 0) {
          // given_name + family_name
          label.text = [NSString stringWithFormat:@"%@ %@",
            operator.givenName, operator.familyName, nil];
          // signature image
          if (operator.signature) {
            UIImageView *signatureView = [[UIImageView alloc]
              initWithImage:operator.signatureThumbnail];
            signatureView.frame = CGRectMake(
                self.view.bounds.size.width - 90.0, 0, 90.0, 45.0);
            [cell.contentView addSubview:signatureView];
          }
        } else if (indexPath.row == 1) { // postal_address
          label.text = operator.address;
        } else if (indexPath.row == 2) { // city country
          label.text = [NSString stringWithFormat:@"%@ %@",
            operator.city, operator.country, nil];
        } else if (indexPath.row == 3) { // phone
          label.text = operator.phone;
        } else if (indexPath.row == 4) { // email
          label.text = operator.email;
        }
      }
    } else if (indexPath.section == kSectionPatient) {
      Patient *patient = self.receipt.patient;
      if (patient) {
        label.font = [UIFont systemFontOfSize:13.0];
        label.textAlignment = kTextAlignmentLeft;
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor clearColor];
        if (indexPath.row == 0) { // given_name + family_name
          label.text = [NSString stringWithFormat:@"%@ %@",
            patient.givenName, patient.familyName, nil];
        } else if (indexPath.row == 1) { // birth_date
          label.text = patient.birthDate;
        } else if (indexPath.row == 2) { // postal_address
          label.text = patient.address;
        } else if (indexPath.row == 3) { // city country
          label.text = [NSString stringWithFormat:@"%@ %@",
            patient.city, patient.country, nil];
        }
      }
    } else {
      // unexpected
    }
    if (label.text) { // 1 cell per row
      label.lineBreakMode = NSLineBreakByWordWrapping;
      label.numberOfLines = 0;
      [cell.contentView addSubview:label];
    }
  } else if (tableView == self.itemView) { // medications
    Product *product;
    product = [self.receipt.products objectAtIndex:indexPath.row];
    if (product) {
      CGRect pFrame = CGRectMake(
        12.0,
        (kItemCellHeight / 2) - 20.5,
        (self.view.bounds.size.width - 26.0),
        kItemCellHeight);
      UILabel *pLabel = [[UILabel alloc] initWithFrame:pFrame];
      pLabel.font = [UIFont systemFontOfSize:11.8];
      pLabel.textAlignment = kTextAlignmentLeft;
      pLabel.textColor = [UIColor blackColor];
      pLabel.backgroundColor = [UIColor clearColor];
      pLabel.text = product.pack;
      // TODO (other entries)
      [cell.contentView addSubview:pLabel];
    }
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)tableView:(UITableView *)tableView
  didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
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
  [self.infoView reloadData];
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
  sheet.cancelButtonIndex = 2;
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
