//
//  WebViewController.m
//  generika
//
//  Created by Yasuhiro Asaka on 4/12/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import "WebViewController.h"

@implementation WebViewController

- (id)init
{
  self = [super initWithNibName: nil
                         bundle: nil];
  return self;
}

- (void)loadView
{
  [super loadView];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  _webview = [[UIWebView alloc] init];
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  _webview.frame = screenBounds;
  _webview.scalesPageToFit = YES;
  _webview.delegate = self;
  self.view = _webview;

  _backBtn = 
    [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem: UIBarButtonSystemItemAction
                           target: self
                           action: @selector(goBack)];
  _backBtn.enabled = NO;

  CGRect frame = self.view.bounds;
  UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:frame];
  frame.size = [toolBar sizeThatFits:frame.size];
  frame.origin.y = self.view.bounds.size.height - frame.size.height;
  [toolBar setFrame:frame];
  [toolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];

  [toolBar setItems:
    [NSArray arrayWithObjects:
        _backBtn,
        [[UIBarButtonItem alloc]
          initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                               target: nil
                               action: nil] ,
        [[UIBarButtonItem alloc]
          initWithBarButtonSystemItem: UIBarButtonSystemItemAction
                               target: self
                               action: @selector(showActions)],
        nil]];
  [self.view addSubview:toolBar];
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

- (void)loadURL:(NSURL*)url
{
  url = [url standardizedURL];
  _history = [url absoluteString];
  DLog(@"load: %@", _history);
  _backBtn.enabled = NO;
  [self refresh];
}

- (void)refresh
{
  // TODO reachable check
  NSURL *url = [NSURL URLWithString: _history];
  NSURLRequest *request = [NSURLRequest requestWithURL: url];
  //DLog(@"request: %@", request);
  UIWebView *view = (UIWebView*)self.view;
  [view loadRequest:request];
}

#pragma mark - Webview

- (void)webViewDidStartLoad:(UIWebView*)view
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView*)view
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  _backBtn.enabled = view.canGoBack;
  NSString *title = [view stringByEvaluatingJavaScriptFromString:@"document.title"];
  if (title) {
    self.title = title;
  }
  //DLog(@"canGoBack: %d", view.canGoBack);
}

- (void)webView:(UIWebView*)view didFailLoadWithError:(NSError*)err
{
  //DLog(@"loading: %d", view.loading);
  //DLog(@"canGoBack: %d", view.canGoBack);
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to open"
                                                  message:@"Error"
                                                 delegate:nil
                                        cancelButtonTitle:@"Cancel"
                                        otherButtonTitles:nil];
  [alert show];
}

- (BOOL)webView:(UIWebView*)view shouldStartLoadWithRequest:(NSURLRequest*)req
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
  case UIWebViewNavigationTypeLinkClicked:
    break;
  case UIWebViewNavigationTypeBackForward:
    _backBtn.enabled = view.canGoBack;
    break;
  case UIWebViewNavigationTypeReload:
  case UIWebViewNavigationTypeFormSubmitted:
  case UIWebViewNavigationTypeFormResubmitted:
  case UIWebViewNavigationTypeOther:
  default:
    break;
  }

  if (result) {
    self.title = [url absoluteString];
  }
  return(result);
}

@end
