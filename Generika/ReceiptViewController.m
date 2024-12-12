//
//  ReceiptViewController.m
//  Generika
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import "ReceiptViewController.h"
#import "Product.h"
#import "UIColorBackport.h"

// default uitableview's cell height: 44.0
static const float kInfoCellHeight = 22.0;  // fixed
static const float kItemCellHeight = 44.0;  // minimum height

static const float kSectionHeaderHeight = 27.0;  // as standard height
static const float kLabelMargin = 2.4;

// info
static const int kSectionMeta = 0;
static const int kSectionOperator = 1;
static const int kSectionPatient = 2;

// item
static const int kSectionProduct = 0;


@class MasterViewController;

@interface ReceiptViewController ()

@property (nonatomic, strong) UIView *canvasView;
@property (nonatomic, strong) UIScrollView *receiptView;
@property (nonatomic, strong) UITableView *infoView;
@property (nonatomic, strong) UITableView *itemView;

- (NSInteger)entriesCountForViewOfField:(NSString *)field;
- (void)layoutFrames;
- (void)refresh;
- (void)showActions;

@end

@implementation ReceiptViewController

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

  _canvasView = nil;
  _receiptView = nil;
  _infoView = nil;
  _itemView = nil;
  [self didReceiveMemoryWarning];
}

- (void)loadView
{
  [super loadView];

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  int statusBarHeight = [
    UIApplication sharedApplication].statusBarFrame.size.height;
  int navBarHeight = self.navigationController.navigationBar.frame.size.height;
  int barHeight = statusBarHeight + navBarHeight;
  CGRect mainFrame = CGRectMake(
    0,
    barHeight,
    screenBounds.size.width,
    CGRectGetHeight(screenBounds) - barHeight
  );

  self.receiptView = [[UIScrollView alloc] initWithFrame:mainFrame];
  self.receiptView.delegate = self;
  self.receiptView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  self.receiptView.scrollEnabled = YES;
  self.receiptView.pagingEnabled = NO;
  self.receiptView.contentOffset = CGPointZero;
  self.receiptView.showsHorizontalScrollIndicator = NO;
  self.receiptView.showsVerticalScrollIndicator = YES;
  self.receiptView.contentMode = UIViewContentModeScaleAspectFit;
  self.receiptView.backgroundColor = [UIColorBackport systemBackgroundColor];

  // info: meta, operator and patient (sections)
  self.infoView = [[UITableView alloc]
    initWithFrame:mainFrame
            style:UITableViewStyleGrouped];
  self.infoView.delegate = self;
  self.infoView.dataSource = self;
  self.infoView.backgroundColor = [UIColorBackport systemBackgroundColor];
  self.infoView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.infoView.scrollEnabled = NO;
  self.infoView.rowHeight = UITableViewAutomaticDimension;
  self.infoView.estimatedRowHeight = kInfoCellHeight;
  self.infoView.translatesAutoresizingMaskIntoConstraints = YES;

  // item: medications
  self.itemView = [[UITableView alloc]
    initWithFrame:mainFrame
            style:UITableViewStylePlain];
  self.itemView.delegate = self;
  self.itemView.dataSource = self;
  self.itemView.backgroundColor = [UIColorBackport systemBackgroundColor];
  self.itemView.scrollEnabled = NO;
  self.itemView.rowHeight = UITableViewAutomaticDimension;
  self.itemView.estimatedRowHeight = kItemCellHeight;
  self.itemView.translatesAutoresizingMaskIntoConstraints = YES;

  [self.receiptView addSubview:self.infoView];
  [self.receiptView insertSubview:self.itemView belowSubview:self.infoView];

  [self layoutTableViewSeparator:self.infoView];
  [self layoutTableViewSeparator:self.itemView];

  self.canvasView = [[UIView alloc] initWithFrame:mainFrame];
  self.canvasView.backgroundColor = [UIColorBackport systemBackgroundColor];
  [self.canvasView addSubview:self.receiptView];
  self.view = self.canvasView;
}

