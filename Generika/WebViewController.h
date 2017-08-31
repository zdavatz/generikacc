//
//  WebViewController.h
//  Generika
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//


@interface WebViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate>

- (void)loadURL:(NSURL*)url;

@end
