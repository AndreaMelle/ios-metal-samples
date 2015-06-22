//
//  MetalView.m
//  MetalSamples
//
//  Created by Andrea Melle on 21/05/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "MetalView.h"


@implementation MetalView

- (instancetype)init
{
    if((self = [super init]))
    {
        [self doInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [super initWithCoder:aDecoder]))
    {
        [self doInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame]))
    {
        [self doInit];
    }
    return self;
}

- (void)doInit
{
    _metalLayer = (CAMetalLayer*)[self layer];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    _metalLayer.drawableSize = CGSizeMake(self.bounds.size.width * scale,
                                          self.bounds.size.height * scale);
    
}

+ (id)layerClass
{
    return [CAMetalLayer class];
}

@end
