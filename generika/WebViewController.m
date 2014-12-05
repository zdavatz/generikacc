//
//  WebViewController.m
//  Generika
//
//  Created by Yasuhiro Asaka on 4/12/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WebViewController.h"


@class MasterViewController;

@interface WebViewController ()

@property (nonatomic, strong, readwrite) UIActivityIndicatorView *indicator;
@property (nonatomic, strong, readwrite) UIView *indicatorBackground;
@property (nonatomic, strong, readwrite) UIWebView *browserView;
@property (nonatomic, strong, readwrite) NSMutableArray *requests;
@property (nonatomic, strong, readwrite) NSString *history;

- (void)goBack;
- (void)refresh;
- (void)showActions;
- (void)layoutIndicator;

@end

@implementation WebViewController

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  _requests = [[NSMutableArray alloc] init];
  return self;
}

- (void)dealloc
{
  [_requests removeAllObjects], _requests = nil;
  _history = nil;
  [self didReceiveMemoryWarning];
}

- (void)didReceiveMemoryWarning
{
  if ([self isViewLoaded] && [self.view window] == nil) {
    _browserView         = nil;
    _indicatorBackground = nil;
    _indicator           = nil;
  }
  [super didReceiveMemoryWarning];
}

- (void)loadView
{
  [super loadView];
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  self.browserView = [[UIWebView alloc] initWithFrame:screenBounds];
  self.browserView.scalesPageToFit = YES;
  self.browserView.delegate = self;
  self.view = self.browserView;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // navigationbar
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"back"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(goBack)];
  self.navigationItem.leftBarButtonItem = backButton;
  UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                target:self
                                                                                action:@selector(showActions)];
  self.navigationItem.rightBarButtonItem = actionButton;
  // indicator
  self.indicatorBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100.0, 100.0)];
  self.indicatorBackground.backgroundColor = [UIColor blackColor];
  self.indicatorBackground.alpha = 0.6;
  [[self.indicatorBackground layer] setCornerRadius:5.0];
  [self.browserView addSubview:self.indicatorBackground];
  self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  [self.browserView addSubview:self.indicator];
  [self layoutIndicator];
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] addObserver:self
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}

- (void)didRotate:(NSNotification *)notification
{
  [self layoutIndicator];
}

- (void)layoutIndicator {
  if (self.indicator) {
    self.indicator.center = self.browserView.center;
    self.indicatorBackground.center = self.browserView.center;
  }
}


# pragma mark - Action

- (void)loadURL:(NSURL *)url
{
  //reset requests
  if (self.requests) {
    [self.requests removeAllObjects];
  }
  url = [url standardizedURL];
  self.history = [url absoluteString];
  [self refresh];
}

- (void)goBack
{
  int requests_count = [self.requests count] - 1;
  if (requests_count > 0) {
    [self.requests removeObjectAtIndex:0];
    [self.browserView goBack];
  } else {
    MasterViewController *parent = [self.navigationController.viewControllers objectAtIndex:0];
    [self.navigationController popToViewController:(UIViewController *)parent animated:YES];
  }
}

- (void)refresh
{
  NSURL *url = [NSURL URLWithString: self.history];
  NSURLRequest *request = [NSURLRequest requestWithURL: url];
  UIWebView *view = (UIWebView*)self.view;
  // open blank page once
  [view loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
  [view loadRequest:request];
}

- (void)showActions
{
  UIActionSheet *sheet = [[UIActionSheet alloc] init];
  sheet.delegate = self;
  sheet.title = [[self.browserView.request URL] absoluteString];
  [sheet addButtonWithTitle:@"Open in Safari"];
  [sheet addButtonWithTitle:@"Back to List"];
  [sheet addButtonWithTitle:@"Cancel"];
  sheet.destructiveButtonIndex = 0;
  sheet.cancelButtonIndex      = 2;
  [sheet showInView:self.browserView];
}


#pragma mark - ActionSheet

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)index
{
  if (index == sheet.destructiveButtonIndex) {
    [[UIApplication sharedApplication] openURL:[self.browserView.request URL]];
  } else if (index == 1) { //back to list
    MasterViewController *parent = [self.navigationController.viewControllers objectAtIndex:0];
    [self.navigationController popToViewController:(UIViewController *)parent animated:YES];
  }
}


#pragma mark - Webview

- (void)webViewDidStartLoad:(UIWebView *)view
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  [self layoutIndicator];
  self.indicatorBackground.hidden = NO;
  [self.indicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)view
{
  [self.indicator stopAnimating];
  self.indicatorBackground.hidden = YES;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  NSString *title = [view stringByEvaluatingJavaScriptFromString:@"document.title"];
  if (title) {
    self.title = title;
  }
}

- (void)webView:(UIWebView *)view didFailLoadWithError:(NSError *)err
{
  [self.indicator stopAnimating];
  self.indicatorBackground.hidden = YES;

  int requests_count = [self.requests count];
  if (requests_count > 0) {
    [self.requests removeObjectAtIndex:0];
  }
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to open"
                                                  message:@"Error"
                                                 delegate:nil
                                        cancelButtonTitle:@"Cancel"
                                        otherButtonTitles:nil];
  [alert show];
}

- (BOOL)webView:(UIWebView *)view shouldStartLoadWithRequest:(NSURLRequest *)req
                                             navigationType:(UIWebViewNavigationType) type
{
  if (view.loading) {
    return(YES);
  }

  NSURL *url = [[req URL] standardizedURL];
  BOOL result = YES;
  switch(type)
  {
  case UIWebViewNavigationTypeBackForward:
  case UIWebViewNavigationTypeReload:
    break;
  case UIWebViewNavigationTypeLinkClicked:
  case UIWebViewNavigationTypeFormSubmitted:
  case UIWebViewNavigationTypeFormResubmitted:
  case UIWebViewNavigationTypeOther:
    [self.requests insertObject:url atIndex:0];
  default:
    break;
  }
  if (result) {
    self.title = [url absoluteString];
  }
  return(result);
}

@end
