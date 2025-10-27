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

typedef enum : NSUInteger {
    PriceComparisonSortingName,
    PriceComparisonSortingAuth,
    PriceComparisonSortingSize,
    PriceComparisonSortingPrice,
    PriceComparisonSortingPercentage,
    PriceComparisonSortingSB
} PriceComparisonSorting;

@interface PriceComparisonViewController ()

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerHeightConstraint;

@property (nonatomic, assign) PriceComparisonSorting sorting;
@property (nonatomic, assign) BOOL isAsc;

@property (nonatomic, strong) UIBarButtonItem *sortBarButtonItem;
@property (nonatomic, strong) UIAction *nameAction;
@property (nonatomic, strong) UIAction *authAction;
@property (nonatomic, strong) UIAction *sizeAction;
@property (nonatomic, strong) UIAction *priceAction;
@property (nonatomic, strong) UIAction *percentageAction;
@property (nonatomic, strong) UIAction *sbAction;

@end

@implementation PriceComparisonViewController

- (instancetype)init {
    if (self = [super init]) {
        _sorting = PriceComparisonSortingPercentage;
        _isAsc = YES;
        self.hidesBottomBarWhenPushed = YES;
        self.tableView.rowHeight = UITableViewAutomaticDimension;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"PriceComparisonTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"tableCell"];
    
    self.nameAction = [UIAction actionWithTitle:@"Präparat" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        if (self.sorting == PriceComparisonSortingName) {
            self.isAsc = !self.isAsc;
        } else {
            self.sorting = PriceComparisonSortingName;
        }
    }];

    self.authAction = [UIAction actionWithTitle:@"Zulassungs­inhaber" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        if (self.sorting == PriceComparisonSortingAuth) {
            self.isAsc = !self.isAsc;
        } else {
            self.sorting = PriceComparisonSortingAuth;
        }
    }];
    
    self.sizeAction = [UIAction actionWithTitle:@"Packungs­grösse" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        if (self.sorting == PriceComparisonSortingSize) {
            self.isAsc = !self.isAsc;
        } else {
            self.sorting = PriceComparisonSortingSize;
        }
    }];
    
    self.priceAction = [UIAction actionWithTitle:@"PP" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        if (self.sorting == PriceComparisonSortingPrice) {
            self.isAsc = !self.isAsc;
        } else {
            self.sorting = PriceComparisonSortingPrice;
        }
    }];
    
    self.percentageAction = [UIAction actionWithTitle:@"Preisunterschied" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        if (self.sorting == PriceComparisonSortingPercentage) {
            self.isAsc = !self.isAsc;
        } else {
            self.sorting = PriceComparisonSortingPercentage;
        }
    }];
    self.percentageAction.state = UIMenuElementStateOn;
    
    self.sbAction = [UIAction actionWithTitle:@"Selbstbehalt" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        if (self.sorting == PriceComparisonSortingSB) {
            self.isAsc = !self.isAsc;
        } else {
            self.sorting = PriceComparisonSortingSB;
        }
    }];
    
    UIMenu *sortMenu = [UIMenu menuWithTitle:@"Sortierung" children:self.sortMenuActions];
    self.sortBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up.and.down.text.horizontal"] menu:sortMenu];

    self.navigationItem.rightBarButtonItem = self.sortBarButtonItem;
}

- (NSArray<UIAction *> *)sortMenuActions {
    return @[
        self.nameAction, self.authAction, self.sizeAction, self.priceAction, self.percentageAction, self.sbAction
    ];
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

- (void)setSorting:(PriceComparisonSorting)sorting {
    _sorting = sorting;
    self.comparisons = [self sortedComparisons:self.comparisons];
    
    for (UIAction *a in self.sortMenuActions) {
        a.state = UIMenuElementStateOff;
    }
    switch (sorting) {
        case PriceComparisonSortingName:
            self.nameAction.state = UIMenuElementStateOn;
            break;
        case PriceComparisonSortingAuth:
            self.authAction.state = UIMenuElementStateOn;
            break;
        case PriceComparisonSortingSize:
            self.sizeAction.state = UIMenuElementStateOn;
            break;
        case PriceComparisonSortingPrice:
            self.priceAction.state = UIMenuElementStateOn;
            break;
        case PriceComparisonSortingPercentage:
            self.percentageAction.state = UIMenuElementStateOn;
            break;
        case PriceComparisonSortingSB:
            self.sbAction.state = UIMenuElementStateOn;
            break;
    }
    UIMenu *sortMenu = [UIMenu menuWithTitle:@"Sortierung" children:self.sortMenuActions];
    self.sortBarButtonItem.menu = sortMenu;
}

- (void)setIsAsc:(BOOL)isAsc {
    _isAsc = isAsc;
    self.comparisons = [self sortedComparisons:self.comparisons];
}

- (NSArray<AmikoDBPriceComparison *> *)sortedComparisons:(NSArray<AmikoDBPriceComparison *> *)comparisons {
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"self"
                                                               ascending:self.isAsc
                                                              comparator:^NSComparisonResult(AmikoDBPriceComparison *obj1, AmikoDBPriceComparison *obj2) {
        switch (self.sorting) {
            case PriceComparisonSortingName:
                return [obj1.package.name compare:obj2.package.name];
            case PriceComparisonSortingAuth:
                return [obj1.package.parent.auth compare:obj2.package.parent.auth];
            case PriceComparisonSortingSize:
                return [obj1.package.dosage compare:obj2.package.dosage];
            case PriceComparisonSortingPrice:
                return [@([obj1.package.pp doubleValue]) compare:@([obj2.package.pp doubleValue])];
            case PriceComparisonSortingPercentage:
                return [@(obj1.priceDifferenceInPercentage) compare:@(obj2.priceDifferenceInPercentage)];
            case PriceComparisonSortingSB:
                return [@([[obj1.package.selbstbehalt stringByReplacingOccurrencesOfString:@"%" withString:@""] doubleValue])
                        compare:@([[obj2.package.selbstbehalt stringByReplacingOccurrencesOfString:@"%" withString:@""] doubleValue])];
        }
    }];
    return [comparisons sortedArrayUsingDescriptors:@[sortDesc]];
}

- (void)setShowAsTable:(BOOL)showAsTable {
    _showAsTable = showAsTable;
    if (showAsTable) {
        self.headerHeightConstraint.constant = 32;
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
