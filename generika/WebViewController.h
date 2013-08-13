//
//  WebViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 4/12/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

@interface WebViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate>
{
  UIActivityIndicatorView *_indicator;
  UIView *_indicatorBackground;
  UIWebView *_browserView;

  NSMutableArray *_requests;
  NSString  *_history;
}

@property (nonatomic, strong, readonly) UIActivityIndicatorView *indicator;
@property (nonatomic, strong, readonly) UIView *indicatorBackground;
@property (nonatomic, strong, readonly) UIWebView *broserView;
@property (nonatomic, strong, readonly) NSMutableArray *requests;
@property (nonatomic, strong, readonly) NSString *history;

- (void)loadURL:(NSURL*)url;

@end
