//
//  ComputeContext.m
//  MetalSamples
//
//  Created by Andrea Melle on 23/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "ComputeContext.h"
#import <Metal/Metal.h>

@implementation ComputeContext

+ (instancetype)CreateContext
{
    return [[self alloc] initWithDevice:nil];
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if ((self = [super init]))
    {
        _device = device ?: MTLCreateSystemDefaultDevice();
        _library = [_device newDefaultLibrary];
        _commandQueue = [_device newCommandQueue];
    }
    return self;
}

@end
