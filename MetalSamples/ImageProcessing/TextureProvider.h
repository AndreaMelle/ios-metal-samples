//
//  TextureProvider.h
//  MetalSamples
//
//  Created by Andrea Melle on 23/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTLTexture;

@protocol TextureProvider <NSObject>

@property (nonatomic, readonly) id<MTLTexture> texture;

@end
