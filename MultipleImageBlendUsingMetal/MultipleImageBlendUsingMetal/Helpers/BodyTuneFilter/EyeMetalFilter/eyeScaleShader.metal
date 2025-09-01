//
//  bodyTuneEyeShader.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 13/8/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

/*fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]],
                               constant float2 &eyeCenter [[buffer(1)]],
                               constant float &eyeRadius [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;
    float dist = length(diff);

    if (dist < eyeRadius) {
        float normalizedDist = dist / eyeRadius;        // 0 = center, 1 = edge
        float smoothScale = 1.0 + scaleFactor * 0.02 * (1.0 - normalizedDist);
        float2 newUV = eyeCenter + diff / smoothScale;
        newUV = clamp(newUV, 0.0, 1.0);
        return inputTexture.sample(textureSampler, newUV);
    } else {
        return inputTexture.sample(textureSampler, uv);
    }
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]],
                               constant float2 &eyeCenter [[buffer(1)]],
                               constant float2 &eyeRadiusXY [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // elliptical normalized distance
    float dx = diff.x / eyeRadiusXY.x;
    float dy = diff.y / eyeRadiusXY.y;
    float dist = sqrt(dx*dx + dy*dy); // 0=center, 1=edge of ellipse

    // smooth falloff for surrounding area
    float outerFalloff = 1.5; // extend effect beyond ellipse
    float weight = clamp(1.0 - dist / outerFalloff, 0.0, 1.0);

    // apply scale based on weight
    float s = 1.0 + scaleFactor * 0.02 * weight;
    float2 newUV = eyeCenter + diff / s;
    newUV = clamp(newUV, 0.0, 1.0);

    return inputTexture.sample(textureSampler, newUV);
}*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]],
                               constant float2 &eyeCenter [[buffer(1)]],
                               constant float2 &eyeRadiusXY [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // elliptical normalized distance
    float dx = diff.x / eyeRadiusXY.x;
    float dy = diff.y / eyeRadiusXY.y;
    float dist = sqrt(dx*dx + dy*dy); // 0=center, 1=edge of ellipse

    // smooth falloff for surrounding area
    float outerFalloff = 1.5; // increased from 1.5 to 2.0 for bigger surrounding effect
    float weight = clamp(1.0 - dist / outerFalloff, 0.0, 1.0);

    // smooth interpolation: center gets full scale, edges taper smoothly
    float s = 1.0 + scaleFactor * 0.02 * pow(weight, 0.8); // power 0.8 gives smoother falloff
    float2 newUV = eyeCenter + diff / s;
    newUV = clamp(newUV, 0.0, 1.0);

    return inputTexture.sample(textureSampler, newUV);
}

*/
/*
//Output Better
#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]],
                               constant float2 &eyeCenter [[buffer(1)]],
                               constant float2 &eyeRadiusXY [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // elliptical normalized distance
    float dx = diff.x / eyeRadiusXY.x;
    float dy = diff.y / eyeRadiusXY.y;
    float dist = sqrt(dx*dx + dy*dy); // 0=center, 1=edge of ellipse

    // extended smooth falloff
    float outerFalloff = 2.5; // bigger than before for more surrounding effect
    float weight = clamp(1.0 - dist / outerFalloff, 0.0, 1.0);

    // smoother taper using exponential
    float smoothWeight = pow(weight, 1.5); // exponent >1 makes edge effect more gradual

    // final scale
    float s = 1.0 + scaleFactor * 0.02 * smoothWeight;
    float2 newUV = eyeCenter + diff / s;
    newUV = clamp(newUV, 0.0, 1.0);

    return inputTexture.sample(textureSampler, newUV);
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]],
                               constant float2 &eyeCenter [[buffer(1)]],
                               constant float2 &eyeRadiusXY [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // elliptical normalized distance
    float dx = diff.x / eyeRadiusXY.x;
    float dy = diff.y / eyeRadiusXY.y;
    float dist = sqrt(dx*dx + dy*dy); // 0=center, 1=edge of ellipse

    // bigger area for smooth distortion
    float outerFalloff = 2.5;

    // Gaussian-like smooth falloff
    float smoothWeight = exp(-pow(dist * 2.0 / outerFalloff, 2.0) * 2.0);

    // final scale with smooth effect
    float s = 1.0 + scaleFactor * 0.02 * smoothWeight;
    float2 newUV = eyeCenter + diff / s;
    newUV = clamp(newUV, 0.0, 1.0);

    return inputTexture.sample(textureSampler, newUV);
}*/

