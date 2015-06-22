#import "Renderer.h"

@interface Renderer ()

//dirty flag
@property (nonatomic, getter=pipelineIsDirty) BOOL pipelineDirty;

// objects living through the whole application
@property (nonatomic, strong) CAMetalLayer *metalLayer;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLLibrary> library;

// lazily recreated
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic, strong) id<MTLDepthStencilState> depthStencilState;

//frame transient
@property (nonatomic, strong) id<MTLRenderCommandEncoder> commandEncoder;
@property (nonatomic, strong) id<MTLCommandBuffer> commandBuffer;
@property (nonatomic, strong) id<CAMetalDrawable> drawable;

@end

@implementation Renderer

@synthesize vertexFunctionName=_vertexFunctionName;
@synthesize fragmentFunctionName=_fragmentFunctionName;

- (instancetype)initWithLayer:(CAMetalLayer *)metalLayer
{
    if((self = [super init]))
    {
        _metalLayer = metalLayer;
        _device = MTLCreateSystemDefaultDevice();
        
        if (!_device)
        {
            NSLog(@"Unable to create default device!");
        }
        
        _metalLayer.device = _device;
        _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
        
        _library = [_device newDefaultLibrary];
        _pipelineDirty = YES;
    }
    
    return self;
}

- (void)buildPipeline
{
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
    
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].offset = 0;
    
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[1].offset = sizeof(float) * 4;
    
    vertexDescriptor.layouts[0].stride = sizeof(float) * 8;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.vertexFunction = [self.library newFunctionWithName:self.vertexFunctionName];
    pipelineDescriptor.fragmentFunction = [self.library newFunctionWithName:self.fragmentFunctionName];
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDescriptor.depthWriteEnabled = YES;
    self.depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    
    NSError *error = nil;
    self.pipeline = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    
    if (!self.pipeline)
    {
        NSLog(@"Error occurred when creating render pipeline state: %@", error);
    }
    
    //TODO: can we do multiple queue?
    self.commandQueue = [self.device newCommandQueue];
    
}

- (id<MTLBuffer>)newBufferWithBytes:(const void *)bytes length:(NSUInteger)length
{
    return [self.device newBufferWithBytes:bytes
                                    length:length
                                   options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)startFrame
{
    // get the framebuffer texture where to draw
    self.drawable = [self.metalLayer nextDrawable];
    id<MTLTexture> framebufferTexture = self.drawable.texture;
    
    if (!framebufferTexture)
    {
        NSLog(@"Unable to retrieve texture; drawable may be nil");
        return;
    }
    
    //rebuild the pipeline if something has changed
    //TODO: can we switch between different pipelines?
    if (self.pipelineIsDirty)
    {
        [self buildPipeline];
        self.pipelineDirty = NO;
    }
    
    // prepare a render pass to render on screen
    MTLRenderPassDescriptor *renderPass = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPass.colorAttachments[0].texture = framebufferTexture;
    renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.9, 0.9, 0.9, 1);
    renderPass.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPass.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    // bind the pipeline state and the render pass for the upcoming command buffer
    // which will encoded and pushed to the queue
    self.commandBuffer = [self.commandQueue commandBuffer];
    self.commandEncoder = [self.commandBuffer renderCommandEncoderWithDescriptor:renderPass];
    [self.commandEncoder setRenderPipelineState:self.pipeline];
    [self.commandEncoder setDepthStencilState:self.depthStencilState];
    [self.commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [self.commandEncoder setCullMode:MTLCullModeBack];
    
}

- (void)drawTrianglesWithInterleavedBuffer:(id<MTLBuffer>)positionBuffer indexBuffer:(id<MTLBuffer>)indexBuffer uniformBuffer:(id<MTLBuffer>)uniformBuffer indexCount:(size_t)indexCount
{
    if (!positionBuffer || !indexBuffer || !uniformBuffer)
    {
        return;
    }
    
    // this is kinda like opengl VAO. we set uniforms, vertices and indices
    
    [self.commandEncoder setVertexBuffer:positionBuffer offset:0 atIndex:0];
    [self.commandEncoder setVertexBuffer:uniformBuffer offset:0 atIndex:1];
    [self.commandEncoder setFragmentBuffer:uniformBuffer offset:0 atIndex:0];
    [self.commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                    indexCount:indexCount
                                     indexType:MTLIndexTypeUInt16
                                   indexBuffer:indexBuffer
                             indexBufferOffset:0];
}

- (void)endFrame
{
    // end the command queue and finally executes it
    
    [self.commandEncoder endEncoding];
    
    if(self.drawable)
    {
        [self.commandBuffer presentDrawable:self.drawable];
        [self.commandBuffer commit];
    }
    
}

- (NSString *)vertexFunctionName
{
    return _vertexFunctionName;
}

- (void)setVertexFunctionName:(NSString *)vertexFunctionName
{
    self.pipelineDirty = YES;
    
    _vertexFunctionName = [vertexFunctionName copy];
}

- (NSString *)fragmentFunctionName
{
    return _fragmentFunctionName;
}

- (void)setFragmentFunctionName:(NSString *)fragmentFunctionName
{
    self.pipelineDirty = YES;
    
    _fragmentFunctionName = [fragmentFunctionName copy];
}

@end
