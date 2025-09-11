//
//  eyeBrowZoomShader.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 11/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

/*float2 scaleUVForBrow1(float2 uv, float2 center, float2 radiusXY, float scaleFactor) {
    float2 diff = uv - center;
    float2 normDiff = diff / radiusXY;
    float dist = length(normDiff);

    // Map slider -100..100 → -0.3..0.3 for vertical scaling
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    float verticalScale = 1.0 + normalizedScale * 0.5;

    // Falloff only inside ellipse
    float falloff = dist <= 1.0 ? exp(-dist * dist * 0.6) : 0.0;
    verticalScale = mix(1.0, verticalScale, falloff);

    // Clamp to prevent extreme stretching
    verticalScale = clamp(verticalScale, 0.3, 2.0);

    return center + float2(normDiff.x, normDiff.y * verticalScale) * radiusXY;
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

    // Compute distance from centers
    float distLeft  = length((uv - leftCenter) / leftRadius);
    float distRight = length((uv - rightCenter) / rightRadius);

    // Compute weights (strong near eyebrow, fade smoothly)
    float weightLeft  = exp(-distLeft * distLeft * 2.0);
    float weightRight = exp(-distRight * distRight * 2.0);

    float totalWeight = weightLeft + weightRight;

    float2 scaledUV = uv;

    if (totalWeight > 0.001) {
        // Scale each eyebrow separately
        float2 uvLeft  = scaleUVForBrow1(uv, leftCenter, leftRadius, scaleFactor);
        float2 uvRight = scaleUVForBrow1(uv, rightCenter, rightRadius, scaleFactor);

        // Weighted blend of eyebrow regions
        scaledUV = (uvLeft * weightLeft + uvRight * weightRight) / totalWeight;

        // Smoothly blend back to original UV near outer edges
        float outerBlend = max(smoothstep(0.8, 1.05, distLeft),
                               smoothstep(0.8, 1.05, distRight));
        scaledUV = mix(scaledUV, uv, outerBlend * 0.2); // slightly stronger outer mix
    }

    return inputTexture.sample(s, scaledUV);
}*/

float2 applyEyebrowScale(float2 uv,
                         float2 center,
                         float2 radius,
                         float scaleFactor) {
    float2 diff = uv - center;
    float2 norm = diff / radius;
    float r = length(norm);

    if (r > 1.0) return uv;

    float influence = smoothstep(0.8, 0.0, r);
    influence = pow(influence, 1.3);

    // Invert scaling logic: scaleFactor > 1 → stretch, < 1 → shrink
    float scale = 1.0 - (scaleFactor - 1.0) * influence;
    diff.y *= scale;

    float2 normScaled = diff / radius;
    if (length(normScaled) > 1.0) {
        normScaled = normalize(normScaled);
        diff = normScaled * radius;
    }

    return center + diff;
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
    float verticalScale = 1.0 + normalizedScale * 0.5;
    
    // Apply to left eyebrow
    uv = applyEyebrowScale(uv, leftCenter, leftRadius, verticalScale);
    
    // Apply to right eyebrow
    uv = applyEyebrowScale(uv, rightCenter, rightRadius, verticalScale);
    
    return inputTexture.sample(s, uv);
}
