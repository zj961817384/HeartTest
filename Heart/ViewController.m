//
//  ViewController.m
//  Heart
//
//  Created by zzzzz on 16/8/27.
//  Copyright © 2016年 zzzzz. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "HeartView.h"


#define max(a,b,c) a > b ? (a > c ? a : c) : (b > c ? b : c)
#define min(a,b,c) a < b ? (a < c ? a : c) : (b < c ? b : c)


@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) CALayer *imageLayer;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) AVCaptureDevice *device;

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) UIButton *flashLight;

@property (nonatomic, strong) NSMutableArray<NSNumber *> *specialArray;
@property (nonatomic, assign) CGFloat currentSpecialValue;

@property (nonatomic, assign) BOOL isStartCollect;

@property (nonatomic, strong) HeartView *heartView;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.imageLayer = _imageView.layer;
    _imageView.userInteractionEnabled = YES;
    
    [self.view addSubview:_imageView];
    
    self.currentSpecialValue = 0;
    self.specialArray = [NSMutableArray arrayWithCapacity:[UIScreen mainScreen].bounds.size.width];
    
    [self createSubview];
    
    
    self.flashLight = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flashLight.frame = CGRectMake(30, 30, 20, 20);
    [self.flashLight setBackgroundColor:[UIColor blackColor]];
    self.flashLight.layer.cornerRadius = 5;
    [self.flashLight addTarget:self action:@selector(lightButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [_imageView addSubview:_flashLight];
    
    
}

- (void)createSubview {
    [self setupDevice];

    self.heartView = [[HeartView alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 300)];
    [_heartView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:_heartView];

}

- (void)setupDevice {
    self.captureSession = [[AVCaptureSession alloc] init];
    
    [_captureSession beginConfiguration];
    
    if([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]){
        [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    }
    
    self.device = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    if (_device == nil) {
        //        NSAssert(device == nil, @"没有可用设备");
        NSLog(@"没有可用设备");
        return;
    }
    
    if([_device isTorchModeSupported:AVCaptureTorchModeOff]){
        NSError *error = nil;
        
        [_device lockForConfiguration:&error];
        if (error) {
            return;
        }
        [_device setTorchMode:AVCaptureTorchModeOff];
        [_device unlockForConfiguration];
    }
    
    ///添加输入流
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if([_captureSession canAddInput:deviceInput]){
        [_captureSession addInput:deviceInput];
    }
    
    ///建立视频输出流
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSNumber *BGRA32PixelFormat = [NSNumber numberWithInt:kCVPixelFormatType_32BGRA];
    NSDictionary *rgbOutputSetting;
    rgbOutputSetting = @{(id)kCVPixelBufferPixelFormatTypeKey : BGRA32PixelFormat};
    
    [videoDataOutput setVideoSettings:rgbOutputSetting];//设置像素输出格式
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];//抛弃延迟的帧
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    if ([_captureSession canAddOutput:videoDataOutput]) {
        [_captureSession addOutput:videoDataOutput];
    }
    
    [_captureSession commitConfiguration];
    
    //    [_captureSession startRunning];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.captureSession startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.captureSession stopRunning];
}

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition) position {
    NSArray *deviceArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in deviceArray) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}


#pragma mark -- AVCaptureVideoDataOutputSampleBufferDelegate代理方法实现
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    //获取图像buffer
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    
    /* 在这个位置处理图片，计算，就可以得到特征值 */
//    NSLog(@"%f", [self calculateSpecial:image]);
    
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        _imageView.image = image;
    });
    
}

///将samplebuffer转成UIImage对象
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    unsigned char* imageData = CGBitmapContextGetData(context);
    
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    if (self.isStartCollect) {
        self.currentSpecialValue = [self calculateSpecial:image andImageData:imageData];
    }
//    if (imageData) {
//        free(imageData);
//    }
    
    return (image);
}

- (CGFloat)calculateSpecial:(UIImage *)image andImageData:(unsigned char*)imageData {
    CGFloat specialValue;
    CGImageRef imageRef = image.CGImage;
    size_t w = CGImageGetWidth(imageRef);
    size_t h = CGImageGetHeight(imageRef);
    
    int totalR = 0;
    int totalG = 0;
    int totalB = 0;
    
    if (imageData != NULL) {
        for (int i = 0; i < h; i++) {
            for (int j = 0; j < w; j++) {
                long offset = 4 * (i * w + w);
//                int alpha = imageData[offset + 0];
                int red = imageData[offset + 1];
                int green = imageData[offset + 2];
                int blue = imageData[offset + 3];
                
                totalR += red;
                totalG += green;
                totalB += blue;
            }
        }
        
        float R = totalR / (w * h);
        float G = totalG / (w * h);
        float B = totalB / (w * h);
        
        float maxV = max(R,G,B);
        float minV = min(R,G,B);
//        float V = max(R,G,B);
//        float S = (maxV - minV) / maxV;
        float H = 0.0;
        if (R == maxV) H =(G - B) / (maxV - minV) * 60;
        if (G == maxV) H = 120 + (B - R) / (maxV - minV) * 60;
        if (B == maxV) H = 240 + (R - G) / (maxV - minV) * 60;
        if (H < 0) H = H + 360;
        
        specialValue = H;
    }
    
    return specialValue;
}

- (void)setCurrentSpecialValue:(CGFloat)currentSpecialValue {
    NSLog(@"%f,", currentSpecialValue);
    static CGFloat minValue = 300;
    _currentSpecialValue = (currentSpecialValue - ((int)currentSpecialValue / 10) * 10) * 10;
    NSLog(@"%f,", _currentSpecialValue);
    if (_currentSpecialValue < minValue) {
        minValue = _currentSpecialValue;
    }
    
//    self.heartView.minValue = minValue;
    
    [self.specialArray insertObject:[NSNumber numberWithInteger:_currentSpecialValue] atIndex:0];
//    [self.specialArray removeLastObject];
    
    self.heartView.pointArray = _specialArray;
//    [self.heartView setNeedsDisplay];
    if (self.timer == nil) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(heartViewReDraw) userInfo:nil repeats:YES];
    }
}

- (void)heartViewReDraw {
    [self.heartView setNeedsDisplay];
}




- (void)lightButton:(UIButton *)button {
    button.selected = !button.selected;
    if (button.isSelected) {
        [button setBackgroundColor:[UIColor whiteColor]];
        if([_device isTorchModeSupported:AVCaptureTorchModeOn]){
            NSError *error = nil;
            
            [_device lockForConfiguration:&error];
            if (error) {
                return;
            }
            [_device setTorchMode:AVCaptureTorchModeOn];
            [_device setTorchModeOnWithLevel:0.01 error:nil];//调低闪光灯亮度
            [_device unlockForConfiguration];
            self.isStartCollect = YES;
        }
    } else {
        [button setBackgroundColor:[UIColor blackColor]];
        if([_device isTorchModeSupported:AVCaptureTorchModeOff]){
            NSError *error = nil;
            
            [_device lockForConfiguration:&error];
            if (error) {
                return;
            }
            [_device setTorchMode:AVCaptureTorchModeOff];
            [_device unlockForConfiguration];
            self.isStartCollect = NO;
        }
    }
}











- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
