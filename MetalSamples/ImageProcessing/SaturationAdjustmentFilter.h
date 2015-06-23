//
//  SaturationAdjustmentFilter.h
//  MetalSamples
//
//  Created by Andrea Melle on 23/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ComputeContext.h"
#import "ImageFilter.h"

@interface SaturationAdjustmentFilter : ImageFilter

@property (nonatomic, assign) float saturationFactor;

+ (instancetype)filterWithSaturationFactor:(float)saturation context:(ComputeContext *)context;

@end
