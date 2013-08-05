//
//  WebViewController.m
//  generika
//
//  Created by Yasuhiro Asaka on 4/12/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import "WebViewController.h"

@class MasterViewController;
@implementation WebViewController

- (id)init
{
  self = [super initWithNibName:nil
                         bundle:nil];
  return self;
}

- (void)loadView
{
  [super loadView];
  _requests = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  _webview = [[UIWebView alloc] init];
  _webview.frame = screenBounds;
  _webview.scalesPageToFit = YES;
  _webview.delegate = self;
  self.view = _webview;
  UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                target:self
                                                                                action:@selector(showActions)];
  self.navigationItem.rightBarButtonItem = actionButton;
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"back"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(goBack)];
  self.navigationItem.leftBarButtonItem = backButton;
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}


# pragma mark - Action

- (void)loadURL:(NSURL *)url
{
  url = [url standardizedURL];
  _history = [url absoluteString];
  //DLog(@"load: %@", _history);
  [self refresh];
}

- (void)goBack
{
  int requests = [_requests count] - 1;
  //DLog(@"history counts: %d", requests);
  if (requests > 0) {
    [_requests removeObjectAtIndex:0];
    [_webview goBack];
  } else {
    MasterViewController *parent = [self.navigationController.viewControllers objectAtIndex:0];
    [self.navigationController popToViewController:(UIViewController *)parent animated:YES];
  }
}

- (void)refresh
{
  NSURL *url = [NSURL URLWithString: _history];
  NSURLRequest *request = [NSURLRequest requestWithURL: url];
  //DLog(@"request: %@", request);
  UIWebView *view = (UIWebView*)self.view;
  [view loadRequest:request];
}

- (void)showActions
{
  UIActionSheet *sheet = [[UIActionSheet alloc] init];
  sheet.delegate = self;
  sheet.title = [[_webview.request URL] absoluteString];
  [sheet addButtonWithTitle:@"Open in Safari"];
  [sheet addButtonWithTitle:@"Back to List"];
  [sheet addButtonWithTitle:@"Cancel"];
  sheet.destructiveButtonIndex = 0;
  sheet.cancelButtonIndex      = 2;
  [sheet showInView:_webview];
}


#pragma mark - ActionSheet

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)index
{
  //DLog(@"sheet button index: %d", index);
  if (index == sheet.destructiveButtonIndex) {
    [[UIApplication sharedApplication] openURL:[_webview.request URL]];
  } else if (index == 1) { //back to list
    MasterViewController *parent = [self.navigationController.viewControllers objectAtIndex:0];
    [self.navigationController popToViewController:(UIViewController *)parent animated:YES];
  }
}


#pragma mark - Webview

- (void)webViewDidStartLoad:(UIWebView *)view
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)view
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  NSString *title = [view stringByEvaluatingJavaScriptFromString:@"document.title"];
  if (title) {
    self.title = title;
  }
}

- (void)webView:(UIWebView *)view didFailLoadWithError:(NSError *)err
{
  [_requests removeObjectAtIndex:0];
  //DLog(@"loading: %d", view.loading);
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
  //DLog(@"url: %@", url);
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
    [_requests insertObject:url atIndex:0];
  default:
    break;
  }
  if (result) {
    self.title = [url absoluteString];
  }
  return(result);
}

@end
