//
//  MainViewController.m
//  MCDemo
//
//  Created by Pandara on 16/6/21.
//  Copyright © 2016年 Pandara. All rights reserved.
//

#import "MainViewController.h"
#import "AppConstant.h"
#import "ConnectivityManager.h"
#import "Masonry.h"
#import "AppMacro.h"
@import AVFoundation;
#import "AppHelper.h"

@interface MainViewController () <ConnectivityManagerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) ConnectivityManager *connectManager;

@property (nonatomic, strong) UIView *videoPreview;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_queue_t bufferQueue;

@property (nonatomic, strong) UIButton *captureButton;
@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.connectManager = [ConnectivityManager new];
    self.connectManager.delegate = self;
    [self.connectManager setLogLevel:1];
    
    [self setupTipLabel];
    [self setupCaptureButton];
}

#pragma mark - UI
- (void)setupTipLabel
{
    self.tipLabel = [[UILabel alloc] init];
    self.tipLabel.backgroundColor = UIColorFromRGBA(52, 73, 94, 1);
    self.tipLabel.textColor = [UIColor whiteColor];
    self.tipLabel.layer.cornerRadius = 5.0f;
    self.tipLabel.clipsToBounds = YES;
    self.tipLabel.font = [UIFont systemFontOfSize:15];
    self.tipLabel.text = @"Waiting for connection";
    self.tipLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.tipLabel];
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.equalTo([NSValue valueWithCGSize:CGSizeMake(200, 40)]);
    }];
    
}

- (void)hideTipLabel
{
    if (self.tipLabel.alpha == 0) {
        return;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.tipLabel.alpha = 0;
    }];
}

- (void)setupPreviewImageView
{
    self.previewImageView = [UIImageView new];
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.previewImageView];
    [self.previewImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)setupCaptureButton
{
    CGFloat buttonW = 80;
    
    self.captureButton = [[UIButton alloc] init];
    self.captureButton.alpha = 0;
    self.captureButton.layer.cornerRadius = buttonW / 2.0;
    self.captureButton.clipsToBounds = YES;
    [self.captureButton setBackgroundImage:[AppHelper imageWithColor:UIColorFromRGBA(46, 204, 113, 1) size:CGSizeMake(1, 1)] forState:UIControlStateNormal];
    [self.captureButton setTitle:@"Capture" forState:UIControlStateNormal];
    self.captureButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.captureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.captureButton addTarget:self action:@selector(pressCaptureButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.captureButton];
    [self.captureButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).with.offset(-70);
        make.size.equalTo([NSValue valueWithCGSize:CGSizeMake(buttonW, buttonW)]);
    }];
}

- (void)showCaptureButton
{
    if (self.captureButton.alpha == 1) {
        return;
    }
    
    self.captureButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.captureButton.transform = CGAffineTransformMakeScale(1, 1);
        self.captureButton.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - AVCapture
- (void)setupAVCapture
{
    self.videoPreview = [UIView new];
    [self.view addSubview:self.videoPreview];
    [self.videoPreview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.videoPreview);
    }];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    videoPreviewLayer.frame = CGRectMake(0, 0, SCREEN_SIZE.width, SCREEN_SIZE.height);
    [self.videoPreview.layer addSublayer:videoPreviewLayer];
    
    //device input
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (videoDevice == nil) {
        NSLog(@"🔴no video device!");
        [self.videoPreview removeFromSuperview];
        self.videoPreview = nil;
        
        self.captureSession = nil;
        return;
    }
    
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    [_captureSession addInput:videoDeviceInput];
    
    //output
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.bufferQueue = dispatch_queue_create("BufferQueue", DISPATCH_QUEUE_SERIAL);
    [videoDataOutput setSampleBufferDelegate:self queue:self.bufferQueue];
    videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    [videoDataOutput setVideoSettings:@{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
    [self.captureSession addOutput:videoDataOutput];
    
    [self setFrameRate:15 onDevice:videoDevice];
    
    [self.captureSession startRunning];
}

- (void)setFrameRate:(NSInteger)frameRate onDevice:(AVCaptureDevice *)videoDevice
{
    if ([videoDevice lockForConfiguration:nil]) {
        videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int)(frameRate));
        videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int)(frameRate));
        [videoDevice unlockForConfiguration];
    }
}

#pragma mark - Action
- (void)pressCaptureButton:(id)sender
{
    if (!self.captureSession) {
        [self setupAVCapture];
    }
}

#pragma mark - ConnectivityManagerDelegate
- (void)manager:(ConnectivityManager *)manager connectedDevicesChanged:(NSArray<NSString *> *)connectedDevices
{
    if (connectedDevices.count > 0) {
        [self hideTipLabel];
        [self showCaptureButton];
    }
}

- (void)manager:(ConnectivityManager *)manager receiveData:(NSData *)data
{
    if (!self.previewImageView) {
        [self setupPreviewImageView];
    }
    
    NSDictionary *dict = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    UIImage *image = [UIImage imageWithData:dict[@"image"]];
    self.previewImageView.image = image;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSNumber* timestamp = @(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)));
    
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
    
    // maybe not always the correct input?  just using this to send current FPS...
    AVCaptureInputPort* inputPort = connection.inputPorts[0];
    AVCaptureDeviceInput* deviceInput = (AVCaptureDeviceInput*) inputPort.input;
    CMTime frameDuration = deviceInput.device.activeVideoMaxFrameDuration;
    NSDictionary* dict = @{
                           @"image": imageData,
                           @"timestamp" : timestamp,
                           @"framesPerSecond": @(frameDuration.timescale)
                           };
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    
    [self.connectManager sendData:data];
}

#pragma mark - Utilities
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer // Create a CGImageRef from sample buffer data
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0,
                                                 CVPixelBufferGetWidth(imageBuffer),
                                                 CVPixelBufferGetHeight(imageBuffer))];
    
    UIImage *image = [[UIImage alloc] initWithCGImage:videoImage scale:1.0 orientation:UIImageOrientationRight];
    CGImageRelease(videoImage);
    
    return image;
}
@end



















