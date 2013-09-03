//
//  WebViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 4/12/12.
//  Copyright (c) 2012 ywesee GmbH. All rights reserved.
//


@interface WebViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate>

- (void)loadURL:(NSURL*)url;

@end
