//
//  MainBundleTextureProvider.h
//  MetalSamples
//
//  Created by Andrea Melle on 23/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TextureProvider.h"

@class ComputeContext;

@interface MainBundleTextureProvider : NSObject<TextureProvider>

+ (instancetype)textureProviderWithImageNamed:(NSString*)imageName context:(ComputeContext*)context;

@end
