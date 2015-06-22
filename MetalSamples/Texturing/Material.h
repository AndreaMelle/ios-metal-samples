//
//  Material.h
//  MetalSamples
//
//  Created by Andrea Melle on 22/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@interface Material : NSObject

@property (strong) id<MTLFunction> vertexFunction;
@property (strong) id<MTLFunction> fragmentFunction;
@property (strong) id<MTLTexture> diffuseTexture;

- (instancetype)initWithVertexFunction:(id<MTLFunction>)vertexFunction
                      fragmentFunction:(id<MTLFunction>)fragmentFunction
                        diffuseTexture:(id<MTLTexture>)diffuseTexture;

@end
