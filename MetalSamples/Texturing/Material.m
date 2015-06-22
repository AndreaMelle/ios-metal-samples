//
//  Material.m
//  MetalSamples
//
//  Created by Andrea Melle on 22/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "Material.h"

@implementation Material

- (instancetype)initWithVertexFunction:(id<MTLFunction>)vertexFunction
                      fragmentFunction:(id<MTLFunction>)fragmentFunction
                        diffuseTexture:(id<MTLTexture>)diffuseTexture
{
    if ((self = [super init]))
    {
        _vertexFunction = vertexFunction;
        _fragmentFunction = fragmentFunction;
        _diffuseTexture = diffuseTexture;
    }
    return self;
}

@end
