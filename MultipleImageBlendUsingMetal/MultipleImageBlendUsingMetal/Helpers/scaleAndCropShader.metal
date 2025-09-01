//
//  scaleAndCropShader.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 7/8/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 scaleAndCropShader(VertexOut vert [[stage_in]],
                                   texture2d<float> sourceTexture [[texture(0)]],
                                   constant float2 &invScaledInputSize [[buffer(0)]],
                                   constant float2 &offset [[buffer(1)]],
                                   constant float2 &targetSize [[buffer(2)]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    float2 scaledCoord = vert.textureCoordinate * targetSize + offset;
    float2 texCoord = scaledCoord * invScaledInputSize;

    return sourceTexture.sample(textureSampler, texCoord);
}
