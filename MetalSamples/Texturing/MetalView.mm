//
//  MetalView.m
//  MetalSamples
//
//  Created by Andrea Melle on 21/05/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "MetalView.h"


@implementation MetalView

+ (id)layerClass
{
    return [CAMetalLayer class];
}

- (CAMetalLayer *)metalLayer
{
    return (CAMetalLayer *)self.layer;
}

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
    
    // During the first layout pass, we will not be in a view hierarchy, so we guess our scale
    CGFloat scale = [UIScreen mainScreen].scale;
    
    // If we've moved to a window by the time our frame is being set, we can take its scale as our own
    if (self.window)
    {
        scale = self.window.screen.scale;
    }
    
    CGSize drawableSize = self.bounds.size;
    
    // Since drawable size is in pixels, we need to multiply by the scale to move from points to pixels
    drawableSize.width *= scale;
    drawableSize.height *= scale;
    
    self.metalLayer.drawableSize = drawableSize;
    
}

@end