//better performance 2
/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]],
                               constant float2 &eyeCenter [[buffer(1)]],
                               constant float2 &eyeRadiusXY [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // elliptical normalized distance
    float dx = diff.x / eyeRadiusXY.x;
    float dy = diff.y / eyeRadiusXY.y;
    float dist = sqrt(dx*dx + dy*dy); // 0=center, 1=edge of ellipse

    // wider influence area but sharper falloff
    float outerFalloff = 2.5; // slightly bigger area
    float smoothWeight = exp(-pow(dist / outerFalloff, 2.0) * 3.5);
    // ↑ higher multiplier → edge distortion reduced

    // final scale with reduced stretch
    float s = 1.0 + scaleFactor * 0.015 * smoothWeight;
    // ↑ 0.015 instead of 0.02 → less extreme scaling

    float2 newUV = eyeCenter + diff / s;
    newUV = clamp(newUV, 0.0, 1.0);

    return inputTexture.sample(textureSampler, newUV);
}
*/

/*
//final effect for eye
#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]], // -100 to 100
                               constant float2 &eyeCenter [[buffer(1)]],
                               constant float2 &eyeRadiusXY [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // elliptical normalized distance
    float dx = diff.x / eyeRadiusXY.x;
    float dy = diff.y / eyeRadiusXY.y;
    float dist = sqrt(dx*dx + dy*dy);

    // normalize slider: -100...100 → -1...1
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);

    // nonlinear mapping for smoother feel
    normalizedScale = tanh(normalizedScale * 1.2); // soften at extremes

    // wider influence with smooth Gaussian falloff
    float outerFalloff = 2.5;
    float smoothWeight = exp(-pow(dist / outerFalloff, 2.0) * 3.0);

    // final scale
    float s = 1.0 + normalizedScale * 0.3 * smoothWeight;
    // ↑ 0.3 = max ±30% scale change

    float2 newUV = eyeCenter + diff / s;
    newUV = clamp(newUV, 0.0, 1.0);

    return inputTexture.sample(textureSampler, newUV);
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                                   texture2d<float> inputTexture [[texture(0)]],
                                   constant float &scaleFactor [[buffer(0)]], // -100 to 100
                                   constant float2 &eyeCenter [[buffer(1)]],
                                   constant float2 &eyeRadiusXY [[buffer(2)]],
                                   sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // elliptical normalized distance
    float dx = diff.x / eyeRadiusXY.x;
    float dy = diff.y / eyeRadiusXY.y;
    float dist = sqrt(dx*dx + dy*dy);

    // normalize slider: -100...100 → -1...1
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);

    // smoother feel
    normalizedScale = tanh(normalizedScale * 1.2);

    // Eyebrow এর জন্য falloff আরও দ্রুত
    float outerFalloff = 2.0; // smaller range
    float smoothWeight = exp(-pow(dist / outerFalloff, 2.0) * 4.0);

    // final scale (কম ইনটেন্স)
    float s = 1.0 + normalizedScale * 0.15 * smoothWeight;
    // ↑ 0.15 = max ±15% scale change

    float2 newUV = eyeCenter + diff / s;
    newUV = clamp(newUV, 0.0, 1.0);

    return inputTexture.sample(textureSampler, newUV);
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]],   // -100..100
                               constant float2 &eyeCenter   [[buffer(1)]],
                               constant float2 &eyeRadiusXY [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv   = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // Elliptical normalized distance
    float dx = diff.x / max(eyeRadiusXY.x, 1e-5);
    float dy = diff.y / max(eyeRadiusXY.y, 1e-5);
    float dist = sqrt(dx*dx + dy*dy);

    // Slider normalization -100..100 → -1..1
    float n = clamp(scaleFactor / 100.0, -1.0, 1.0);
    n = tanh(n * 1.2);

    // Smaller outerFalloff → surrounding area কম
    const float outerFalloff = 2.0;   // smaller → effect concentrated
    const float sharpness    = 4.0;   // higher → edges sharper
    float smoothWeight = exp(-pow(dist / outerFalloff, 2.0) * sharpness);

    // Vertical bias
    float v = clamp((diff.y / max(eyeRadiusXY.y, 1e-5)) * 0.5 + 0.5, 0.0, 1.0);
    float verticalBias = mix(0.65, 1.0, v);
    smoothWeight *= verticalBias;

    // Increase scaling strengths
    const float kx = 2.0;   // horizontal scale
    const float ky = 1.5;   // vertical scale
    float sx = 1.0 + n * kx * smoothWeight;
    float sy = 1.0 + n * ky * smoothWeight;

    // Warp UV
    float2 warpedUV = eyeCenter + float2(diff.x / sx, diff.y / sy);
    warpedUV = clamp(warpedUV, 0.0, 1.0);

    // Blend edges
    float blend = smoothWeight;
    float2 finalUV = mix(uv, warpedUV, blend);

    return inputTexture.sample(textureSampler, finalUV);
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]],   // -100..100
                               constant float2 &eyeCenter   [[buffer(1)]],
                               constant float2 &eyeRadiusXY [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv   = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // Elliptical normalized distance
    float dx = diff.x / max(eyeRadiusXY.x, 1e-5);
    float dy = diff.y / max(eyeRadiusXY.y, 1e-5);
    float dist = sqrt(dx*dx + dy*dy);

    // Normalize slider -100..100 -> -1..1
    float n = clamp(scaleFactor / 100.0, -1.0, 1.0);
    n = tanh(n * 1.2); // soften extremes

    // Gaussian-like smooth falloff
    const float outerFalloff = 2.0;
    const float sharpness    = 3.5;
    float smoothWeight = exp(-pow(dist / outerFalloff, 2.0) * sharpness);

    // Vertical bias
    float v = clamp((diff.y / max(eyeRadiusXY.y, 1e-5)) * 0.5 + 0.5, 0.0, 1.0);
    float verticalBias = mix(0.65, 1.0, v);
    smoothWeight *= verticalBias;

    // Max scale ±30%
    const float maxScale = 0.5;

    // Apply positive or negative scale linearly
    float sx = 1.0 + n * maxScale * smoothWeight;
    float sy = 1.0 + n * maxScale * smoothWeight;

    // Clamp to avoid over-shrink (<0.6)
    sx = max(sx, 0.6);
    sy = max(sy, 0.6);

    // Warp UV
    float2 warpedUV = eyeCenter + float2(diff.x / sx, diff.y / sy);
    warpedUV = clamp(warpedUV, 0.0, 1.0);

    // Blend edges
    float2 finalUV = mix(uv, warpedUV, smoothWeight);

    return inputTexture.sample(textureSampler, finalUV);
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]],   // -100..100
                               constant float2 &eyeCenter   [[buffer(1)]],
                               constant float2 &eyeRadiusXY [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv   = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // Elliptical normalized distance
    float dx = diff.x / max(eyeRadiusXY.x, 1e-5);
    float dy = diff.y / max(eyeRadiusXY.y, 1e-5);
    float dist = sqrt(dx*dx + dy*dy);

    // Normalize slider -100..100 -> -1..1
    float n = clamp(scaleFactor / 100.0, -1.0, 1.0);
    n = tanh(n * 1.6); // soften extremes

    // Gaussian-like smooth falloff
    const float outerFalloff = 2.5;  // smaller → concentrated effect
    const float sharpness    = 4.5;  // higher → sharper edges
    float smoothWeight = exp(-pow(dist / outerFalloff, 2.0) * sharpness);

    // Vertical bias (bottom weaker, top stronger)
    float v = clamp((diff.y / max(eyeRadiusXY.y, 1e-5)) * 0.5 + 0.5, 0.0, 1.0);
    float verticalBias = mix(0.65, 1.0, v);
    smoothWeight *= verticalBias;

    // Max scale ±50%
    const float maxScale = 0.6;

    // Apply positive or negative scale
    float sx = 1.0 + n * maxScale * smoothWeight;
    float sy = 1.0 + n * maxScale * smoothWeight;

    // Clamp to avoid over-shrink
    sx = max(sx, 0.5);
    sy = max(sy, 0.5);

    // Warp UV
    float2 warpedUV = eyeCenter + float2(diff.x / sx, diff.y / sy);
    warpedUV = clamp(warpedUV, 0.0, 1.0);

    // Blend edges
    float2 finalUV = mix(uv, warpedUV, smoothWeight);

    return inputTexture.sample(textureSampler, finalUV);
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                                   texture2d<float> inputTexture [[texture(0)]],
                                   constant float &scaleFactor [[buffer(0)]],   // -100..100
                                   constant float2 &eyeCenter   [[buffer(1)]],
                                   constant float2 &eyeRadiusXY [[buffer(2)]],
                                   sampler textureSampler [[sampler(0)]]) {

    float2 uv   = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // Normalized elliptical distance
    float dx = diff.x / max(eyeRadiusXY.x, 1e-5);
    float dy = diff.y / max(eyeRadiusXY.y, 1e-5);
    float distNorm = sqrt(dx*dx + dy*dy); // 0 center, 1 edge

    // Normalize slider -100..100 → -1..1
    float n = clamp(scaleFactor / 100.0, -1.0, 1.0);
    n = tanh(n * 1.6); // soften extremes

    // Bump falloff
    float bump = 1.0 - pow(distNorm, 2.0); // 1 center, 0 edge
    bump = max(bump, 0.0);

    // Vertical bias
    float v = clamp((diff.y / max(eyeRadiusXY.y, 1e-5)) * 0.5 + 0.5, 0.0, 1.0);
    float verticalBias = mix(0.65, 1.0, v);
    bump *= verticalBias;

    // Max warp ±50%
    const float maxWarp = 0.5;
    float warpAmount = n * maxWarp;

    // FIX: invert direction so positive enlarges
    float2 warpedUV = uv - diff * bump * warpAmount;

    // Clamp UV
    warpedUV = clamp(warpedUV, 0.0, 1.0);

    return inputTexture.sample(textureSampler, warpedUV);
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]],   // -100..100
                               constant float2 &eyeCenter   [[buffer(1)]],
                               constant float2 &eyeRadiusXY [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv   = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;

    // Normalized elliptical distance
    float dx = diff.x / max(eyeRadiusXY.x, 1e-5);
    float dy = diff.y / max(eyeRadiusXY.y, 1e-5);
    float distNorm = sqrt(dx*dx + dy*dy);

    // Normalize slider -100..100 → -1..1
    float n = clamp(scaleFactor / 100.0, -1.0, 1.0);
    n = tanh(n * 1.6); // soften extremes

    // Bump falloff
    float bump = 1.0 - pow(distNorm, 2.0);
    bump = max(bump, 0.0);

    // Vertical bias
    float v = clamp((diff.y / max(eyeRadiusXY.y, 1e-5)) * 0.5 + 0.5, 0.0, 1.0);
    float verticalBias = mix(0.65, 1.0, v);
    bump *= verticalBias;

    // Max warp ±50%
    const float maxWarp = 0.5;
    float warpAmount = n * maxWarp;

    // Anisotropic stretch factors (horizontal, vertical)
    float2 anisotropy = float2(1.4, 0.7);

    // Apply anisotropic bump distortion
    float2 warpedUV = uv - (diff * anisotropy) * bump * warpAmount;

    // Clamp UV
    warpedUV = clamp(warpedUV, 0.0, 1.0);

    return inputTexture.sample(textureSampler, warpedUV);
}

*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]], // -100 to 100
                               constant float2 &eyeCenter [[buffer(1)]],
                               constant float2 &eyeRadiusXY [[buffer(2)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;
    float2 diff = uv - eyeCenter;
    
    // elliptical normalized distance (more accurate calculation)
    float dist = length(float2(diff.x/eyeRadiusXY.x, diff.y/eyeRadiusXY.y));
    
    // remap scale factor with nonlinear response curve
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = sign(normalizedScale) * pow(abs(normalizedScale), 0.7);
    
    // dual falloff zones for better control
    float innerFalloff = 0.8;  // Full effect inside this radius
    float outerFalloff = 2.0;  // Effect fades out to this radius
    
    // smooth transition between zones
    float smoothWeight;
    if (dist < innerFalloff) {
        smoothWeight = 1.0;
    } else {
        smoothWeight = 1.0 - smoothstep(innerFalloff, outerFalloff, dist);
    }
    
    // adaptive scaling strength based on distance
    float baseScale = 1.0 + normalizedScale * 0.25;
    float edgeScale = 1.0 + normalizedScale * 0.1;
    float s = mix(baseScale, edgeScale, smoothstep(0.0, outerFalloff, dist));
    
    // preserve aspect ratio when scaling
    float2 scaledDiff = diff / s;
    
    // soft edge clamping with boundary protection
    float2 newUV = eyeCenter + scaledDiff;
    float2 safeUV = mix(newUV, uv, smoothstep(outerFalloff*0.8, outerFalloff, dist));
    safeUV = clamp(safeUV, 0.001, 0.999);
    
    // sample with linear filtering for smoother results
    return inputTexture.sample(textureSampler, safeUV, gradient2d(dfdx(uv), dfdy(uv)));
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

// --- Helper for smooth eye scaling ---
float2 scaledUVForEye(float2 uv, float2 center, float2 radiusXY, float scaleFactor) {
    float2 diff = uv - center;

    // elliptical normalized distance
    float dx = diff.x / radiusXY.x;
    float dy = diff.y / radiusXY.y;
    float dist = sqrt(dx*dx + dy*dy);

    // normalize slider: -100..100 → -1..1
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2); // smooth at extremes

    // smooth Gaussian-like falloff
    float outerFalloff = 2.5;
    float weight = exp(-pow(dist / outerFalloff, 2.0) * 3.0);

    float s = 1.0 + normalizedScale * 0.3 * weight; // ±30% scale max
    float2 newUV = center + diff / s;

    return clamp(newUV, 0.001, 0.999);
}

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &leftScaleFactor [[buffer(0)]],
                               constant float &rightScaleFactor [[buffer(1)]],
                               constant float2 &leftEyeCenter [[buffer(2)]],
                               constant float2 &rightEyeCenter [[buffer(3)]],
                               constant float2 &leftEyeRadiusXY [[buffer(4)]],
                               constant float2 &rightEyeRadiusXY [[buffer(5)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;

    // compute scaled UVs for each eye
    float2 uvLeft = scaledUVForEye(uv, leftEyeCenter, leftEyeRadiusXY, leftScaleFactor);
    float2 uvRight = scaledUVForEye(uv, rightEyeCenter, rightEyeRadiusXY, rightScaleFactor);

    // compute soft blending weights based on elliptical distance
    float distLeft = length(float2((uv - leftEyeCenter) / leftEyeRadiusXY));
    float distRight = length(float2((uv - rightEyeCenter) / rightEyeRadiusXY));

    float weightLeft = exp(-pow(distLeft / 2.5, 2.0) * 3.0);
    float weightRight = exp(-pow(distRight / 2.5, 2.0) * 3.0);

    float totalWeight = weightLeft + weightRight;
    if (totalWeight > 0.0) {
        weightLeft /= totalWeight;
        weightRight /= totalWeight;
    }

    // blend UVs smoothly
    float2 finalUV = uvLeft * weightLeft + uvRight * weightRight + uv * (1.0 - weightLeft - weightRight);

    return inputTexture.sample(textureSampler, finalUV);
}
*/

