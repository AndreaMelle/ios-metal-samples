//
//  SaturationAdjustmentFilter.m
//  MetalSamples
//
//  Created by Andrea Melle on 23/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "SaturationAdjustmentFilter.h"
#import <Metal/Metal.h>

struct AdjustSaturationUniforms
{
    float saturationFactor;
};

@implementation SaturationAdjustmentFilter
@synthesize saturationFactor = _saturationFactor;

+ (instancetype)filterWithSaturationFactor:(float)saturation context:(id)context
{
    return [[self alloc] initWithSaturationFactor:saturation context:context];
}

- (instancetype)initWithSaturationFactor:(float)saturation context:(ComputeContext *)context
{
    if ((self = [super initWithFunctionName:@"adjust_saturation" context:context]))
    {
        _saturationFactor = saturation;
    }
    
    return self;
}

- (void)setSaturationFactor:(float)saturationFactor
{
    self.dirty = YES;
    _saturationFactor = saturationFactor;
}

-(void)configureArgumentTableWithCommandEncoder:(id<MTLComputeCommandEncoder>)commandEncoder
{
    struct AdjustSaturationUniforms uniforms;
    uniforms.saturationFactor = self.saturationFactor;
    
    if(!self.uniformBuffer)
    {
        self.uniformBuffer = [self.context.device newBufferWithLength:sizeof(uniforms) options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    memcpy([self.uniformBuffer contents], &uniforms, sizeof(uniforms));
    
    [commandEncoder setBuffer:self.uniformBuffer offset:0 atIndex:0];
}

@end
