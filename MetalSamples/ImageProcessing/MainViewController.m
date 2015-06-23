//
//  MainViewController.m
//  MetalSamples
//
//  Created by Andrea Melle on 23/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "MainViewController.h"
#import "ComputeContext.h"
#import "ImageFilter.h"
#import "SaturationAdjustmentFilter.h"
#import "GaussianBlur2DFilter.h"
#import "UIImage+MBETextureUtilities.h"
#import "MainBundleTextureProvider.h"

@interface MainViewController ()

@property (nonatomic, strong) ComputeContext *context;
@property (nonatomic, strong) id<TextureProvider> imageProvider;
@property (nonatomic, strong) SaturationAdjustmentFilter *desaturateFilter;
@property (nonatomic, strong) GaussianBlur2DFilter *blurFilter;

@property (nonatomic, strong) dispatch_queue_t renderingQueue;
@property (atomic, assign) uint64_t jobIndex;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.renderingQueue = dispatch_queue_create("Rendering", DISPATCH_QUEUE_SERIAL);
    
    [self buildFilterGraph];
    [self updateImage];
}

- (void)buildFilterGraph
{
    self.context = [ComputeContext CreateContext];
    
    self.imageProvider = [MainBundleTextureProvider textureProviderWithImageNamed:@"mandrill"
                                                                             context:self.context];
    
    self.desaturateFilter = [SaturationAdjustmentFilter filterWithSaturationFactor:self.saturationSlider.value
                                                                              context:self.context];
    self.desaturateFilter.provider = self.imageProvider;
    
    self.blurFilter = [GaussianBlur2DFilter filterWithRadius:self.blurRadiusSlider.value
                                                        context:self.context];
    self.blurFilter.provider = self.desaturateFilter;
}

- (void)updateImage
{
    ++self.jobIndex;
    uint64_t currentJobIndex = self.jobIndex;
    
    // Grab these values while we're still on the main thread, since we could
    // conceivably get incomplete values by reading them in the background.
    float blurRadius = self.blurRadiusSlider.value;
    float saturation = self.saturationSlider.value;
    
    dispatch_async(self.renderingQueue, ^{
        if (currentJobIndex != self.jobIndex)
            return;
        
        self.blurFilter.radius = blurRadius;
        self.desaturateFilter.saturationFactor = saturation;
        
        id<MTLTexture> texture = self.blurFilter.texture;
        UIImage *image = [UIImage imageWithMTLTexture:texture];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
        });
    });
}

- (IBAction)blurRadiusDidChange:(id)sender
{
    [self updateImage];
}

- (IBAction)saturationDidChange:(id)sender
{
    [self updateImage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
