//
//  WebViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 4/12/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate>
{
  NSMutableArray *_requests;
  NSString  *_history;

  UIActivityIndicatorView *_indicator;
  UIView *_indicatorBackground;
  UIWebView *_webview;
}
- (void)loadURL:(NSURL*)url;
@end
