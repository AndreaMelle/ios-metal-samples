#import <UIKit/UIKit.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "Shared.h"

@class Mesh, Material, OBJGroup;

/*
 * A Renderer is pretty much a delegate for the view
 */

@interface Renderer : NSObject

@property (strong) UIColor *clearColor;

@property (assign) simd::float4x4 modelViewProjectionMatrix;
@property (assign) simd::float4x4 modelViewMatrix;

- (instancetype)initWithView:(UIView *)view;

/// Creates a new material with the specified pair of vertex/fragment functions and
/// the specified diffuse texture name. The texture name must refer to a PNG resource
/// in the main bundle in order to be loaded successfully.
- (Material *)newMaterialWithVertexFunctionNamed:(NSString *)vertexFunctionName
                           fragmentFunctionNamed:(NSString *)fragmentFunctionName
                             diffuseTextureNamed:(NSString *)diffuseTextureName;

/// Creates a new mesh object from the specified OBJ group
- (Mesh *)newMeshWithOBJGroup:(OBJGroup *)group;

- (void)startFrame;
- (void)endFrame;

- (void)drawMesh:(Mesh *)drawable withMaterial:(Material *)material;

@end
