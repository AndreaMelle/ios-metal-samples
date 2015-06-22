#import "Renderer.h"
#import "Material.h"
#import "Mesh.h"
#import "Transforms.h"
#import "OBJGroup.h"

#import <QuartzCore/CAMetalLayer.h>

@interface Renderer ()

@property (strong) UIView *view;
@property (weak) CAMetalLayer *layer;
@property (strong) id<MTLDevice> device;
@property (strong) id<MTLLibrary> library;
@property (strong) id<MTLRenderPipelineState> pipeline;
@property (strong) id<MTLCommandQueue> commandQueue;
@property (assign, getter=isPipelineDirty) BOOL pipelineDirty;
@property (strong) id<MTLBuffer> uniformBuffer;
@property (strong) id<MTLTexture> depthTexture;
@property (strong) id<MTLSamplerState> sampler;
@property (strong) MTLRenderPassDescriptor *currentRenderPass;
@property (strong) id<CAMetalDrawable> currentDrawable;
@property (assign) simd::float4x4 normalMatrix;

@end

@implementation Renderer

- (instancetype)initWithView:(UIView *)view
{
    if((self = [super init]))
    {
        NSAssert([view.layer isKindOfClass:[CAMetalLayer class]], @"Layer type of view used for rendering must be CAMetalLayer");
        
        _view = view;
        _layer = (CAMetalLayer *)view.layer;
        _clearColor = [UIColor colorWithWhite:0.95 alpha:1];
        _pipelineDirty = YES;
        _device = MTLCreateSystemDefaultDevice();
        [self initializeDeviceDependentObjects];
    }
    
    return self;
}

- (void)initializeDeviceDependentObjects
{
    _library = [_device newDefaultLibrary];
    _commandQueue = [_device newCommandQueue];
    
    // create a descriptor to ask the device for a state!
    
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    _sampler = [_device newSamplerStateWithDescriptor:samplerDescriptor];
    
}

- (void)configurePipelineWithMaterial:(Material *)material
{
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].offset = offsetof(VertexType, position);
    
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[1].offset = offsetof(VertexType, normal);
    
    vertexDescriptor.attributes[2].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[2].bufferIndex = 0;
    vertexDescriptor.attributes[2].offset = offsetof(VertexType, texCoords);
    
    vertexDescriptor.layouts[0].stride = sizeof(VertexType);
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = material.vertexFunction;
    pipelineDescriptor.fragmentFunction = material.fragmentFunction;
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    NSError *error = nil;
    self.pipeline = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                                error:&error];
    
    if (!self.pipeline)
    {
        NSLog(@"Error occurred when creating render pipeline state: %@", error);
    }
    
}

- (id<MTLTexture>)textureForImage:(UIImage *)image
{
    CGImageRef imageRef = [image CGImage];
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8_t *rawData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    // Flip the context so the positive Y axis points down
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:width height:height mipmapped:YES];
    
    id<MTLTexture> texture = [self.device newTextureWithDescriptor:textureDescriptor];
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [texture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
    free(rawData);
    
    return texture;
}

- (Material *)newMaterialWithVertexFunctionNamed:(NSString *)vertexFunctionName
                           fragmentFunctionNamed:(NSString *)fragmentFunctionName
                             diffuseTextureNamed:(NSString *)diffuseTextureName
{
    id<MTLFunction> vertexFunction = [self.library newFunctionWithName:vertexFunctionName];
    
    if (!vertexFunction)
    {
        NSLog(@"Could not load vertex function named \"%@\" from default library", vertexFunctionName);
        return nil;
    }
    
    id<MTLFunction> fragmentFunction = [self.library newFunctionWithName:fragmentFunctionName];
    
    if (!fragmentFunction)
    {
        NSLog(@"Could not load fragment function named \"%@\" from default library", fragmentFunctionName);
        return nil;
    }
    
    UIImage *diffuseTextureImage = [UIImage imageNamed:diffuseTextureName];
    if (!diffuseTextureImage)
    {
        NSLog(@"Unable to find PNG image named \"%@\" in main bundle", diffuseTextureName);
        return nil;
    }
    
    id<MTLTexture> diffuseTexture = [self textureForImage:diffuseTextureImage];
    if (!diffuseTexture)
    {
        NSLog(@"Could not create a texture from an image");
    }
    
    Material *material = [[Material alloc] initWithVertexFunction:vertexFunction
                                                 fragmentFunction:fragmentFunction
                                                   diffuseTexture:diffuseTexture];
    
    return material;
}

