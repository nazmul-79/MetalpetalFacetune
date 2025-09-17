//
//  lipsScaleShaderV2.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 11/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

float2 applyLipZoom(float2 uv,
                    float2 center,
                    float2 radiusXY,
                    float scaleFactor,
                    float sideBias) {
    
    float2 diff = uv - center;

    // --- normalize slider -100..100 → -1..1 with smoother curve ---
    float normalized = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalized = tanh(normalized * 1.2);

    // --- normalized lip-space ---
    float2 normDiff = diff / radiusXY;
    float dist = length(normDiff);

    // Gaussian-like falloff → 1 at center, 0 at edge
    float falloff = 1.0;
    float weight = exp(-pow(dist / falloff, 2.0));

    // --- directional control (left/right lips) ---
    float sideFactor = smoothstep(-1.0, 1.0, diff.x / radiusXY.x); // left=0, right=1
    sideFactor = mix(1.0 - sideFactor, sideFactor, (sideBias + 1.0) * 0.5);
    // sideBias = -1 → left, 0 → both, 1 → right

    // --- final scale factor ---
    float maxScale = 0.35; // ±25% scaling max
    float scale = 1.0 + normalized * maxScale * weight * sideFactor;

    // --- apply scaling (inverse UV transform) ---
    float2 newUV = center + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}

fragment float4 lipZoomShader(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              constant float &scaleFactor [[buffer(0)]],
                              constant float2 &lipCenter [[buffer(1)]],
                              constant float2 &lipRadius [[buffer(2)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = vert.textureCoordinate;

    // Apply smooth zoom inside lips
    uv = applyLipZoom(uv, lipCenter, lipRadius, scaleFactor, 0.0); // sideBias=0 → both lips

    return inputTexture.sample(s, uv);
}