- (void)layoutFrames
{
  // fix toolbar on iPhone 8 (11.2) (after rotate)
  self.navigationController.toolbarHidden = YES;

  // for iPhone X issue
  if (@available(iOS 11, *)) {
    UILayoutGuide *guide = self.canvasView.safeAreaLayoutGuide;
    self.receiptView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.receiptView.leadingAnchor
     constraintEqualToAnchor:guide.leadingAnchor].active = YES;
    [self.receiptView.topAnchor
     constraintEqualToAnchor:guide.topAnchor].active = YES;
    [self.receiptView.trailingAnchor
     constraintEqualToAnchor:guide.trailingAnchor].active = YES;
    [self.receiptView.bottomAnchor
     constraintEqualToAnchor:guide.bottomAnchor].active = YES;
  }

  // infoView
  CGRect infoFrame = self.infoView.frame;
  infoFrame.origin.y = 0.6;
  infoFrame.size.width = self.view.bounds.size.width;
  infoFrame.size.height = (
      (kSectionHeaderHeight * 2) +
      (kInfoCellHeight * [self entriesCountForViewOfField:@"operator"]) +
      (kInfoCellHeight * [self entriesCountForViewOfField:@"patient"])
  );
  [self.infoView setFrame:infoFrame];

  // itemView
  CGFloat height = 0.0;
  for (int i = 0; i < [self.receipt.products count]; i++) {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i
      inSection:kSectionProduct];
    CGFloat rowHeight = [self tableView:self.itemView
      heightForRowAtIndexPath:indexPath];
    height += rowHeight;
  }
  CGFloat defaultHeight = kItemCellHeight * [self.receipt.products count];
  if (defaultHeight > height) {
    height = defaultHeight;
  }
  CGRect itemFrame = CGRectMake(
    0,
    CGRectGetMaxY(infoFrame) + 8.0,
    self.view.bounds.size.width,
    (kSectionHeaderHeight + height)
  );
  [self.itemView setFrame:itemFrame];

  // content size according size of above frames
  [self.receiptView setContentSize:CGSizeMake(
      CGRectGetWidth(self.receiptView.frame),
      CGRectGetHeight(infoFrame) + CGRectGetHeight(itemFrame))];

  [self.view layoutIfNeeded];
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
  [self layoutFrames];
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
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  [self.receiptView flashScrollIndicators];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.navigationController setToolbarHidden:YES animated:YES];
  // This line looks unnecessary. but, apparently, this can fixe wrong width
  // issue from master vview at landscape mode
  [self layoutFrames];

  // force layout (previous views will be cleared, if exist)
  // because sometimes table view cells have corrupted width :'(
  [self refresh];

  // always scroll top :'(
  float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
  if (osVersion >= 11.0) {
    [self.receiptView setContentOffset:CGPointMake(
        0, -self.receiptView.adjustedContentInset.top) animated:YES];
  } else if (osVersion >= 7.0) {
    [self.receiptView setContentOffset:CGPointMake(
        0, -self.receiptView.contentInset.top) animated:YES];
  } else {
    [self.receiptView setContentOffset:CGPointZero animated:YES];
  }

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
  [self layoutFrames];

  // redraw via reload
  [self.infoView performSelectorOnMainThread:@selector(reloadData)
                                  withObject:nil
                               waitUntilDone:YES];
  [self.itemView performSelectorOnMainThread:@selector(reloadData)
                                  withObject:nil
                               waitUntilDone:YES];
}

-(void)viewWillTransitionToSize:(CGSize)size
      withTransitionCoordinator:(
          id<UIViewControllerTransitionCoordinator>)coordinator
{
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

  // via orientation notification settings in viewdidload like below, sometimes
  // it'll be late to re:layout, so use this method instead.
  //
  //[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  //[[NSNotificationCenter defaultCenter]
  //  addObserver:self
  //     selector:@selector(didRotate:)
  //         name:UIDeviceOrientationDidChangeNotification object:nil];

  [coordinator animateAlongsideTransition:^(
    id<UIViewControllerTransitionCoordinatorContext> context) {
    // willRotateToInterfaceOrientation
  } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    // didRotateFromInterfaceOrientation would go here.
    [self didRotate:nil];
  }];
}

