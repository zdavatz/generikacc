//
//  PriceComparisonViewController.m
//  Generika
//
//  Created by b123400 on 2025/10/26.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "PriceComparisonViewController.h"
#import "AmikoDatabase/AmikoDBRow.h"
#import "PriceComparisonTableViewCell.h"

@interface PriceComparisonViewController ()

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerHeightConstraint;

@end

@implementation PriceComparisonViewController

- (instancetype)init {
    if (self = [super init]) {
        self.hidesBottomBarWhenPushed = YES;
        self.tableView.rowHeight = UITableViewAutomaticDimension;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"PriceComparisonTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"tableCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadUIWithSize:self.view.frame.size];
    self.navigationController.toolbarHidden = YES;
}

- (void)setComparisons:(NSArray<AmikoDBPriceComparison *> *)comparisons {
    _comparisons = comparisons;
    [self.tableView reloadData];
}

- (void)setShowAsTable:(BOOL)showAsTable {
    _showAsTable = showAsTable;
    if (showAsTable) {
        self.headerHeightConstraint.constant = 50;
        self.headerView.hidden = NO;
    } else {
        self.headerView.hidden = YES;
        self.headerHeightConstraint.constant = 0;
    }
    [self.tableView reloadData];
}

- (void)reloadUIWithSize:(CGSize)size {
    if (size.width > 500) {
        self.showAsTable = YES;
    } else {
        self.showAsTable = NO;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self reloadUIWithSize:size];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.showAsTable) {
        return 1;
    }
    return self.comparisons.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.showAsTable) {
        return self.comparisons.count;
    }
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.showAsTable) {
        PriceComparisonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableCell" forIndexPath:indexPath];
        
        AmikoDBPriceComparison *c = self.comparisons[indexPath.row];
        
        cell.nameLabel.text = c.package.name;
        cell.authLabel.text = c.package.parent.auth;
        cell.sizeLabel.text = [NSString stringWithFormat:@"%@ %@", c.package.dosage, c.package.units];
        cell.priceLabel.text = c.package.pp;
        cell.percentageLabel.text = [NSString stringWithFormat:@"%.0f%%", floor(c.priceDifferenceInPercentage)];
        cell.sbLabell.text = c.package.selbstbehalt;
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        }
        
        AmikoDBPriceComparison *c = self.comparisons[indexPath.section];
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Präparat";
                cell.detailTextLabel.text = c.package.name;
                break;
            case 1:
                cell.textLabel.text = @"Zulassungs­inhaber";
                cell.detailTextLabel.text = c.package.parent.auth;
                break;
            case 2:
                cell.textLabel.text = @"Packungs­grösse";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", c.package.dosage, c.package.units];
                break;
            case 3:
                cell.textLabel.text = @"PP";
                cell.detailTextLabel.text = c.package.pp;
                break;
            case 4:
                cell.textLabel.text = @"% (Preisunterschied in Prozent)";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f%%", floor(c.priceDifferenceInPercentage)];
                break;
            case 5:
                cell.textLabel.text = @"SB";
                cell.detailTextLabel.text = c.package.selbstbehalt;
                break;
                
            default:
                break;
        }
        return cell;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
