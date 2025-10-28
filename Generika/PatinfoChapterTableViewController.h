//
//  PatinfoChapterTableViewController.h
//  Generika
//
//  Created by b123400 on 2025/10/28.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AmikoDatabase/AmikoDBRow.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PatinfoChapterTableViewControllerDelegate <NSObject>

- (void)chapterViewController:(id)sender didSelectedChapter:(NSString *)chapterId;

@end

@interface PatinfoChapterTableViewController : UITableViewController

@property (nonatomic, weak) id<PatinfoChapterTableViewControllerDelegate> delegate;

- (instancetype)initWithAmikoRow:(AmikoDBRow *)row;

@end

NS_ASSUME_NONNULL_END
