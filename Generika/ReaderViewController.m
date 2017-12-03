//
//  ReaderViewController.m
//  Generika
//
//  Copyright (c) 2014-2017 ywesee GmbH. All rights reserved.
//

#import "ReaderViewController.h"

@implementation ReaderViewController

// FIX
// Memory leak without release
// - http://sourceforge.net/p/zbar/patches/36/
// - https://github.com/ZBar/ZBar/blob/master/iphone/ZBarReaderViewController.m
- (void) loadView {
  self.view = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 320, 480)];
}

- (void) info {
  [self showHelpWithReason: @"INFO"];
}

// FIX
// Broken toolbar and button layout
// - https://github.com/ZBar/ZBar/blob/master/iphone/ZBarReaderViewController.m
- (void) initControls {
  if (!showsZBarControls && controls) {
    [controls removeFromSuperview];
    controls = nil;
  }
  if (!showsZBarControls) {
    return;
  }
  UIView *view = self.view;
  if (controls) {
    assert(controls.superview == view);
    [view bringSubviewToFront: controls];
    return;
  }

  CGRect r = view.bounds;
  r.size.height += 10;
  controls = [[UIView alloc] initWithFrame: r];

  // see Constant.m
  if (floor(NSFoundationVersionNumber) > kVersionNumber_iOS_6_1) {
    // iOS 7 or later
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { // iPad
      r.origin.y = view.bounds.size.height - 20;
      r.size.height = 21;
    } else {
      r.origin.y = view.bounds.size.height - 45;
      r.size.height = 45;
    }
  } else {

  }
  controls = [[UIView alloc] initWithFrame: r];
  controls.autoresizingMask =
    UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight |
    UIViewAutoresizingFlexibleTopMargin;
  controls.backgroundColor = [UIColor blackColor];

  UIToolbar *toolbar = [[UIToolbar alloc] init];
  r.origin.y = 0;
  toolbar.frame = r;
  toolbar.barStyle = UIBarStyleBlackOpaque;
  toolbar.autoresizingMask =
     UIViewAutoresizingFlexibleWidth |
     UIViewAutoresizingFlexibleHeight;

  // cancel
  UIButton *cancel = [UIButton buttonWithType:UIButtonTypeCustom];
  [cancel addTarget:self
          action:@selector(cancel)
          forControlEvents:UIControlEventTouchUpInside];
  [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
  CGRect buttonFrame = CGRectMake(0, 0, 60.0, 30.0);
  [cancel setFrame: buttonFrame];
  [cancel setTitleColor: [UIColor colorWithRed:34.0/255.0
                                         green:97.0/255.0
                                          blue:221.0/255.0
                                         alpha:1]
          forState:UIControlStateNormal];
  UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc]
    initWithCustomView:cancel];
  [cancelButtonItem setTitleTextAttributes:@{
    NSFontAttributeName:[UIFont fontWithName:@"Helvetica-Bold" size:14.0]}
                                  forState:UIControlStateNormal];
  // info
  UIButton *info = [UIButton buttonWithType:UIButtonTypeInfoLight];
  [info addTarget:self
        action:@selector(info)
        forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *infoButtonItem = [[UIBarButtonItem alloc]
      initWithCustomView:info];
  // space
  UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                         target:nil
                         action:nil];

  toolbar.items = [NSArray arrayWithObjects:
    cancelButtonItem,
    spaceItem,
    infoButtonItem, nil];

  [controls addSubview:toolbar];
  [view addSubview:controls];
}

@end
