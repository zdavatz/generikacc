//
//  SettingsProfileTableViewController.m
//  Generika
//
//  Created by b123400 on 2025/03/27.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "SettingsProfileTableViewController.h"

typedef enum : NSUInteger {
    SettingsProfileTableViewControllerRowGLN = 0,
    SettingsProfileTableViewControllerRowZSR = 1,
    SettingsProfileTableViewControllerRowZRCustomerNumber = 2,
} SettingsProfileTableViewControllerRow;

@interface SettingsProfileTableViewController () <UITextFieldDelegate>

@end

@implementation SettingsProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    self.title = NSLocalizedString(@"Profile", @"");
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        cell.selectedBackgroundView = [[UIView alloc] init]; // Clear view
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
        [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.delegate = self;
        textField.returnKeyType = UIReturnKeyDone;
//        textField.tag = 3;
        [textField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UIAxisHorizontal];
        textField.textAlignment = NSTextAlignmentRight;
        textField.translatesAutoresizingMaskIntoConstraints = NO;
//        textField.placeholder = @"...";
        [cell.contentView addSubview:textField];
        
        [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                         attribute:NSLayoutAttributeLeading
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cell.textLabel
                                                         attribute:NSLayoutAttributeTrailing
                                                        multiplier:1
                                                          constant:8]];
        [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cell.contentView
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1
                                                          constant:8]];
        [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cell.contentView
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1
                                                          constant:-8]];
        [cell addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                         attribute:NSLayoutAttributeTrailing
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cell.contentView.safeAreaLayoutGuide
                                                         attribute:NSLayoutAttributeTrailing
                                                        multiplier:1
                                                          constant:-16]];
    }
    
    UITextField *textField = nil;
    for (UIView *v in cell.contentView.subviews) {
        if ([v isKindOfClass:[UITextField class]]) {
            textField = v;
            break;
        }
    }
    textField.tag = indexPath.row;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    switch (indexPath.row) {
        case SettingsProfileTableViewControllerRowGLN:
            cell.textLabel.text = @"GLN";
            textField.text = [userDefaults stringForKey:@"profile.gln"] ?: @"";
            break;
        case SettingsProfileTableViewControllerRowZSR:
            cell.textLabel.text = @"ZSR";
            textField.text = [userDefaults stringForKey:@"profile.zsr"] ?: @"";
            break;
        case SettingsProfileTableViewControllerRowZRCustomerNumber:
            cell.textLabel.text = @"ZR Kundennummer";
            textField.text = [userDefaults stringForKey:@"profile.zrCustomerNumber"] ?: @"";
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UITextField *textField = nil;
    for (UIView *v in cell.contentView.subviews) {
        if ([v isKindOfClass:[UITextField class]]) {
            textField = v;
            break;
        }
    }
    [textField becomeFirstResponder];
}

- (void)textFieldDidChange:(UITextField *)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    switch (sender.tag) {
        case SettingsProfileTableViewControllerRowGLN:
            [userDefaults setObject:sender.text forKey:@"profile.gln"];
            break;
        case SettingsProfileTableViewControllerRowZSR:
            [userDefaults setObject:sender.text forKey:@"profile.zsr"];
            break;
        case SettingsProfileTableViewControllerRowZRCustomerNumber:
            [userDefaults setObject:sender.text forKey:@"profile.zrCustomerNumber"];
            break;
    }
    [userDefaults synchronize];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField.tag == SettingsProfileTableViewControllerRowGLN) {
        self.navigationItem.hidesBackButton = YES;
        self.modalInPresentation = YES;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.tag == SettingsProfileTableViewControllerRowGLN && textField.text.length != 0) {
        NSString *trimmed = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
        if (textField.text.length != 13 || trimmed.length != 0) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:@"GLN must be a 13 digit number"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                [textField becomeFirstResponder];
            }]];
            [self presentModalViewController:alert animated:YES];
        }
    }
    self.navigationItem.hidesBackButton = NO;
    self.modalInPresentation = NO;
}

@end
