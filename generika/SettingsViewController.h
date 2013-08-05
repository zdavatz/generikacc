//
//  SettingsViewController.h
//  generika
//
//  Created by Yasuhiro Asaka on 08/05/13.
//  Copyright (c) 2013 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
  UITableView *_optionsView;
  UILabel *_sectionLabel;
  UILabel *_nameLabel;
}

@end
