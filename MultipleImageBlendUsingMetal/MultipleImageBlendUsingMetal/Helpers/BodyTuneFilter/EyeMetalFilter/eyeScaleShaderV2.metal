//
//  eyeScaleShaderV2.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 9/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

/*float2 scaleUVForEyeRadial(float2 uv, float2 center, float2 radiusXY, float scaleFactor) {
    float2 diff = uv - center;

    // ellipse-space normalized
    float2 normDiff = diff / radiusXY;
    float r = length(normDiff);
    float angle = atan2(normDiff.y, normDiff.x);

    // slider -100..100 → -1..1
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5); // softer

    // radial falloff: center less, outer more, slightly beyond ellipse
    float inner = 0.2;   // center less zoom
    float outer = 1.3;    // beyond ellipse
    float t = smoothstep(inner, outer, r);

    float maxScale = 0.3;
    float zoom = 1.0 + normalizedScale * (1.0 - t) * maxScale;

    // radial scaling to preserve shape
    float rNew = r / zoom;
    float2 normNew = float2(cos(angle), sin(angle)) * rNew;

    return center + normNew * radiusXY;
}
*/
float2 scaleUVForEyeRadial(float2 uv,
                           float2 center,
                           float2 radiusXY,
                           float scaleFactor) {
    float2 diff = uv - center;
       float2 normDiff = diff / radiusXY;
       float r = length(normDiff);

       if(r < 0.001) return center + normDiff * radiusXY;

       float angle = atan2(normDiff.y, normDiff.x);

       // slider -100..100 → -1..1
       float s = clamp(scaleFactor / 100.0, -1.0, 1.0);
       s = tanh(s * 1.2); // softer curve

       // bell-shaped influence: center moderate, iris edge max, outer fade
       float inner = 0.05;
       float peak  = 0.65;
       float outer = 1.2;

       float t1 = smoothstep(inner, peak, r);
       float t2 = 1.0 - smoothstep(peak, outer, r);

       // center gets a small effect for both in/out
       float baseInfluence = 0.15;

       // For negative zoom (zoom-out), reduce peak effect
       float influence = (s >= 0.0) ? mix(baseInfluence, 1.0, t1) * t2
                                    : mix(baseInfluence, 0.6, t1) * t2;

       float maxZoom = 0.25;
       float zoom = 1.0 + s * influence * maxZoom;

       float rNew = r / zoom;
       float2 normNew = float2(cos(angle), sin(angle)) * rNew;

       return center + normNew * radiusXY;
}

fragment float4 eyeScaleShaderV2(VertexOut vert [[stage_in]],
                                 texture2d<float> inputTexture [[texture(0)]],
                                 sampler textureSampler [[sampler(0)]],
                                 constant float2 &leftEyeCenter [[buffer(0)]],
                                 constant float2 &leftEyeRadii [[buffer(1)]],
                                 constant float2 &rightEyeCenter [[buffer(2)]],
                                 constant float2 &rightEyeRadii [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {

    float2 uv = vert.textureCoordinate;

    float2 uvLeft = scaleUVForEyeRadial(uv, leftEyeCenter, leftEyeRadii, scaleFactor);
    float2 uvRight = scaleUVForEyeRadial(uv, rightEyeCenter, rightEyeRadii, scaleFactor);

    // distance in normalized ellipse space
    float distLeft = length((uv - leftEyeCenter) / leftEyeRadii);
    float distRight = length((uv - rightEyeCenter) / rightEyeRadii);

    // Gaussian-style blending weights
    float falloff = 1.5;
    float weightLeft = exp(-pow(distLeft / falloff, 2.0));
    float weightRight = exp(-pow(distRight / falloff, 2.0));

    float totalWeight = weightLeft + weightRight;
    if(totalWeight > 0.0) {
        weightLeft /= totalWeight;
        weightRight /= totalWeight;
    }

    float2 finalUV = uv * (1.0 - weightLeft - weightRight) + uvLeft * weightLeft + uvRight * weightRight;

    return inputTexture.sample(textureSampler, finalUV);
}


