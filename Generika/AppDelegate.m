//
//  AppDelegate.m
//  Generika
//
//  Copyright (c) 2012-2017 ywesee GmbH. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "ProductManager.h"
#import "ReceiptManager.h"


@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
  didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // defaults
  NSDictionary *userDefaultsDefaults = [NSDictionary
    dictionaryWithObjectsAndKeys:
      [NSNumber numberWithInteger:0],
      @"search.result.type",
      [NSNumber numberWithInteger:0],
      @"search.result.lang",
      nil];
  [[NSUserDefaults standardUserDefaults]
    registerDefaults:userDefaultsDefaults];

  // load products & receipts
  [[ProductManager sharedManager] load];
  [[ReceiptManager sharedManager] load];

  // view
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  _window = [[UIWindow alloc] initWithFrame:screenBounds];
  MasterViewController *masterViewController = [
    [MasterViewController alloc] init];
  _navigationController = [[UINavigationController alloc]
    initWithRootViewController:masterViewController];
  _navigationController.view.autoresizingMask = \
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  // receipt
  NSURL *url = (NSURL *)[launchOptions
                         valueForKey:UIApplicationLaunchOptionsURLKey];
  if (url != nil && [url isFileURL]) {
    DLogMethod
    [self importURL:url to:masterViewController];
  }

  // does not work for auto rotation
	//[_window addSubview:_navigationController.view];
  _window.rootViewController = _navigationController;
	[_window makeKeyAndVisible];

  return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  if (url != nil && [url isFileURL]) {
    DLogMethod
    MasterViewController *masterViewController = (MasterViewController *)[
      _navigationController.viewControllers objectAtIndex:0];
    [self importURL:url to:masterViewController];
  }
  return YES;
}

- (void)importURL:(NSURL *)url to:(MasterViewController *)masterViewController
{
  // The handling for `*.amk` receipt file (defined in Generika-info.plist)
  // This block imports file from amiko (`RZ_YYYY-MM-DDTNNNNNN.amk`).
  NSString *fileName = [[url absoluteString] lastPathComponent];
  NSString *extName = [url pathExtension];

  // check prefix und extension of file format like: `RZ_(.*)?.amk`
  if ([extName isEqualToString:@"amk"] && [fileName hasPrefix:@"RZ_"]) {
    DLog(@"fileName -> %@", fileName);

    [masterViewController setSelectedSegmentIndex:(NSInteger)1];
    [masterViewController handleOpenAmkFileURL:url animated:NO];
  }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state.
  // This can occur for certain types of temporary interruptions (such as an
  // incoming phone call or SMS message) or when the user quits the application
  // and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down
  // OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate
  // timers, and store enough application state information to restore your
  // application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called
  // instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive
  // state; here you can undo many of the changes made on entering the
  // background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the
  // application was inactive. If the application was previously in the
  // background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if
  // appropriate. See also applicationDidEnterBackground:.
}

@end
