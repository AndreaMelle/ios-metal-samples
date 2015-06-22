//
//  Mesh.h
//  MetalSamples
//
//  Created by Andrea Melle on 22/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface Mesh : NSObject

@property (strong) id<MTLBuffer> vertexBuffer;
@property (strong) id<MTLBuffer> indexBuffer;

- (instancetype)initWithVertexBuffer:(id<MTLBuffer>)vertexBuffer
                         indexBuffer:(id<MTLBuffer>)indexBuffer;

@end