- (NSInteger)entriesCountForViewOfField:(NSString *)field
{
  NSInteger count = 0;
  if ([field isEqualToString:@"operator"]) {
    count = [self.receipt entriesCountOfField:@"operator"];
    Operator *operator = self.receipt.operator;
    // in same line
    if (operator && (
        ![operator.familyName isEqualToString:@""] ||
        ![operator.givenName isEqualToString:@""])) {
      count -= 1;
    }
    if (operator &&
        ![operator.title isEqualToString:@""]) {
      count -= 1;
    }
  } else if ([field isEqualToString:@"patient"]) {
    count = [self.receipt entriesCountOfField:@"operator"];
    Patient *patient = self.receipt.patient;
    // in same line
    if (patient && (
        ![patient.familyName isEqualToString:@""] ||
        ![patient.givenName isEqualToString:@""])) {
      count -= 1;
    }
    if (patient && (
        ![patient.weight isEqualToString:@""] ||
        ![patient.height isEqualToString:@""])) {
      count -= 1;
    }
  }
  return count;
}

#pragma mark - Scroll view

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  // a hack to disable horizontal on some versions
  scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
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
    if (section == kSectionMeta) {  // meta (place_date)
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

  CGRect labelFrame = CGRectMake(12, 2, 200, 25);
  UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
  label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightLight];
  label.textColor = [UIColor secondaryLabelColor];
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
    NSInteger count = [self.receipt.products count];
    NSString *format = @"Medikamente (%d)";
    if (count < 2) {
      format = @"Medikament (%d)";
    }
    label.text = [NSString stringWithFormat:format, count];
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
      return 6;
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
    Product *product = [self.receipt.products objectAtIndex:indexPath.row];
    if (product) {
      // NOTE
      // Don't use `tableView.frame.size.width` here, because it returns
      // "previous" with value (at before rotation), so, use
      // `canvasView.frame.size.width`

      if (@available(iOS 11, *)) {
          tableView.contentInset = UIEdgeInsetsMake(0, 0,
              self.canvasView.frame.size.width - 24.0, 0);
      }

      CGFloat height = 0.0;
      CGFloat width = self.canvasView.frame.size.width - 24.0;
      // package name label
      UILabel *packLabel = [self makeItemLabel:product.pack
                                     textColor:[UIColor clearColor]
                                    fontOfSize:12.2];
      height += [Helper getSizeOfLabel:packLabel inWidth:width].height;
      height += kLabelMargin;
      // ean label
      UILabel *eanLabel = [self makeItemLabel:product.ean
                                    textColor:[UIColor clearColor]
                                   fontOfSize:12.2];
      height += [Helper getSizeOfLabel:eanLabel inWidth:width].height;
      height += kLabelMargin;
      height += 8.0;
      // comment label
      UILabel *commentLabel = [self makeItemLabel:product.comment
                                        textColor:[UIColor clearColor]
                                       fontOfSize:12.2];
      height += [Helper getSizeOfLabel:commentLabel inWidth:width].height;
      height += kLabelMargin;
      height += 8.0;
      if (height > kItemCellHeight) {
        return height;
      }
    }
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
  cell.contentView.translatesAutoresizingMaskIntoConstraints = YES;

  if (@available(iOS 11, *)) {
    tableView.contentInset = UIEdgeInsetsMake(0, 0,
        self.canvasView.frame.size.width, 0);
  }

  UILabel *label;
  int labelIndex = 0;
  if (tableView == self.infoView) {
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.section == kSectionMeta) {
      // place_date
      label = [self makeInfoLabel:self.receipt.placeDate
                        textColor:[UIColor labelColor]
                       fontOfSize:13.8];
    } else {  // operator or patient
      label = [self makeInfoLabel:@""
                        textColor:[UIColor labelColor]
                       fontOfSize:13.0];
      if (indexPath.section == kSectionOperator) {
        Operator *operator = self.receipt.operator;
        if (operator) {
          if (indexPath.row == 0) {
            // given_name + family_name
            label.text = [NSString stringWithFormat:@"%@ %@",
              operator.givenName, operator.familyName, nil];
            if (![operator.title isEqualToString:@""]) {
              label.text = [operator.title stringByAppendingString:[
                NSString stringWithFormat:@" %@", label.text, nil]];
            }
            // signature image (90.0 x 45.0)
            if (![operator.signature isEqualToString:@""]) {
              UIImageView *signatureView = [[UIImageView alloc]
                initWithImage:operator.signatureThumbnail];
              CGFloat imageWidth = 90.0;
              CGRect imageFrame = CGRectMake(
                  self.infoView.frame.size.width - (imageWidth + 10.0),
                  0, imageWidth, 45.0);
              // for iPhone X issue
              if (@available(iOS 11, *)) {
                imageFrame.origin.x = self.infoView.frame.size.width - (
                    self.view.safeAreaInsets.left * 2) - (imageWidth + 10.0);
              }
              [signatureView setFrame:imageFrame];
              signatureView.contentMode = UIViewContentModeTopRight;
              signatureView.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 10);
              [signatureView setNeedsDisplay];
              [cell.contentView addSubview:signatureView];
              labelIndex += 1;
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
          if (indexPath.row == 0) { // given_name + family_name
            label.text = [NSString stringWithFormat:@"%@ %@",
              patient.givenName, patient.familyName, nil];
          } else if (indexPath.row == 1) {
            // weight_kg/height_cm gender birth_date
            label.text = @"";
            if (![patient.weight isEqualToString:@""]) {
              label.text = [label.text stringByAppendingString:[
                NSString stringWithFormat:@"%@kg",
                patient.weight, nil]];
            }
            if (![patient.height isEqualToString:@""]) {
              label.text = [label.text stringByAppendingString:[
                NSString stringWithFormat:@"/%@cm",
                patient.height, nil]];
            }
            if (![patient.gender isEqualToString:@""]) {
              // use sign F/M or any capitalized char
              label.text = [label.text stringByAppendingString:[
                NSString stringWithFormat:@" %@", patient.genderSign, nil]];
            }
            if (![patient.birthDate isEqualToString:@""]) {
              label.text = [label.text stringByAppendingString:[
                NSString stringWithFormat:@" %@",
                patient.birthDate, nil]];
            }
          } else if (indexPath.row == 2) { // postal_address
            label.text = patient.address;
          } else if (indexPath.row == 3) { // city country
            label.text = [NSString stringWithFormat:@"%@ %@",
              patient.city, patient.country, nil];
          } else if (indexPath.row == 4) { // phone
            label.text = patient.phone;
          } else if (indexPath.row == 5) { // email
            label.text = patient.email;
          }
        }
      }
    }
    if (label.text && ![label.text isEqualToString:@""]) {
      [label sizeToFit];
      [cell.contentView insertSubview:label atIndex:labelIndex];
    }
  } else if (tableView == self.itemView) { // medications
    Product *product;
    product = [self.receipt.products objectAtIndex:indexPath.row];
    if (product) {
      UILabel *packLabel = [self makeItemLabel:product.pack
                                     textColor:[UIColor labelColor]
                                    fontOfSize:12.2];
      UILabel *eanLabel = [self makeItemLabel:product.ean
                                    textColor:[UIColor secondaryLabelColor]
                                   fontOfSize:12.2];
      UILabel *commentLabel = [self makeItemLabel:product.comment
                                        textColor:[UIColor secondaryLabelColor]
                                       fontOfSize:12.2];
      // layout (fix origin.y)
      CGRect eanFrame = CGRectMake(
          12.0,
          packLabel.frame.origin.y + packLabel.frame.size.height +
            kLabelMargin,
          eanLabel.frame.size.width,
          eanLabel.frame.size.height
      );
      [eanLabel setFrame:eanFrame];

      CGRect commentFrame = CGRectMake(
          12.0,
          eanLabel.frame.origin.y + eanLabel.frame.size.height +
            kLabelMargin,
          commentLabel.frame.size.width,
          commentLabel.frame.size.height
      );
      [commentLabel setFrame:commentFrame];
      [cell.contentView addSubview:packLabel];
      [cell.contentView insertSubview:eanLabel belowSubview:packLabel];
      [cell.contentView insertSubview:commentLabel belowSubview:eanLabel];
    }
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (BOOL)tableView:(UITableView *)tableView
  shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
  // on all table views
  return NO;
}