/*// --- Helper for smooth, visible eye scaling ---
float2 scaledUVForEye(float2 uv, float2 center, float2 radiusXY, float scaleFactor) {
    float2 diff = uv - center;

    // elliptical normalized distance
    float dx = diff.x / radiusXY.x;
    float dy = diff.y / radiusXY.y;
    float dist = sqrt(dx*dx + dy*dy);

    // normalize slider: -100..100 → -1..1
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5); // stronger mapping

    // Gaussian-like falloff
    float outerFalloff = 2.0; // larger radius for outer influence
    float weight = exp(-pow(dist / outerFalloff, 2.0) * 2.0); // slower falloff

    // separate X/Y scaling
    float2 xyMultiplier = float2(1.0, 0.85);
    float maxScaleFactor = 0.4; // increase scaling for more visible effect
    float2 s = 1.0 + normalizedScale * maxScaleFactor * weight * xyMultiplier;

    float2 newUV = center + float2(diff.x / s.x, diff.y / s.y);

    // blend with original UV for smooth edges
    float2 safeUV = mix(uv, newUV, weight);

    return clamp(safeUV, 0.001, 0.999);
}*/

// --- Helper for natural eye zoom (not stretch) ---
/*float2 scaleUVForEye(float2 uv, float2 center, float2 radiusXY, float scaleFactor) {
    float2 diff = uv - center;

    // normalize to ellipse space
    float2 normDiff = diff / radiusXY;
    float dist = length(normDiff);

    // slider -100..100 → -1..1
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    // inner = exact eye region
    float inner = 1.0;
    // outer = influence falloff
    float outer = 2.0;

    // falloff factor
    float t = smoothstep(inner, outer, dist);

    // final zoom (inside also affected, smoothly blended)
    float maxScale = 0.35; // like lips
    float zoom = 1.0 + normalizedScale * (1.0 - t) * maxScale;

    // apply proportional scaling in ellipse space
    float2 newNorm = normDiff * zoom;
    float2 newUV = center + newNorm * radiusXY;

    return newUV;
}


fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &leftScaleFactor [[buffer(0)]],
                               constant float &rightScaleFactor [[buffer(1)]],
                               constant float2 &leftEyeCenter [[buffer(2)]],
                               constant float2 &rightEyeCenter [[buffer(3)]],
                               constant float2 &leftEyeRadiusXY [[buffer(4)]],
                               constant float2 &rightEyeRadiusXY [[buffer(5)]],
                               sampler textureSampler [[sampler(0)]]) {

    float2 uv = vert.textureCoordinate;

    // compute scaled UVs for both eyes
    float2 uvLeft = scaleUVForEye(uv, leftEyeCenter, leftEyeRadiusXY, leftScaleFactor);
    float2 uvRight = scaleUVForEye(uv, rightEyeCenter, rightEyeRadiusXY, rightScaleFactor);

    // blending weights based on elliptical distance
    float distLeft = length(float2((uv - leftEyeCenter) / leftEyeRadiusXY));
    float distRight = length(float2((uv - rightEyeCenter) / rightEyeRadiusXY));

    float weightLeft = exp(-pow(distLeft / 3.0, 2.0) * 2.0);  // match outerFalloff
    float weightRight = exp(-pow(distRight / 3.0, 2.0) * 2.0);

    float totalWeight = weightLeft + weightRight;
    if (totalWeight > 0.0) {
        weightLeft /= totalWeight;
        weightRight /= totalWeight;
    }

    // final blended UV
    float2 finalUV = uvLeft * weightLeft + uvRight * weightRight + uv * (1.0 - weightLeft - weightRight);

    return inputTexture.sample(textureSampler, finalUV);
}
*/

