//
//  WebViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController < UIWebViewDelegate, UIActionSheetDelegate > {
  UIBarButtonItem *_backBtn;
  NSString        *_history;
  UIWebView       *_webview;
}
- (void)loadURL:(NSURL*)url;
- (void)refresh;
@end
