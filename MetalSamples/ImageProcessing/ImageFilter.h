//
//  ImageFilter.h
//  MetalSamples
//
//  Created by Andrea Melle on 23/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TextureProvider.h"
#import "TextureConsumer.h"
#import "ComputeContext.h"

@protocol MTLTexture, MTLBuffer, MTLComputeCommandEncoder, MTLComputePipelineState;

@interface ImageFilter : NSObject<TextureProvider, TextureConsumer>

@property (nonatomic, strong) ComputeContext *context;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@property (nonatomic, strong) id<MTLComputePipelineState> pipeline;
@property (nonatomic, strong) id<MTLTexture> internalTexture;
@property (nonatomic, assign, getter=isDirty) BOOL dirty;

- (instancetype)initWithFunctionName:(NSString *)functionName context:(ComputeContext*)context;
- (void)configureArgumentTableWithCommandEncoder:(id<MTLComputeCommandEncoder>)commandEncoder;

@end