- (void)tableView:(UITableView *)tableView
  didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
  // pass
}


#pragma mark - UI

- (UILabel *)makeInfoLabel:(NSString *)text
                 textColor:(UIColor *)color
                  fontOfSize:(CGFloat)size
{
  CGRect frame = CGRectMake(
    12.0, 0, self.infoView.frame.size.width, kInfoCellHeight);

  if (@available(iOS 11, *)) {
    // for iPhone X issue
    frame.size.width = self.infoView.frame.size.width - (
        self.view.safeAreaInsets.left * 2);
  }

  UILabel *label = [[UILabel alloc] initWithFrame:frame];
  label.font = [UIFont systemFontOfSize:size];
  label.textAlignment = kTextAlignmentLeft;
  label.textColor = color;
  label.text = text;
  label.backgroundColor = [UIColor clearColor];
  label.highlighted = NO;

  // use multiple lines for wrapped text as required
  label.numberOfLines = 0;
  label.preferredMaxLayoutWidth = frame.size.width;
  label.lineBreakMode = NSLineBreakByWordWrapping;

  [label sizeToFit];  // this line must be after `numberOfLines`
  return label;
}

- (UILabel *)makeItemLabel:(NSString *)text
                 textColor:(UIColor *)color
                 fontOfSize:(CGFloat)size
{
  CGRect frame = CGRectMake(
    12.0,
     8.0,
    (self.canvasView.bounds.size.width - 24.0),
    0.0);

  if (@available(iOS 11, *)) {
      // for iPhone X issue
      frame.size.width = frame.size.width -
          self.view.safeAreaInsets.left * 2;
  }

  UILabel *label = [[UILabel alloc] initWithFrame:frame];
  label.font = [UIFont systemFontOfSize:size];
  label.textAlignment = kTextAlignmentLeft;
  label.textColor = color;
  label.text = text;
  label.backgroundColor = [UIColor clearColor];
  label.highlighted = NO;

  // use multiple lines for wrapped text as required
  label.numberOfLines = 0;
  label.preferredMaxLayoutWidth = frame.size.width;
  label.lineBreakMode = NSLineBreakByWordWrapping;

  [label sizeToFit];  // this line must be after `numberOfLines`
  return label;
}


#pragma mark - Action

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

  NSString *description = [NSString stringWithFormat:@"%@\r%@",
    self.receipt.filename,
    self.receipt.importedAt];
  sheet.title = description;

  // TODO
  // more actions
  [sheet addButtonWithTitle:@"Back to List"];
  [sheet addButtonWithTitle:@"Cancel"];
  sheet.destructiveButtonIndex = 0;
  sheet.cancelButtonIndex = 1;
  [sheet showInView:self.view];
}

#pragma mark - ActionSheet

- (void)actionSheet:(UIActionSheet *)sheet
  clickedButtonAtIndex:(NSInteger)index
{
  if (index == sheet.destructiveButtonIndex) { // back to list
    // TODO
    // Add archive action
    MasterViewController *parent = [self.navigationController.viewControllers
                                    objectAtIndex:0];
    [self.navigationController popToViewController:(
        UIViewController *)parent animated:YES];
  }
}

@end
