//
//  DetailViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (retain, nonatomic) id detailItem;

@property (retain, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
