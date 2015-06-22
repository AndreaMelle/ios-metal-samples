//
//  ViewController.h
//  MetalSamples
//
//  Created by Andrea Melle on 21/05/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "Renderer.h"

@interface ViewController : UIViewController

@property (nonatomic, strong) Renderer *renderer;
@property (nonatomic, strong) CADisplayLink *displayLink;

@end

