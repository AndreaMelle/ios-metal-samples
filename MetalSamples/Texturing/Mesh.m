//
//  Mesh.m
//  MetalSamples
//
//  Created by Andrea Melle on 22/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "Mesh.h"

@implementation Mesh

- (instancetype)initWithVertexBuffer:(id<MTLBuffer>)vertexBuffer
                         indexBuffer:(id<MTLBuffer>)indexBuffer
{
    if ((self = [super init]))
    {
        _vertexBuffer = vertexBuffer;
        _indexBuffer = indexBuffer;
    }
    return self;
}

@end
