//
//  PatinfoViewController.m
//  Generika
//
//  Created by b123400 on 2025/10/28.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "PatinfoViewController.h"
#import <WebKit/WKWebView.h>
#import "PatinfoChapterTableViewController.h"

@interface PatinfoViewController ()<PatinfoChapterTableViewControllerDelegate>

@property (weak, nonatomic) IBOutlet WKWebView *webView;

@property (strong, nonatomic) AmikoDBRow *amikoRow;

@end

@implementation PatinfoViewController

- (instancetype)initWithRow:(AmikoDBRow *)row {
    if (self = [super initWithNibName:@"PatinfoViewController" bundle:nil]) {
        self.amikoRow = row;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.webView loadHTMLString:self.htmlContent baseURL:nil];
    
    UIBarButtonItem *chapterItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"doc.plaintext"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(chapterButtonClicked:)];
    self.navigationItem.rightBarButtonItem = chapterItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = YES;
}

- (NSString *)htmlContent {
    NSString *colorSchemeFilename = @"color-scheme-light";
    UIUserInterfaceStyle osMode = [UITraitCollection currentTraitCollection].userInterfaceStyle;
    if (@available(iOS 13, *)) {
        if (osMode == UIUserInterfaceStyleDark) {
            colorSchemeFilename = @"color-scheme-dark";
        }
    }
    
    NSString *colorCssPath = [[NSBundle mainBundle] pathForResource:colorSchemeFilename ofType:@"css"];
    NSString *colorCss = [NSString stringWithContentsOfFile:colorCssPath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *amikoCssPath = [[NSBundle mainBundle] pathForResource:@"amiko_stylesheet" ofType:@"css"];
    NSString *amikoCss = [NSString stringWithContentsOfFile:amikoCssPath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *headHtml;
    {
        NSString *scalingMeta = @"<meta name=\"viewport\" content=\"initial-scale=1.0\" />";
        NSString *charsetMeta = @"<meta charset=\"utf-8\" />";
        NSString *colorSchemeMeta= @"<meta name=\"supported-color-schemes\" content=\"light dark\" />";
        headHtml = [NSString stringWithFormat:@"<head>%@\n%@\n%@\n<style type=\"text/css\">%@</style>\n<style type=\"text/css\">%@</style>\n</head>",
                    charsetMeta,
                    colorSchemeMeta,
                    scalingMeta,
                    colorCss,
                    amikoCss];
    }

    NSString * htmlStr = [self.amikoRow.content stringByReplacingOccurrencesOfString:@"<head></head>"
                                                                          withString:headHtml];
    return htmlStr;
}

- (void)chapterButtonClicked:(id)sender {
}

@end
