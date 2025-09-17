//
//  eyeBrowZoomShader.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 11/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;


float2 applyEyebrowScale(float2 uv,
                         float2 center,
                         float2 radius,
                         float scaleFactor) {
    float2 modifiedRadius = radius;
    modifiedRadius.x *= 1.5; // widen horizontally a bit
    
    float2 diff = uv - center;
    float2 norm = diff / modifiedRadius;
    float r = length(norm);

    if (r > 1.0) return uv;

    float influence = smoothstep(0.75, 0.0, r);
    influence = pow(influence, 1.3);

    // For vertical scaling, we want to scale the vertical distance from center
    // scaleFactor > 1 → stretch vertically, < 1 → compress vertically
    float scale = 1.0 - (scaleFactor - 1.0) * influence;
    
    // Scale the vertical component relative to the center
    diff.y = (uv.y - center.y) * scale;
    
    // Recalculate the normalized position with scaled coordinates
    float2 scaledDiff = float2(diff.x, diff.y);
    float2 normScaled = scaledDiff / modifiedRadius;
    float rScaled = length(normScaled);
    
    // If we're outside the ellipse after scaling, normalize back to the boundary
    if (rScaled > 1.0) {
        normScaled = normalize(normScaled);
        scaledDiff = normScaled * modifiedRadius;
    }
    
    return center + scaledDiff;
}


fragment float4 eyeBrowZoomShader(VertexOut vert [[stage_in]],
                                   texture2d<float> inputTexture [[texture(0)]],
                                   constant float &scaleFactor [[buffer(0)]],
                                   constant float2 &leftCenter [[buffer(1)]],
                                   constant float2 &rightCenter [[buffer(2)]],
                                   constant float2 &leftRadius [[buffer(3)]],
                                   constant float2 &rightRadius [[buffer(4)]]) {
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = vert.textureCoordinate;
    
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    float verticalScale = 1.0 + normalizedScale * 0.6;
    
    // Apply to left eyebrow
    uv = applyEyebrowScale(uv, leftCenter, leftRadius, verticalScale);
    
    // Apply to right eyebrow
    uv = applyEyebrowScale(uv, rightCenter, rightRadius, verticalScale);
    
    return inputTexture.sample(s, uv);
}
