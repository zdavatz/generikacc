//
//  PatinfoChapterTableViewController.m
//  Generika
//
//  Created by b123400 on 2025/10/28.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "PatinfoChapterTableViewController.h"

@interface PatinfoChapterTableViewController ()

@property (nonatomic, strong) AmikoDBRow *amikoRow;

@property (nonatomic, strong) NSArray<NSString *> *chapterIds;
@property (nonatomic, strong) NSArray<NSString *> *chapterTitles;

@end

@implementation PatinfoChapterTableViewController

- (instancetype)initWithAmikoRow:(AmikoDBRow *)row {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.amikoRow = row;
    }
    return self;
}

- (void)setAmikoRow:(AmikoDBRow *)amikoRow {
    _amikoRow = amikoRow;
    self.chapterIds = amikoRow.chapterIds;
    self.chapterTitles = amikoRow.chapterTitles;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:@"Schließen"
                                                                  style:UIBarButtonItemStyleDone
                                                                 target:self
                                                                 action:@selector(close)];
    self.navigationItem.leftBarButtonItem = closeItem;
}

- (void)close {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chapterIds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = self.chapterTitles[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate chapterViewController:self didSelectedChapter:self.chapterIds[indexPath.row]];
}

@end