float2 scaleUVForEye(float2 uv, float2 center, float2 radiusXY, float scaleFactor) {
    float2 diff = uv - center;

    // elliptical normalization
    float2 normDiff = diff / radiusXY;
    float dist = length(normDiff);

    // slider -100..100 → -1..1
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    // inner eye region fully affected
    float inner = 0.75;
    float outer = 2.0; // influence falloff

    // falloff factor: 0 at inner, 1 at outer
    float t = smoothstep(inner, outer, dist);

    // final zoom: positive → zoom in, negative → zoom out
    float maxScale = 0.15; // smaller than lips
    float zoom = 1.0 - normalizedScale * (1.0 - t) * maxScale;

    // proportional scaling in ellipse space (no stretching)
    float2 newNorm = normDiff * zoom;
    float2 newUV = center + newNorm * radiusXY;

    return newUV;
}

fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                               texture2d<float> inputTexture [[texture(0)]],
                               constant float &leftScaleFactor [[buffer(0)]],
                               constant float &rightScaleFactor [[buffer(1)]],
                               constant float2 &leftEyeCenter [[buffer(2)]],
                               constant float2 &rightEyeCenter [[buffer(3)]],
                               constant float2 &leftEyeRadiusXY [[buffer(4)]],
                               constant float2 &rightEyeRadiusXY [[buffer(5)]]) {
    
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    float2 uv = vert.textureCoordinate;

    float2 uvLeft = scaleUVForEye(uv, leftEyeCenter, leftEyeRadiusXY, leftScaleFactor);
    float2 uvRight = scaleUVForEye(uv, rightEyeCenter, rightEyeRadiusXY, rightScaleFactor);

    // distance-based blending for smooth overlap
    float distLeft = length((uv - leftEyeCenter) / leftEyeRadiusXY);
    float distRight = length((uv - rightEyeCenter) / rightEyeRadiusXY);

    //float weightLeft = 1.0 - smoothstep(0.75, 2.0, distLeft);
    //float weightRight = 1.0 - smoothstep(0.75, 2.0, distRight);
    
    float falloff = 2.0; // control outer influence
    float weightLeft = exp(-pow(distLeft / falloff, 2.0));
    float weightRight = exp(-pow(distRight / falloff, 2.0));

    float totalWeight = weightLeft + weightRight;
    if (totalWeight > 0.0) {
        weightLeft /= totalWeight;
        weightRight /= totalWeight;
    }

    float2 finalUV = uvLeft * weightLeft + uvRight * weightRight + uv * (1.0 - weightLeft - weightRight);

    return inputTexture.sample(textureSampler, finalUV);
}
