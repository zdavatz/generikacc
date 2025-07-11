//
//  SettingsProfileTableViewController.m
//  Generika
//
//  Created by b123400 on 2025/03/27.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "SettingsProfileTableViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "SettingsManager.h"
#import "SessionManager.h"
#import <AuthenticationServices/AuthenticationServices.h>

typedef enum : NSUInteger {
    SettingsProfileTableViewControllerRowGLN = 0,
    SettingsProfileTableViewControllerRowZSR = 1,
    SettingsProfileTableViewControllerRowZRCustomerNumber = 2,
} SettingsProfileTableViewControllerRow;

typedef enum : NSUInteger {
    SettingsProfileTableViewControllerLoginRowUsername = 0,
    SettingsProfileTableViewControllerLoginRowFirstName = 1,
    SettingsProfileTableViewControllerLoginRowLastName = 2,
    SettingsProfileTableViewControllerLoginRowEmail = 3,
} SettingsProfileTableViewControllerLoginRow;

@interface SettingsProfileTableViewController () <UITextFieldDelegate, ASWebAuthenticationPresentationContextProviding>

@property (nonatomic, strong) NSMutableDictionary *keychainDict;
@property (nonatomic, strong) SessionAccount *account;

@end

@implementation SettingsProfileTableViewController

- (instancetype)initWithKeychainDict:(NSDictionary *)dict {
    if ([super initWithStyle:UITableViewStyleGrouped]) {
        self.keychainDict = [dict mutableCopy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    self.title = NSLocalizedString(@"Profile", @"");
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 3;
        case 1: {
            BOOL loggedIn = self.account;
            if (loggedIn && self.account) {
                return 4;
            } else  {
                return 0;
            }
        case 2:
            return 1;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isLoggedIn = !!self.account;
    
    if (indexPath.section == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"login"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"login"];
        }
        cell.textLabel.text = isLoggedIn ? @"Abmeldung" : @"Anmelden";
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        cell.selectedBackgroundView = [[UIView alloc] init]; // Clear view
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
        [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.delegate = self;
        textField.returnKeyType = UIReturnKeyDone;
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
    
    if (indexPath.section == 0) {
        [textField setEnabled:YES];
        switch (indexPath.row) {
            case SettingsProfileTableViewControllerRowGLN:
                cell.textLabel.text = @"GLN";
                textField.text = [userDefaults stringForKey:@"profile.gln"] ?: @"";
                break;
            case SettingsProfileTableViewControllerRowZSR:
                cell.textLabel.text = @"ZSR";
                textField.text = self.keychainDict[KEYCHAIN_KEY_ZSR] ?: @"";
                break;
            case SettingsProfileTableViewControllerRowZRCustomerNumber:
                cell.textLabel.text = @"ZR Kundennummer";
                textField.text = self.keychainDict[KEYCHAIN_KEY_ZR_CUSTOMER_NUMBER] ?: @"";
                break;
        }
    } else if (indexPath.section == 1) {
        [textField setEnabled:NO];
        switch (indexPath.row) {
            case SettingsProfileTableViewControllerLoginRowUsername:
                cell.textLabel.text = @"Username";
                textField.text = self.account.username;
                break;
            case SettingsProfileTableViewControllerLoginRowFirstName:
                cell.textLabel.text = @"First Name";
                textField.text = self.account.firstName;
                break;
            case SettingsProfileTableViewControllerLoginRowLastName:
                cell.textLabel.text = @"Last Name";
                textField.text = self.account.lastName;
                break;
            case SettingsProfileTableViewControllerLoginRowEmail:
                cell.textLabel.text = @"Email";
                textField.text = self.account.email;
                break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    BOOL isLoggedIn = !!self.account;
    
    if (indexPath.section == 2) {
        if (isLoggedIn) {
            // Logout
        } else {
            [self login];
        }
    }
    
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
        default:
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
    
    switch (textField.tag) {
        case SettingsProfileTableViewControllerRowZSR:
            if (![textField.text isEqual:self.keychainDict[KEYCHAIN_KEY_ZSR]]) {
                self.keychainDict[KEYCHAIN_KEY_ZSR] = [SettingsManager shared].zsrNumber = textField.text;
            }
            break;
        case SettingsProfileTableViewControllerRowZRCustomerNumber:
            if (![textField.text isEqual:self.keychainDict[KEYCHAIN_KEY_ZR_CUSTOMER_NUMBER]]) {
                self.keychainDict[KEYCHAIN_KEY_ZR_CUSTOMER_NUMBER] = [SettingsManager shared].zrCustomerNumber = textField.text;
            }
            break;
        default:
            break;
    }
}

- (void)login {
    __weak typeof(self) _self = self;
    [[SessionManager shared] loginWithViewController:self callback:^(SessionToken * _Nullable token, NSError * _Nullable error) {
        [[SessionManager shared] fetchAccountWithToken:token callback:^(SessionAccount * _Nullable userInfo, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _self.account = userInfo;
                [_self.tableView reloadData];
            });
        }];
    }];
}

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session {
    return self.view.window;
}

@end
