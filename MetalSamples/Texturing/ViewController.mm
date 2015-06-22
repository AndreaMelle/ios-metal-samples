//
//  ViewController.m
//  MetalSamples
//
//  Created by Andrea Melle on 21/05/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import "ViewController.h"
#import "OBJModel.h"
#import "Shared.h"
#import "Transforms.h"
#import <AudioToolbox/AudioToolbox.h>
#include <simd/simd.h>
#import "Renderer.h"
#import "OBJGroup.h"

static const CGFloat kVelocityScale = 0.01;
static const CGFloat kRotationDamping = 0.05;
static const CGFloat kMooSpinThreshold = 30;
static const CGFloat kMooDuration = 3;

@interface ViewController ()

@property (nonatomic, strong) CADisplayLink *redrawTimer;
@property (nonatomic, strong) Renderer *renderer;
@property (nonatomic, strong) Mesh *mesh;
@property (nonatomic, strong) Material *material;
@property (nonatomic, assign) SystemSoundID mooSound;
@property (nonatomic, assign) NSTimeInterval lastMooTime;
@property (nonatomic, assign) CGPoint angularVelocity;
@property (nonatomic, assign) CGPoint angle;
@property (nonatomic, assign) NSTimeInterval lastFrameTime;

@end

@implementation ViewController

- (void)dealloc
{
    AudioServicesDisposeSystemSoundID(_mooSound);
    [_redrawTimer invalidate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.renderer = [[Renderer alloc] initWithView:self.view];
    
    [self loadModel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.redrawTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(redrawTimerDidFire:)];
    [self.redrawTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(gestureDidRecognize:)];
    [self.view addGestureRecognizer:panGesture];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.redrawTimer invalidate];
    self.redrawTimer = nil;
}

- (void)redrawTimerDidFire:(CADisplayLink *)sender
{
    [self redraw];
}

- (void)gestureDidRecognize:(UIGestureRecognizer *)gestureRecognizer
{
    UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer *)gestureRecognizer;
    CGPoint velocity = [panGestureRecognizer velocityInView:self.view];
    self.angularVelocity = CGPointMake(velocity.x * kVelocityScale, velocity.y * kVelocityScale);
}

- (void)loadModel
{
    // Load geometry from OBJ file
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"spot" withExtension:@"obj"];
    if (!modelURL)
    {
        NSLog(@"The model could not be located in the main bundle");
    }
    else
    {
        OBJModel *model = [[OBJModel alloc] initWithContentsOfURL:modelURL generateNormals:YES];
        if (!model)
        {
            NSLog(@"The model could not be loaded from the specified URL");
        }
        else
        {
            OBJGroup *group = [model.groups objectAtIndex:1];
            self.mesh = [self.renderer newMeshWithOBJGroup:group];
            self.material = [self.renderer newMaterialWithVertexFunctionNamed:@"vertex_main"
                                                        fragmentFunctionNamed:@"fragment_main"
                                                          diffuseTextureNamed:@"spot_texture"];
        }
    }
    
    // Load sound effect
    
    NSURL *mooURL = [[NSBundle mainBundle] URLForResource:@"moo" withExtension:@"aiff"];
    if (!mooURL)
    {
        NSLog(@"Could not find sound effect file in main bundle");
    }
    
    OSStatus result = AudioServicesCreateSystemSoundID((__bridge CFURLRef)mooURL, &_mooSound);
    if (result != noErr)
    {
        NSLog(@"Error when loading sound effect. Error code %d", result);
    }
}

- (void)updateMotion
{
    // Compute duration of previous frame
    CFAbsoluteTime frameTime = CFAbsoluteTimeGetCurrent();
    NSTimeInterval deltaTime = frameTime - self.lastFrameTime;
    self.lastFrameTime = frameTime;
    
    if (deltaTime > 0)
    {
        // Update the rotation angles according to the current velocity and time step
        self.angle = CGPointMake(self.angle.x + self.angularVelocity.x * deltaTime,
                                 self.angle.y + self.angularVelocity.y * deltaTime);
        
        // Apply damping by removing some proportion of the angular velocity each frame
        self.angularVelocity = CGPointMake(self.angularVelocity.x * (1 - kRotationDamping),
                                           self.angularVelocity.y * (1 - kRotationDamping));
        
        CGFloat spinSpeed = hypot(self.angularVelocity.x, self.angularVelocity.y);
        
        // If we're spinning fast and haven't mooed in a while, trigger the moo sound effect
        if (spinSpeed > kMooSpinThreshold && frameTime > (self.lastMooTime + kMooDuration))
        {
            AudioServicesPlaySystemSound(self.mooSound);
            self.lastMooTime = frameTime;
        }
    }
}

- (void)updateTransformations
{
    // Build the perspective projection matrix
    
    const CGSize size = self.view.bounds.size;
    const CGFloat aspectRatio = size.width / size.height;
    const CGFloat verticalFOV = (aspectRatio > 1) ? 45 : 90;
    static const CGFloat near = 0.1;
    static const CGFloat far = 100;
    
    simd::float4x4 projectionMatrix = PerspectiveProjection(aspectRatio, verticalFOV * (M_PI / 180), near, far);
    
    // Build the model view matrix by rotating and then translating "out" of the screen
    
    static const simd::float3 X = { 1, 0, 0 };
    static const simd::float3 Y = { 0, 1, 0 };
    
    simd::float4x4 modelViewMatrix = Identity();
    modelViewMatrix = modelViewMatrix * Rotation(X, -self.angle.y);
    modelViewMatrix = modelViewMatrix * Rotation(Y, -self.angle.x);
    
    modelViewMatrix.columns[3].z = -1.5;
    
    self.renderer.modelViewMatrix = modelViewMatrix;
    self.renderer.modelViewProjectionMatrix = projectionMatrix * modelViewMatrix;
}

- (void)redraw
{
    [self updateMotion];
    [self updateTransformations];
    
    [self.renderer startFrame];
    [self.renderer drawMesh:self.mesh withMaterial:self.material];
    [self.renderer endFrame];
}

@end
