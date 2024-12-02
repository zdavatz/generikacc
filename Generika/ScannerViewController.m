//
//  ScannerViewController.m
//  Generika
//
//  Created by b123400 on 2018/11/27.
//  Copyright © 2018 ywesee GmbH. All rights reserved.
//

#import "ScannerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Vision/Vision.h>
#import "DataMatrixResult.h"
#import "BarcodeExtractor.h"
#import "Helper.h"

@interface ScannerViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (atomic) BOOL didSendResult;
// atomic view size for calculating coordinates in background thread
@property (atomic) CGSize viewSize;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) UIToolbar *toolbar;

@property (nonatomic) CAShapeLayer *shapeLayer;

@end

@implementation ScannerViewController

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.backgroundColor = [UIColor blackColor];

    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
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
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.toolbar
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.toolbar
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.toolbar
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view.safeAreaLayoutGuide
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:0]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewSize = self.view.bounds.size;
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            [self setupCaptureSession];
            break;
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self setupCaptureSession];
                } else {
                    [self displayError:NSLocalizedString(@"Permission denined",@"")];
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
        [self displayError:error.localizedDescription];
        return;
    }

    if ([self.captureSession canAddInput:input]) {
        [self.captureSession addInput:input];
    }

    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    [output setSampleBufferDelegate:self
                              queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    if ([self.captureSession canAddOutput:output]) {
        [self.captureSession addOutput:output];
    }

    [self.captureSession startRunning];

    for (AVCaptureConnection *connection in [output connections]){
        connection.videoOrientation = [self currentVideoOrientation];
    }

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.connection.videoOrientation = [self currentVideoOrientation];

    self.shapeLayer = [CAShapeLayer layer];
    self.shapeLayer.fillColor = nil;
    self.shapeLayer.opacity = 1.0;
    self.shapeLayer.strokeColor = [UIColor greenColor].CGColor;
    self.shapeLayer.lineWidth = 2;
    [self.view.layer addSublayer:self.shapeLayer];

    [self.view bringSubviewToFront:self.toolbar];
}

- (void)viewDidLayoutSubviews {
    self.viewSize = self.view.bounds.size;
    self.shapeLayer.frame = self.view.bounds;
    self.previewLayer.frame = self.view.bounds;
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if (self.didSendResult) return;
    VNImageRequestHandler *requestHandler =
        [[VNImageRequestHandler alloc] initWithCVPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)
                                                     options:@{}];
    VNDetectBarcodesRequest *barcodeRequest = [[VNDetectBarcodesRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error) {
        if (!request.results.count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.shapeLayer.path = nil;
            });
            return;
        }
        if (error != nil) {
            [self displayError:error.localizedDescription];
        }
        UIImage *image = [Helper sampleBufferToUIImage:sampleBuffer];
        for (VNBarcodeObservation *result in request.results) {
            CGPoint tl = result.topLeft, tr = result.topRight, bl = result.bottomLeft, br = result.bottomRight;
            dispatch_async(dispatch_get_main_queue(), ^{
                UIBezierPath *path = [UIBezierPath bezierPath];
                [path moveToPoint:[self relativePointToAbsolutePoint:tl withImageSize:image.size viewSize:self.viewSize]];
                [path addLineToPoint:[self relativePointToAbsolutePoint:tr withImageSize:image.size viewSize:self.viewSize]];
                [path addLineToPoint:[self relativePointToAbsolutePoint:br withImageSize:image.size viewSize:self.viewSize]];
                [path addLineToPoint:[self relativePointToAbsolutePoint:bl withImageSize:image.size viewSize:self.viewSize]];
                [path closePath];
                self.shapeLayer.path = path.CGPath;
            });
           if (result.symbology == VNBarcodeSymbologyDataMatrix) {
               BarcodeExtractor *extractor = [[BarcodeExtractor alloc] init];
               DataMatrixResult *r = [extractor extractGS1DataFrom:result.payloadStringValue];
               [self.delegate scannerViewController:self
                               didScannedDataMatrix:r
                                          withImage:image];
           } else if (result.symbology == VNBarcodeSymbologyEAN13) {
               [self.delegate scannerViewController:self
                                    didScannedEan13:result.payloadStringValue
                                          withImage:image];
           } else if (result.symbology == VNBarcodeSymbologyQR) {
               EPrescription *prescription = [self parseEPrescription:result.payloadStringValue];
               if (prescription) {
                   [self.delegate scannerViewController:self
                                       didEPrescription:prescription
                                              withImage:image];
               }
           }
            self.didSendResult = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.captureSession stopRunning];
            });
            break;
        }
    }];
    barcodeRequest.symbologies = @[VNBarcodeSymbologyEAN13, VNBarcodeSymbologyDataMatrix, VNBarcodeSymbologyQR];
    NSError *error = nil;
    [requestHandler performRequests:@[barcodeRequest] error:&error];
    if (error != nil) {
        [self displayError:error.localizedDescription];
    }
}

- (void)displayError:(NSString *)errorMessage {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                       message:errorMessage
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
    });
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (EPrescription *)parseEPrescription:(NSString *)str {
    EPrescription *prescription = [[EPrescription alloc] initWithCHMED16A1String:str];
    return prescription;
}

- (void)dealloc {
    [self.captureSession stopRunning];
    self.captureSession = nil;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    AVCaptureConnection *connection = self.previewLayer.connection;
    connection.videoOrientation = [self currentVideoOrientation];

    for (AVCaptureConnection *connection in [[[self.captureSession outputs] firstObject] connections]){
        connection.videoOrientation = [self currentVideoOrientation];
    }
}

- (AVCaptureVideoOrientation)currentVideoOrientation {
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
    }
    return AVCaptureVideoOrientationPortrait;
}

- (CGPoint)relativePointToAbsolutePoint:(CGPoint)point withImageSize:(CGSize)imageSize viewSize:(CGSize)viewSize {
    CGFloat scale = MAX(viewSize.width / imageSize.width, viewSize.height / imageSize.height);
    CGFloat trimmedX = (imageSize.width * scale - viewSize.width) / 2;
    CGFloat trimmedY = (imageSize.height * scale - viewSize.height) / 2;
    point = CGPointMake(point.x, 1.0 - point.y);
    return CGPointMake(point.x * imageSize.width * scale - trimmedX,
                       point.y * imageSize.height * scale - trimmedY);
}

@end
