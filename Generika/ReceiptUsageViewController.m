//
//  ReceiptUsageViewController.m
//  Generika
//
//  Copyright (c) 2013-2017 ywesee GmbH. All rights reserved.
//

#import "ReceiptUsageViewController.h"


@interface ReceiptUsageViewController ()

@property (nonatomic, strong, readwrite) UITextView *usageView;

- (void)closeUsageView;

@end

@implementation ReceiptUsageViewController

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  return self;
}

- (void)dealloc
{
  [self didReceiveMemoryWarning];
}

- (void)didReceiveMemoryWarning
{
  if ([self isViewLoaded] && [self.view window] == nil) {
    _usageView  = nil;
  }
  [super didReceiveMemoryWarning];
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
  self.usageView = [[UITextView alloc] initWithFrame:mainFrame];
  self.usageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;

  // attach usageView as view
  self.view = self.usageView;
  [self layoutFrameAndViews];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  UIBarButtonItem *closeButton = [[UIBarButtonItem alloc]
    initWithTitle:@"Close"
            style:UIBarButtonItemStylePlain
           target:self
           action:@selector(closeUsageView)];
  self.navigationItem.leftBarButtonItem = closeButton;

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
  [self layoutFrameAndViews];

  [super viewWillAppear:animated];
}

- (void)layoutFrameAndViews
{
  CGRect textFrame = self.view.frame;
  textFrame.origin.x = 18.0;
  textFrame.origin.y = 16.0;
  textFrame.size.width = self.view.bounds.size.width - 29.5;
  textFrame.size.height = self.view.bounds.size.height;
  UIView *textView = [[UIView alloc] initWithFrame:CGRectMake(
    0.0, 0.0, textFrame.size.width, textFrame.size.height)];
  textView.backgroundColor = [UIColor whiteColor];

  UILabel *noteLabel = [[UILabel alloc] initWithFrame:CGRectMake(
    18.0, 16.0, textView.frame.size.width - 29.5, textView.frame.size.height)];
  noteLabel.text = [NSString stringWithFormat:@""
    "Rezepte werden mit der App \"Amiko Desitin\" oder \"CoMed Desitin\" "
    "erstellt. Mit Amiko/CoMed erstellte Rezepte haben immer die Datei-Endung "
    ".amk. Mit Amiko/CoMed erstellte Rezepte können mit der Generika-App "
    "geöffnet werden."];
  noteLabel.font = [UIFont systemFontOfSize:13.5];
  noteLabel.textAlignment = kTextAlignmentLeft;
  noteLabel.textColor = [UIColor blackColor];
  noteLabel.backgroundColor = [UIColor clearColor];
  noteLabel.lineBreakMode = NSLineBreakByWordWrapping;
  noteLabel.numberOfLines = 0;
  [noteLabel sizeToFit];

  [textView addSubview:noteLabel];
  [self.usageView addSubview:textView];
}

- (void)didRotate:(NSNotification *)notification
{
  [self layoutFrameAndViews];
}


#pragma mark - Action

- (void)closeUsageView
{
  [self.presentingViewController dismissViewControllerAnimated:YES
                                                    completion:nil];
}

@end