- (Mesh *)newMeshWithOBJGroup:(OBJGroup *)group
{
    id<MTLBuffer> vertexBuffer = [self.device newBufferWithBytes:group.vertexData.bytes
                                                          length:group.vertexData.length
                                                         options:MTLResourceOptionCPUCacheModeDefault];
    
    id<MTLBuffer> indexBuffer = [self.device newBufferWithBytes:group.indexData.bytes
                                                         length:group.indexData.length
                                                        options:MTLResourceOptionCPUCacheModeDefault];
    
    Mesh *mesh = [[Mesh alloc] initWithVertexBuffer:vertexBuffer indexBuffer:indexBuffer];
    return mesh;
}

- (void)createDepthBuffer
{
    CGSize drawableSize = self.layer.drawableSize;
    MTLTextureDescriptor *depthTexDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float width:drawableSize.width height:drawableSize.height mipmapped:NO];
    
    self.depthTexture = [self.device newTextureWithDescriptor:depthTexDesc];
}

- (void)updateUniforms
{
    if(!self.uniformBuffer)
    {
        self.uniformBuffer = [self.device newBufferWithLength:sizeof(Uniforms) options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    Uniforms uniforms;
    uniforms.modelViewMatrix = self.modelViewMatrix;
    uniforms.modelViewProjectionMatrix = self.modelViewProjectionMatrix;
    uniforms.normalMatrix = simd::inverse(simd::transpose(UpperLeft3x3(self.modelViewMatrix)));
    
    memcpy([self.uniformBuffer contents], &uniforms, sizeof(Uniforms));
}

- (void)startFrame
{
    CGSize drawableSize = self.layer.drawableSize;
    
    if (!self.depthTexture || self.depthTexture.width != drawableSize.width || self.depthTexture.height != drawableSize.height)
    {
        [self createDepthBuffer];
    }
    
    MTLRenderPassDescriptor *renderPass = [MTLRenderPassDescriptor renderPassDescriptor];
    
    id<CAMetalDrawable> drawable = [self.layer nextDrawable];
    NSAssert(drawable != nil, @"Could not retrieve drawable from Metal layer");
    
    CGFloat r, g, b, a;
    [self.clearColor getRed:&r green:&g blue:&b alpha:&a];
    
    renderPass.colorAttachments[0].texture = drawable.texture;
    renderPass.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPass.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPass.colorAttachments[0].clearColor = MTLClearColorMake(r, g, b, a);
    
    renderPass.depthAttachment.texture = self.depthTexture;
    renderPass.depthAttachment.loadAction = MTLLoadActionClear;
    renderPass.depthAttachment.storeAction = MTLStoreActionStore;
    renderPass.depthAttachment.clearDepth = 1;
    
    self.currentDrawable = drawable;
    self.currentRenderPass = renderPass;
    
}

- (void)drawMesh:(Mesh *)mesh withMaterial:(Material *)material
{
    [self configurePipelineWithMaterial:material];
    
    [self updateUniforms];
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:self.currentRenderPass];
    
    [commandEncoder setVertexBuffer:mesh.vertexBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:self.uniformBuffer offset:0 atIndex:1];
    [commandEncoder setFragmentBuffer:self.uniformBuffer offset:0 atIndex:0];
    [commandEncoder setFragmentTexture:material.diffuseTexture atIndex:0];
    [commandEncoder setFragmentSamplerState:self.sampler atIndex:0];
    
    [commandEncoder setRenderPipelineState:self.pipeline];
    [commandEncoder setCullMode:MTLCullModeBack];
    [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    
    MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDescriptor.depthWriteEnabled = YES;
    id<MTLDepthStencilState> depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    [commandEncoder setDepthStencilState:depthStencilState];
    
    [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                               indexCount:[mesh.indexBuffer length] / sizeof(UInt16)
                                indexType:MTLIndexTypeUInt16
                              indexBuffer:mesh.indexBuffer
                        indexBufferOffset:0];
    
    [commandEncoder endEncoding];
    [commandBuffer commit];
    
}

- (void)endFrame
{
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    [commandBuffer presentDrawable:self.currentDrawable];
    [commandBuffer commit];
}

@end
