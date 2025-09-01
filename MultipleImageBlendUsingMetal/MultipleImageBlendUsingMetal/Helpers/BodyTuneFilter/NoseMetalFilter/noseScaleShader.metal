//
//  noseScaleShader.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 18/8/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

 float2 scaleUVForNose(float2 uv,
                       float2 noseCenter,
                       float2 noseRadiusXY,
                       float noseScaleFactor,
                       float falloffPower,
                       float horizontalPadding,
                       float verticalPadding)
 {
     float2 adjustedCenter = noseCenter;
     adjustedCenter.y -= noseRadiusXY.y * 0.25;
     float2 diff = uv - adjustedCenter;

     float2 paddedRadius = noseRadiusXY + float2(horizontalPadding * 0.9, verticalPadding * 0.05);

     float2 normDiff = diff / paddedRadius;
     float dist = length(normDiff);

     float radialWeight = exp(-pow(dist, falloffPower * 1.2));
     radialWeight = clamp(radialWeight, 0.0, 1.0);

     float verticalFactor = clamp((diff.y - paddedRadius.y) / (2.0 * paddedRadius.y), 0.9, 1.0);
     verticalFactor = pow(verticalFactor, 1.2);

     float weight = radialWeight * verticalFactor;

     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);

     // vertical gradient for horizontal scaling
     float verticalGradient = saturate((diff.y + paddedRadius.y) / (2.0 * paddedRadius.y));
     verticalGradient = pow(verticalGradient, 1.5);

     float scaleX = 1.0 - normalizedScale * mix(0.05, 0.25, verticalGradient);

     float2 scaled = float2(diff.x * scaleX, diff.y);
     float2 newUV = adjustedCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }

 fragment float4 noseScaleShader(VertexOut vert [[stage_in]],
                                 texture2d<float> inputTexture [[texture(0)]],
                                 constant float &lipScaleFactor [[buffer(0)]],
                                 constant float2 &lipCenter [[buffer(1)]],
                                 constant float2 &lipRadiusXY [[buffer(2)]]) {
     
     constexpr sampler textureSampler (mag_filter::linear,
                                       min_filter::linear);

     float2 uv = vert.textureCoordinate;
     float2 uvLips = scaleUVForNose(uv, lipCenter, lipRadiusXY, lipScaleFactor,5.0,0.02,0.0);

     return inputTexture.sample(textureSampler, uvLips);
 }



