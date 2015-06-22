//
//  Shared.h
//  UpAndRunning3D
//
//  Created by Warren Moore on 9/12/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//

#ifndef __SHARED_H__
#define __SHARED_H__

#include <simd/simd.h>

typedef struct
{
    simd::float4 position;
    simd::float3 normal;
    simd::float2 texCoords;
} VertexType;

typedef struct
{
    simd::float4x4 modelViewProjectionMatrix;
    simd::float4x4 modelViewMatrix;
    simd::float3x3 normalMatrix;
} Uniforms;

typedef uint16_t IndexType;

#endif //__SHARED_H__
