//
//  TextureConsumer.h
//  MetalSamples
//
//  Created by Andrea Melle on 23/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TextureProvider;

@protocol TextureConsumer <NSObject>

@property (nonatomic, strong) id<TextureProvider> provider;

@end