/*
 float2 scaleUVForNose(float2 uv,
                       float2 noseCenter,
                       float2 noseRadiusXY,
                       float noseScaleFactor,
                       float falloffPower,
                       float horizontalPadding,
                       float verticalPadding)
 {
     float2 adjustedCenter = noseCenter;
     adjustedCenter.y -= noseRadiusXY.y * 0.25;
     float2 diff = uv - adjustedCenter;

     float2 paddedRadius = noseRadiusXY + float2(horizontalPadding * 0.9, verticalPadding * 0.05);

     float2 normDiff = diff / paddedRadius;
     float dist = length(normDiff);

     float radialWeight = exp(-pow(dist, falloffPower * 1.2));
     radialWeight = clamp(radialWeight, 0.0, 1.0);

     float verticalFactor = clamp((diff.y - paddedRadius.y) / (2.0 * paddedRadius.y), 0.9, 1.0);
     verticalFactor = pow(verticalFactor, 1.2);

     float weight = radialWeight * verticalFactor;

     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);

     // vertical gradient for horizontal scaling
     float verticalGradient = saturate((diff.y + paddedRadius.y) / (2.0 * paddedRadius.y));
     verticalGradient = pow(verticalGradient, 1.5);

     float scaleX = 1.0 - normalizedScale * mix(0.05, 0.25, verticalGradient);

     float2 scaled = float2(diff.x * scaleX, diff.y);
     float2 newUV = adjustedCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }

 
 
 /*float2 scaleUVForNose(float2 uv,
                        float2 noseCenter,
                        float2 noseRadiusXY,
                        float noseScaleFactor,
                        float sideBias) {
     
     float2 diff = uv - noseCenter;

     // normalize slider -100..100 → -1..1
     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     normalizedScale = tanh(normalizedScale * 1.2);

     // Gaussian-like falloff
     float2 normDiff = diff / noseRadiusXY;
     float dist = length(normDiff);
     float falloff = 1.0;
     float weight = exp(-pow(dist / falloff, 2.0));

     // vertical factor (top moves more)
     float verticalFactor = 1.0 - (diff.y / noseRadiusXY.y) * 0.5;
     verticalFactor = clamp(verticalFactor, 0.5, 1.0);

     // horizontal factor (sides expand)
     float horizontalFactor = 1.0 + 0.2 * abs(diff.x / noseRadiusXY.x); // max 20% side expansion

     // separate scaling
     float scaleX = 1.0 + normalizedScale * 0.25 * weight * horizontalFactor; // horizontal scaling
     float scaleY = 1.0 + normalizedScale * 0.25 * weight * verticalFactor;   // vertical scaling

     float2 newUV = noseCenter + float2(diff.x / scaleX, diff.y / scaleY);

     return clamp(newUV, 0.0, 1.0);
 }*/


 /*float2 scaleUVForNose(float2 uv,
                        float2 noseCenter,
                        float2 noseRadiusXY,
                        float noseScaleFactor,
                        float sideBias) {
     
     float2 diff = uv - noseCenter;

     // normalize slider -100..100 → -1..1
     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     normalizedScale = tanh(normalizedScale * 1.2);

     // Gaussian-like falloff
     float2 normDiff = diff / noseRadiusXY;
     float dist = length(normDiff);
     float falloff = 1.0;
     float weight = exp(-pow(dist / falloff, 2.0));

     // vertical factor: 1=top, 0=bottom
     float verticalFactor = 1.0 - (diff.y / noseRadiusXY.y);
     verticalFactor = clamp(verticalFactor, 0.0, 1.0);

     // horizontal factor: bottom widens more
     float horizontalFactor = 1.0 + 0.2 * (1.0 - verticalFactor) * abs(diff.x / noseRadiusXY.x);

     // optional side bias (-1 left, 0 both, 1 right)
     float sideFactor = mix(1.0 - (diff.x / noseRadiusXY.x), (diff.x / noseRadiusXY.x), (sideBias + 1.0) * 0.5);
     horizontalFactor *= sideFactor;

     // separate scaling
     float scaleX = 1.0 + normalizedScale * 0.25 * weight * horizontalFactor;
     float scaleY = 1.0 + normalizedScale * 0.15 * weight * verticalFactor;

     float2 newUV = noseCenter + float2(diff.x / scaleX, diff.y / scaleY);

     return clamp(newUV, 0.0, 1.0);
 }*/

 /*float2 scaleUVForNose(float2 uv,
                        float2 noseCenter,
                        float2 noseRadiusXY,
                        float noseScaleFactor,
                        float sideBias) {
     
     float2 diff = uv - noseCenter;

     // normalize slider -100..100 → -1..1 (tanh for softness)
     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     normalizedScale = tanh(normalizedScale * 1.2);

     // elliptical distance
     float2 normDiff = diff / noseRadiusXY;
     float dist = length(normDiff);

     // smooth falloff
     float weight = exp(-pow(dist, 2.5));  // softer decay

     // vertical factor: 1 at tip (bottom), 0 at top
     float verticalFactor = 1.0 - (diff.y / noseRadiusXY.y);
     verticalFactor = clamp(verticalFactor, 0.0, 1.0);

     // horizontal factor (wider effect at bottom)
     float horizontalFactor = 1.0 + 2.5 * (1.0 - verticalFactor) * abs(diff.x / noseRadiusXY.x);

     // optional side bias (-1 left, 0 both, 1 right)
     float sideFactor = mix(1.0 - (diff.x / noseRadiusXY.x), (diff.x / noseRadiusXY.x), (sideBias + 1.0) * 0.5);
     horizontalFactor *= sideFactor;

     // final scaling
     float scaleX = 1.0 - normalizedScale * 0.30 * horizontalFactor;
     float scaleY = 1.0 - normalizedScale * 0.15 * verticalFactor;

     // apply scaling smoothly (lerp instead of divide)
     float2 scaled = diff * float2(scaleX, scaleY);
     float2 newUV = noseCenter + mix(diff, scaled, weight * verticalFactor);

     return clamp(newUV, 0.0, 1.0);
 }*/

 /*
 float2 scaleUVForNose(float2 uv,
                        float2 noseCenter,
                        float2 noseRadiusXY,
                        float noseScaleFactor,
                        float sideBias) {
     
     float2 diff = uv - noseCenter;

     // slider normalize -100..100 → -1..1 (tanh softness)
     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     normalizedScale = tanh(normalizedScale * 1.2);

     // elliptical distance
     float2 normDiff = diff / noseRadiusXY;
     float dist = length(normDiff);

     // smooth falloff
     float weight = exp(-pow(dist, 4.5));

     // vertical factor: 1 = tip (bottom), 0 = bridge/top
    // float verticalFactor = 1.0 - (diff.y / noseRadiusXY.y);
     float verticalFactor = 1.0 - smoothstep(0.0, 1.0, diff.y / noseRadiusXY.y);
     verticalFactor = clamp(verticalFactor, 0.0, 1.0);

     // ❗ cut off effect for upper side (bridge/eyes area)
     weight *= verticalFactor;

     // horizontal factor (wider near tip)
     float horizontalFactor = 1.0 + 2.5 * (1.0 - verticalFactor) * abs(diff.x / noseRadiusXY.x);

     // optional side bias (-1 left, 0 both, 1 right)
     /*float sideFactor = mix(1.0 - (diff.x / noseRadiusXY.x),
                            (diff.x / noseRadiusXY.x),
                            (sideBias + 1.0) * 0.5);
     
     float sideFactor = mix(1.0, abs(diff.x / noseRadiusXY.x), sideBias);
     horizontalFactor *= sideFactor;

     // final scaling
     float scaleX = 1.0 - normalizedScale * 0.30 * horizontalFactor;
     float scaleY = 1.0 - normalizedScale * 0.15 * verticalFactor;

     // apply scaling smoothly
     float2 scaled = diff * float2(scaleX, scaleY);
     float2 newUV = noseCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }*/

  /*float2 scaleUVForNose(float2 uv,
                        float2 noseCenter,
                        float2 noseRadiusXY,
                        float noseScaleFactor,
                        float sideBias,
                        float falloffPower) { // new: adjustable falloff

     float2 diff = uv - noseCenter;

     // slider normalize -100..100 → -1..1
     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     normalizedScale = tanh(normalizedScale * 1.2);

     // elliptical distance
     float2 normDiff = diff / noseRadiusXY;
     float dist = length(normDiff);

     // smooth radial falloff
     float weight = exp(-pow(dist, falloffPower));
     weight = smoothstep(0.0, 1.0, weight); // extra smooth blend

     // vertical factor: tip=1, bridge/top=0, smooth
     float verticalFactor = 1.0 - smoothstep(0.0, 1.0, diff.y / noseRadiusXY.y);
     verticalFactor = clamp(verticalFactor, 0.0, 1.0);

     // cut off upper bridge / eyes area
     weight *= verticalFactor;

     // horizontal factor (wider at tip)
     float horizontalFactor = 1.0 + 5.5 * (1.0 - verticalFactor) * abs(diff.x / noseRadiusXY.x);

     // side bias (-1 left, 0 both, 1 right) with symmetry preservation
     float sideFactor = mix(1.0, abs(diff.x / noseRadiusXY.x), sideBias);
     horizontalFactor *= sideFactor;

     // limit max scaling to avoid pixel break
     float maxScaleX = 0.25;
     float maxScaleY = 0.15;
     float scaleX = 1.0 - clamp(normalizedScale * 0.25 * horizontalFactor, -maxScaleX, maxScaleX);
     float scaleY = 1.0 - clamp(normalizedScale * 0.05 * verticalFactor, -maxScaleY, maxScaleY);

     // apply scaling smoothly
     float2 scaled = diff * float2(scaleX, scaleY);
     float2 newUV = noseCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }*/

 /*float2 scaleUVForNose(float2 uv,
                        float2 noseCenter,
                        float2 noseRadiusXY,
                        float noseScaleFactor,
                        float sideBias,
                        float falloffPower) {

     float2 diff = uv - noseCenter;

     // normalize slider -100..100 → -1..1
     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     normalizedScale = tanh(normalizedScale * 1.2);

     // elliptical distance
     float2 normDiff = diff / noseRadiusXY;
     float dist = length(normDiff);

     // vertical factor: 0 at top (bridge), 1 at tip (bottom)
     float verticalFactor = 1.0 - (diff.y / noseRadiusXY.y);
     verticalFactor = clamp(verticalFactor, 0.0, 1.0);

     // weight: only tip affected, top untouched
     float weight = exp(-pow(dist, falloffPower)) * verticalFactor;

     // horizontal factor: more widening at tip
     float horizontalFactor = 1.0 + 3.0 * (1.0 - verticalFactor) * abs(diff.x / noseRadiusXY.x);

     // side bias
     float sideFactor = mix(1.0, abs(diff.x / noseRadiusXY.x), sideBias);
     horizontalFactor *= sideFactor;

     // max scaling clamp
     float maxScaleX = 0.35;
     float maxScaleY = 0.15;
     float scaleX = 1.0 - clamp(normalizedScale * 0.25 * horizontalFactor, -maxScaleX, maxScaleX);
     float scaleY = 1.0 - clamp(normalizedScale * 0.15 * verticalFactor, -maxScaleY, maxScaleY);

     // apply scaling smoothly
     float2 scaled = diff * float2(scaleX, scaleY);
     float2 newUV = noseCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }*/

 /*float2 scaleUVForNose(float2 uv,
                        float2 noseCenter,
                        float2 noseRadiusXY,
                        float noseScaleFactor,
                        float sideBias,
                        float falloffPower) {

     float2 diff = uv - noseCenter;

     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     normalizedScale = tanh(normalizedScale * 1.2);

     float2 normDiff = diff / noseRadiusXY;
     float dist = length(normDiff);

     // vertical factor: 0 at bridge/top, 1 at tip/bottom
     float verticalFactor = 1.0 - (diff.y / noseRadiusXY.y);
     verticalFactor = clamp(verticalFactor, 0.0, 1.0);

     // tip-focused weight
     float weight = exp(-pow(dist, falloffPower)) * pow(verticalFactor, 3.0);

     // horizontal widening only near tip
     float horizontalFactor = 1.0 + 6.0 * (1.0 - verticalFactor) * abs(diff.x / noseRadiusXY.x);

     // optional side bias
     float sideFactor = mix(1.0, abs(diff.x / noseRadiusXY.x), sideBias);
     horizontalFactor *= sideFactor;

     float maxScaleX = 0.35;
     float maxScaleY = 0.15;
     float scaleX = 1.0 - clamp(normalizedScale * 0.25 * horizontalFactor, -maxScaleX, maxScaleX);
     float scaleY = 1.0 - clamp(normalizedScale * 0.15 * verticalFactor, -maxScaleY, maxScaleY);

     float2 scaled = diff * float2(scaleX, scaleY);
     float2 newUV = noseCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }*/

 //float2 scaleUVForNose(float2 uv,
 //                      float2 noseCenter,
 //                      float2 noseRadiusXY,
 //                      float noseScaleFactor,
 //                      float sideBias,
 //                      float falloffPower,
 //                      float horizontalPadding,
 //                      float verticalPadding)
 //{
 //    float2 diff = uv - noseCenter;
 //
 //    // --- radius + padding ---
 //    float2 paddedRadius = noseRadiusXY + float2(horizontalPadding, verticalPadding);
 //
 //    // Normalize scale factor
 //    float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
 //    normalizedScale = tanh(normalizedScale * 1.2);
 //
 //    // Normalize difference by padded radius
 //    float2 normDiff = diff / paddedRadius;
 //    float dist = length(normDiff);
 //
 //    // Vertical factor: 0 at bridge/top, 1 at tip/bottom
 //    float verticalFactor = 1.0 - (diff.y / paddedRadius.y);
 //    verticalFactor = clamp(verticalFactor, 0.0, 1.0);
 //
 //    // Weighting (falloff)
 //    float bridgeBias = 0.5 + 0.5 * verticalFactor;
 //    float weight = exp(-pow(dist, falloffPower * 0.8)) * bridgeBias;
 //
 //    // Horizontal widening factor
 //    float horizontalFactor = 1.0 + 4.0 * (1.0 - verticalFactor) * abs(diff.x / paddedRadius.x);
 //    horizontalFactor = clamp(horizontalFactor, 1.0, 2.5);
 //
 //    float sideFactor = mix(1.0, abs(diff.x / paddedRadius.x), smoothstep(0.0, 1.0, sideBias));
 //    horizontalFactor *= sideFactor;
 //
 //    // Scaling (X strong, Y weak)
 //    float maxScaleX = 0.35 * (1.0 + 0.5 * abs(normalizedScale));
 //    float maxScaleY = 0.15 * (1.0 + 0.5 * abs(normalizedScale));
 //
 //    float scaleX = 1.0 - clamp(normalizedScale * 0.3 * horizontalFactor, -maxScaleX, maxScaleX);
 //    float scaleY = 1.0 - clamp(normalizedScale * 0.05 * verticalFactor, -maxScaleY, maxScaleY);
 //
 //    float2 scaled = diff * float2(scaleX, scaleY);
 //    float2 newUV = noseCenter + mix(diff, scaled, weight);
 //
 //    return newUV;
 //}


 /*float2 scaleUVForNose(float2 uv,
                       float2 noseCenter,
                       float2 noseRadiusXY,
                       float noseScaleFactor,
                       float falloffPower)
 {
     // Difference from nose center
     float2 diff = uv - noseCenter;

     // Elliptical normalized distance
     float2 normDiff = diff / noseRadiusXY;
     float dist = length(normDiff);

     // Weight for smooth falloff (1=center, 0=edge)
     float weight = exp(-pow(dist, falloffPower));
     weight = clamp(weight, 0.0, 1.0);

     // Horizontal scale only (X-axis)
     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     float scaleX = 1.0 - normalizedScale * 0.20; // adjust 0.35 for intensity

     // Y-axis unchanged
     float2 scaled = float2(diff.x * scaleX, diff.y);

     // Blend using weight
     float2 newUV = noseCenter + mix(diff, scaled, weight);

     // Clamp to valid UV
     return clamp(newUV, 0.0, 1.0);
 }*/

 /*float2 scaleUVForNose(float2 uv,
                       float2 noseCenter,
                       float2 noseRadiusXY,
                       float noseScaleFactor,
                       float falloffPower,
                       float horizontalPadding,
                       float verticalPadding)
 {
     float2 diff = uv - noseCenter;

     // Apply padding
     float2 paddedRadius = noseRadiusXY + float2(horizontalPadding, verticalPadding);

     // Elliptical normalized distance
     float2 normDiff = diff / paddedRadius;
     float dist = length(normDiff);

     // Smooth radial weight
     float radialWeight = exp(-pow(dist, falloffPower));
     radialWeight = clamp(radialWeight, 0.0, 1.0);

     // Vertical factor: 0 at bridge/top, 1 at tip/bottom
     float verticalFactor = clamp((diff.y + paddedRadius.y) / (2.0 * paddedRadius.y), 0.0, 1.0);
     // pow to smooth
     verticalFactor = pow(verticalFactor, 1.2);

     // Final weight = radial * verticalFactor
     float weight = radialWeight * verticalFactor;

     // Horizontal scaling only
     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     float scaleX = 1.0 - normalizedScale * 0.20;

     float2 scaled = float2(diff.x * scaleX, diff.y);

     // Blend scaled X using weight
     float2 newUV = noseCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }*/

 /*float2 scaleUVForNose(float2 uv,
                       float2 noseCenter,
                       float2 noseRadiusXY,
                       float noseScaleFactor,
                       float falloffPower,
                       float horizontalPadding,
                       float verticalPadding)
 {
     float2 diff = uv - noseCenter;

     // Apply padding
     float2 paddedRadius = noseRadiusXY + float2(horizontalPadding, verticalPadding);

     // Elliptical normalized distance
     float2 normDiff = diff / paddedRadius;
     float dist = length(normDiff);

     // Smooth radial weight
     float radialWeight = exp(-pow(dist, falloffPower));
     radialWeight = clamp(radialWeight, 0.0, 1.0);

     // Vertical factor: 0.2 at bridge/top, 1 at tip/bottom
     float verticalFactor = clamp((diff.y + paddedRadius.y) / (2.0 * paddedRadius.y), 0.5, 1.0);
     verticalFactor = pow(verticalFactor, 1.2); // smooth transition

     // Final weight = radial * verticalFactor
     float weight = radialWeight * verticalFactor;

     // Horizontal scaling only
     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     float scaleX = 1.0 - normalizedScale * 0.20;

     float2 scaled = float2(diff.x * scaleX, diff.y);

     // Blend scaled X using weight
     float2 newUV = noseCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }
 */

 /*float2 scaleUVForNose(float2 uv,
                       float2 noseCenter,
                       float2 noseRadiusXY,
                       float noseScaleFactor,
                       float falloffPower,
                       float horizontalPadding,
                       float verticalPadding)
 {
     float2 diff = uv - noseCenter;

     // Reduce padding to limit influence downward
     float2 paddedRadius = noseRadiusXY + float2(horizontalPadding * 0.7, verticalPadding * 0.5);

     // Elliptical normalized distance
     float2 normDiff = diff / paddedRadius;
     float dist = length(normDiff);

     // Sharper falloff
     float radialWeight = exp(-pow(dist, falloffPower * 1.2));
     radialWeight = clamp(radialWeight, 0.0, 1.0);

     // Vertical factor: only allow effect above nose tip
     float verticalFactor = clamp((diff.y + paddedRadius.y) / (2.0 * paddedRadius.y), 0.7, 1.0);
     verticalFactor = pow(verticalFactor, 1.2);

     float weight = radialWeight * verticalFactor;

     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     float scaleX = 1.0 - normalizedScale * 0.20;

     float2 scaled = float2(diff.x * scaleX, diff.y);

     float2 newUV = noseCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }*/

 /*float2 scaleUVForNose(float2 uv,
                       float2 noseCenter,
                       float2 noseRadiusXY,
                       float noseScaleFactor,
                       float falloffPower,
                       float horizontalPadding,
                       float verticalPadding)
 {
     float2 diff = uv - noseCenter;

     // Shift the effect slightly upward
  
     // Reduce padding to limit influence downward
     float2 paddedRadius = noseRadiusXY + float2(horizontalPadding * 0.8, verticalPadding * 0.6);
     
     diff.y += paddedRadius.y * 0.9; // lift 10% of vertical radius


     // Elliptical normalized distance
     float2 normDiff = diff / paddedRadius;
     float dist = length(normDiff);

     // Sharper falloff
     float radialWeight = exp(-pow(dist, falloffPower * 1.2));
     radialWeight = clamp(radialWeight, 0.0, 0.8);

     // Vertical factor: only allow effect above nose tip
     float verticalFactor = clamp((diff.y - paddedRadius.y) / (3.0 * paddedRadius.y), 0.8, 1.0);
     verticalFactor = pow(verticalFactor, 1.8);

     float weight = radialWeight * verticalFactor;

     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     float scaleX = 1.0 - normalizedScale * 0.20;

     float2 scaled = float2(diff.x * scaleX, diff.y);

     float2 newUV = noseCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }
 */

 /*float2 scaleUVForNose(float2 uv,
                       float2 noseCenter,
                       float2 noseRadiusXY,
                       float noseScaleFactor,
                       float falloffPower,
                       float horizontalPadding,
                       float verticalPadding)
 {
     
     float2 adjustedCenter = noseCenter;
     adjustedCenter.y -= noseRadiusXY.y * 0.20;; // Shift center upward (from 0.5 to 0.45)
     float2 diff = uv - adjustedCenter;

     // Shift the effect slightly upward
  
     // Reduce padding to limit influence downward
     float2 paddedRadius = noseRadiusXY + float2(horizontalPadding * 0.5, verticalPadding * 0.005);
     
     //diff.y += paddedRadius.y * 0.1; // lift 10% of vertical radius


     // Elliptical normalized distance
     float2 normDiff = diff / paddedRadius;
     float dist = length(normDiff);

     // Sharper falloff
     float radialWeight = exp(-pow(dist, falloffPower * 1.2));
     radialWeight = clamp(radialWeight, 0.0, 1.0);

     // Vertical factor: only allow effect above nose tip
     float verticalFactor = clamp((diff.y + paddedRadius.y) / (2.0 * paddedRadius.y), 0.7, 1.0);
     verticalFactor = pow(verticalFactor, 1.2);

     float weight = radialWeight * verticalFactor;

     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
     float scaleX = 1.0 - normalizedScale * 0.20;

     float2 scaled = float2(diff.x * scaleX, diff.y);

     float2 newUV = adjustedCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }*/

 /*float2 scaleUVForNose(float2 uv,
                       float2 noseCenter,
                       float2 noseRadiusXY,
                       float noseScaleFactor,
                       float falloffPower,
                       float horizontalPadding,
                       float verticalPadding)
 {
     float2 adjustedCenter = noseCenter;
     adjustedCenter.y -= noseRadiusXY.y * 0.30; // উপরের দিকে shift করে দিচ্ছি

     float2 diff = uv - adjustedCenter;

     // padded radius
     float2 paddedRadius = noseRadiusXY + float2(horizontalPadding * 0.5,
                                                 verticalPadding * 0.005);

     // normalized elliptical distance
     float2 normDiff = diff / paddedRadius;
     float dist = length(normDiff);

     // radial falloff
     float radialWeight = exp(-pow(dist, falloffPower * 1.2));
     radialWeight = clamp(radialWeight, 0.0, 1.0);

     // vertical factor (0=উপরে, 1=নিচে)
     float verticalFactor = (diff.y + paddedRadius.y) / (2.0 * paddedRadius.y);
     verticalFactor = clamp(verticalFactor, 0.0, 1.0);

     // 👉 নতুন horizontal fade factor
     // উপরে গেলে (verticalFactor ছোট) → horizontal স্কেল কমে যাবে
     // নিচে গেলে (verticalFactor বড়) → horizontal স্কেল পুরো কাজ করবে
     float horizontalFade = smoothstep(0.0, 1.0, verticalFactor);

     // final weight
     float weight = radialWeight * pow(verticalFactor, 1.2);

     // scale calculation
     float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);

     // horizontal fade apply
     float scaleX = 1.0 - normalizedScale * 0.20 * horizontalFade;

     float2 scaled = float2(diff.x * scaleX, diff.y);

     float2 newUV = adjustedCenter + mix(diff, scaled, weight);

     return clamp(newUV, 0.0, 1.0);
 }
  
  
*/
