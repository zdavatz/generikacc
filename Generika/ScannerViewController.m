//
//  ScannerViewController.m
//  Generika
//
//  Created by b123400 on 2018/11/27.
//  Copyright © 2018 ywesee GmbH. All rights reserved.
//

#import "ScannerViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ScannerViewController ()

@property (atomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (atomic, strong) AVCaptureSession *captureSession;
@property (atomic, strong) UIToolbar *toolbar;

@end

@implementation ScannerViewController

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];

    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            [self setupCaptureSession];
            break;
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self setupCaptureSession];
                } else {
                    // TODO: display permission denined message
                }
            }];
            break;
        }
        default:
            break;
    }
}

- (void)setupCaptureSession {
    self.captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                                 mediaType:AVMediaTypeVideo
                                                                  position:AVCaptureDevicePositionBack];
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                        error:&error];
    if (error != nil) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                       message:error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
        return;
    }

    if ([self.captureSession canAddInput:input]) {
        [self.captureSession addInput:input];
    }
    [self.captureSession startRunning];

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    [self.view.layer addSublayer:self.previewLayer];
    self.previewLayer.frame = self.view.bounds;

    self.toolbar = [[UIToolbar alloc] init];
    self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    self.toolbar.barStyle = UIBarStyleBlackTranslucent;
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(cancel)];
    [self.toolbar setItems:@[cancel,
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                           target:nil
                                                                           action:nil]]];
    [self.view addSubview:self.toolbar];
}

- (void)viewDidLayoutSubviews {
    self.previewLayer.frame = self.view.bounds;
    self.toolbar.frame = CGRectMake(0,
                                    CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.toolbar.frame),
                                    CGRectGetWidth(self.view.bounds),
                                    CGRectGetHeight(self.toolbar.frame));
}

- (void)dealloc {
    [self.captureSession stopRunning];
    self.captureSession = nil;
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

@end
