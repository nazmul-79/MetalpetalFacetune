//
//  FacePFilter.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 25/8/25.
//

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

float2 scaleUVForFace(float2 uv,
                      float2 faceCenter,
                      float2 faceRadiusXY,
                      float faceScaleFactor) {
    
    float2 diff = uv - faceCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(faceScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2);

    // ellipse → circle
    float2 normDiff = diff / faceRadiusXY;
    float dist = length(normDiff);

    // Gaussian falloff for smooth blending
    float falloff = 0.8;
    float weight = exp(-pow(dist / falloff, 2.0));

    // max scale strength (cap)
    float maxScale = 0.15; // adjust for intensity
    float scale = 1.0 + normalizedScale * maxScale * weight;

    // scale inward/outward relative to center
    float2 newUV = faceCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}

fragment float4 FacePFilter(VertexOut vert [[stage_in]],
                            texture2d<float, access::sample> inputTexture [[texture(0)]],
                            sampler textureSampler [[sampler(0)]],
                            constant float &faceScaleFactor [[buffer(0)]],
                            constant float2 &faceRectCenter [[buffer(1)]],
                            constant float2 &faceRectRadius [[buffer(2)]])
{
    float2 uv = vert.textureCoordinate;

    // smooth localized scaling for face
    float2 uvFace = scaleUVForFace(uv, faceRectCenter, faceRectRadius, faceScaleFactor);

    return inputTexture.sample(textureSampler, uvFace);
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

float2 scaleUVForFace(float2 uv,
                      float2 faceCenter,
                      float2 faceRadiusXY,
                      float faceScaleFactor) {
    
    float2 diff = uv - faceCenter;

    // normalize slider -100..100 → -1..1 with soft response
    float normalizedScale = clamp(faceScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.0); // gentler curve

    // ellipse → circle
    float2 normDiff = diff / faceRadiusXY;
    float dist = length(normDiff);

    // hybrid falloff: Gaussian * smoothstep for softer edge fade
    float falloff = 1.5;
    float gaussian = exp(-pow(dist / falloff, 2.0));
    float smoothMask = smoothstep(1.0, 0.0, dist);
    float weight = gaussian * smoothMask;

    // max scale intensity (smaller = more natural)
    float maxScale = 0.15;
    float scale = 1.0 + normalizedScale * maxScale * weight;

    // scale relative to center
    float2 newUV = faceCenter + diff / scale;

    // clamp to texture coords
    return clamp(newUV, 0.0, 1.0);
}

fragment float4 FacePFilter(VertexOut vert [[stage_in]],
                            texture2d<float, access::sample> inputTexture [[texture(0)]],
                            sampler textureSampler [[sampler(0)]],
                            constant float &faceScaleFactor [[buffer(0)]],
                            constant float2 &faceRectCenter [[buffer(1)]],
                            constant float2 &faceRectRadius [[buffer(2)]])
{
    float2 uv = vert.textureCoordinate;

    // smoother localized scaling for face
    float2 uvFace = scaleUVForFace(uv, faceRectCenter, faceRectRadius, faceScaleFactor);

    return inputTexture.sample(textureSampler, uvFace);
}*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

float2 scaleUVForFace(float2 uv,
                      float2 faceCenter,
                      float2 faceRadiusXY,
                      float faceScaleFactor) {
    
    float2 diff = uv - faceCenter;

    // normalize slider -100..100 → -1..1 with soft response
    float normalizedScale = clamp(faceScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.0); // gentler curve

    // ellipse → circle
    float2 normDiff = diff / faceRadiusXY;
    float dist = length(normDiff);

    // -------------------------------
    // falloff tuned for wider region
    // -------------------------------
    float falloff = 1.8;              // bigger → effect spreads outside
    float gaussian = exp(-pow(dist / falloff, 2.0));

    // smoothstep edge shifted outward
    float edgeStart = 1.2;            // start fading after 120% radius
    float edgeEnd   = 0.0;            // fade to zero
    float smoothMask = smoothstep(edgeStart, edgeEnd, dist);

    float weight = gaussian * smoothMask;

    // max scale intensity (smaller = more natural)
    float maxScale = 0.15;
    float scale = 1.0 + normalizedScale * maxScale * weight;

    // scale relative to center
    float2 newUV = faceCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}

fragment float4 FacePFilter(VertexOut vert [[stage_in]],
                            texture2d<float, access::sample> inputTexture [[texture(0)]],
                            sampler textureSampler [[sampler(0)]],
                            constant float &faceScaleFactor [[buffer(0)]],
                            constant float2 &faceRectCenter [[buffer(1)]],
                            constant float2 &faceRectRadius [[buffer(2)]])
{
    float2 uv = vert.textureCoordinate;

    float2 uvFace = scaleUVForFace(uv, faceRectCenter, faceRectRadius, faceScaleFactor);

    return inputTexture.sample(textureSampler, uvFace);
}


*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

float2 scaleUVForFace(float2 uv,
                      float2 faceCenter,
                      float2 faceRadiusXY,
                      float faceScaleFactor) {

    float2 diff = uv - faceCenter;

    // normalize slider -100..100 → -1..1 with soft response
    float normalizedScale = clamp(faceScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.0);

    // ellipse → circle
    float2 normDiff = diff / faceRadiusXY;
    float dist = length(normDiff);

    // -------------------------------
    // top side boost for outer deformation
    // -------------------------------
    float topBoost = 1.8; // increase effect for top area
    float anisotropicDist = dist;
    if (diff.y < 0.0) { // top side (y negative)
        anisotropicDist = length(float2(normDiff.x, normDiff.y / topBoost));
    }

    // Gaussian falloff
    float falloff = 1.8;
    float gaussian = exp(-pow(anisotropicDist / falloff, 2.0));

    // smoothstep edge shifted outward
    float edgeStart = 1.2;
    float edgeEnd   = 0.0;
    float smoothMask = smoothstep(edgeStart, edgeEnd, anisotropicDist);

    float weight = gaussian * smoothMask;

    // max scale intensity
    float maxScale = 0.15;
    float scale = 1.0 + normalizedScale * maxScale * weight;

    // scale relative to center
    float2 newUV = faceCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}

fragment float4 FacePFilter(VertexOut vert [[stage_in]],
                            texture2d<float, access::sample> inputTexture [[texture(0)]],
                            sampler textureSampler [[sampler(0)]],
                            constant float &faceScaleFactor [[buffer(0)]],
                            constant float2 &faceRectCenter [[buffer(1)]],
                            constant float2 &faceRectRadius [[buffer(2)]])
{
    float2 uv = vert.textureCoordinate;

    float2 uvFace = scaleUVForFace(uv, faceRectCenter, faceRectRadius, faceScaleFactor);

    return inputTexture.sample(textureSampler, uvFace);
}

*/

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

/*float2 scaleUVForFace(float2 uv,
                      float2 faceCenter,
                      float2 faceRadiusXY,
                      float faceScaleFactor) {

    float2 diff = uv - faceCenter;

    // normalize slider -100..100 → -1..1 with soft response
    float normalizedScale = clamp(faceScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.0);

    // ellipse → circle
    float2 normDiff = diff / faceRadiusXY;
    float dist = length(normDiff);

    // -------------------------------
    // anisotropic boost for top and bottom
    // -------------------------------
    float topBoost = 1.75;    // top (forehead) influence
    float bottomBoost = 1.2; // bottom (chin/jaw) influence
    float anisotropicDist = dist;

    if (diff.y < 0.0) { // top side
        anisotropicDist = length(float2(normDiff.x, normDiff.y / topBoost));
    } else if (diff.y > 0.0) { // bottom side
        anisotropicDist = length(float2(normDiff.x, normDiff.y / bottomBoost));
    }

    // Gaussian falloff
    float falloff = 1.8;
    float gaussian = exp(-pow(anisotropicDist / falloff, 2.0));

    // smoothstep edge shifted outward
    float edgeStart = 1.2;
    float edgeEnd   = 0.0;
    float smoothMask = smoothstep(edgeStart, edgeEnd, anisotropicDist);

    float weight = gaussian * smoothMask;

    // max scale intensity
    float maxScale = 0.12;
    float scale = 1.0 + normalizedScale * maxScale * weight;

    // scale relative to center
    float2 newUV = faceCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}*/

/*float2 scaleUVForFace(float2 uv,
                      float2 faceCenter,
                      float2 faceRadiusXY,
                      float faceScaleFactor) {

    float2 diff = uv - faceCenter;

    // normalize slider
    float normalizedScale = clamp(faceScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale);

    float2 normDiff = diff / faceRadiusXY;

    // directional anisotropy
    float topBoost = 1.75;
    float bottomBoost = 1.2;
    float anisotropicDist;
    if (diff.y < 0.0) {
        anisotropicDist = length(float2(normDiff.x, normDiff.y / topBoost));
    } else {
        anisotropicDist = length(float2(normDiff.x, normDiff.y / bottomBoost));
    }

    // soft Gaussian falloff
    float falloff = 0.5;
    float gaussian = exp(-pow(anisotropicDist / falloff, 2.0));

    // gentle edge
    float smoothMask = smoothstep(0.0, 1.2, anisotropicDist);

    float weight = gaussian * smoothMask;

    float maxScale = 0.30;
    float scale = 1.0 + normalizedScale * maxScale;

    // compute displaced UV
    float2 displacedUV = faceCenter + diff / scale;

    // blend with original UV for natural effect
    float2 newUV = mix(uv, displacedUV, weight);

    return clamp(newUV, 0.0, 1.0);
}*/

/*float2 scaleUVForFace(float2 uv,
                      float2 faceCenter,
                      float2 faceRadiusXY,
                      float faceScaleFactor) {

    float2 diff = uv - faceCenter;

    // normalize slider
    float normalizedScale = clamp(faceScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale);

    float2 normDiff = diff / faceRadiusXY;

    // directional anisotropy
    float topBoost = 1.7;
    float bottomBoost = 1.1;
    float anisotropicDist;
    if (diff.y < 0.0) {
        anisotropicDist = length(float2(normDiff.x, normDiff.y / topBoost));
    } else {
        anisotropicDist = length(float2(normDiff.x, normDiff.y / bottomBoost));
    }

    // soft Gaussian falloff
    float falloff = 0.6;
    float gaussian = exp(-pow(anisotropicDist / falloff, 2.0));

    // smoothstep edge (center gets influence)
    float edgeStart = 0.1;   // small radius to preserve center
    float edgeEnd   = 1.2;
    float smoothMask = smoothstep(edgeStart, edgeEnd, anisotropicDist);

    // subtle center movement
       float minWeight = 0.03;
       float weight = max(gaussian * smoothMask, minWeight);
    //float smoothMask = smoothstep(0.0, 1.2, anisotropicDist);

    //float weight = gaussian * smoothMask;

    float maxScale = 0.35;
    float scale = 1.0 + normalizedScale * maxScale;

    // compute displaced UV
    float2 displacedUV = faceCenter + diff / scale;

    // blend with original UV for natural effect
    float2 newUV = mix(uv, displacedUV, weight);

    return clamp(newUV, 0.0, 1.0);
}
*/

/*float2 scaleUVForFace(float2 uv,
                      float2 faceCenter,
                      float2 faceRadiusXY,
                      float faceScaleFactor) {

    // vector from center
    float2 diff = uv - faceCenter;

    // normalize slider
    float normalizedScale = clamp(faceScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale);

    // normalize for ellipse
    float2 normDiff = diff / faceRadiusXY;

    // directional anisotropy
    float topBoost = 1.6;
    float bottomBoost = 1.1;
    float anisotropicDist;
    if (diff.y < 0.0) {
        anisotropicDist = length(float2(normDiff.x, normDiff.y / topBoost));
    } else {
        anisotropicDist = length(float2(normDiff.x, normDiff.y / bottomBoost));
    }

    // Gaussian falloff for natural edges
    float falloff = 0.75;
    float gaussian = exp(-pow(anisotropicDist / falloff, 2.0));

    // smooth edge starting very close to center
    float edgeEnd = 1.2;
    float smoothMask = smoothstep(0.0, edgeEnd, anisotropicDist);

    // weight for blending
    float weight = gaussian * smoothMask;

    // max scaling factor
    float maxScale = 0.04;
    float scale = 1.0 - normalizedScale * maxScale;

    // --- radial displacement ---
    float2 direction = normalize(diff + float2(0.001, 0.001)); // tiny offset to avoid zero
    float displacement = (scale - 1.0); // displacement magnitude
    float2 displacedUV = uv + direction * displacement * weight;

    return clamp(displacedUV, 0.0, 1.0);
}
*/

/*float2 scaleUVForFace(float2 uv,
                      float2 faceCenter,
                      float2 faceRadiusXY,
                      float faceScaleFactor) {

    // Vector from center with epsilon to avoid division by zero
    float2 diff = uv - faceCenter;
    float dist = length(diff);
    if (dist < 0.0001) return uv;
    
    // Normalize and apply hyperbolic tangent for smoother scaling
    float normalizedScale = clamp(faceScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5) / 1.5; // Softer response curve
    
    // Normalize for elliptical region
    float2 normDiff = diff / faceRadiusXY;
    float ellipticalDist = length(normDiff);
    
    // More natural anisotropic scaling - gradual transition from top to bottom
    float topSensitivity = 1.8;
    float bottomSensitivity = 1.3;
    float verticalBlend = smoothstep(-1.0, 1.0, normDiff.y); // Blend based on vertical position
    
    float anisotropicDist = length(float2(
        normDiff.x,
        normDiff.y / mix(topSensitivity, bottomSensitivity, verticalBlend)
    ));
    
    // Combined falloff with smoother transition
    float innerRadius = 0.2;
    float outerRadius = 1.6;
    
    // Smooth mask with softer edges
    float smoothMask = 1.0 - smoothstep(innerRadius, outerRadius, anisotropicDist);
    
    // Gaussian falloff for natural edges with adjustable intensity
    float falloffIntensity = 1.5;
    float gaussian = exp(-pow(anisotropicDist / falloffIntensity, 2.5));
    
    // Combined weight with emphasis on natural transitions
    float weight = smoothMask * gaussian;
    
    // Adaptive scaling based on distance from center
    float maxScale = 0.2;
    float scale = 1.0 - normalizedScale * maxScale * (1.0 - 0.3 * ellipticalDist);
    
    // Direction with proper normalization
    float2 direction = diff / dist;
    
    // Apply displacement with smooth weighting
    float2 displacedUV = faceCenter + diff * scale * weight + diff * (1.0 - weight);
    
    return clamp(displacedUV, 0.0, 1.0);
}*/

float2 scaleUVForFace(float2 uv,
                      float2 faceCenter,
                      float2 faceRadiusXY,
                      float faceScaleFactor) {

    float2 diff = uv - faceCenter;
    float dist = length(diff);
    if (dist < 1e-5) return uv;
    
    // smoother normalized scale
    float normalizedScale = clamp(faceScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.3) / 1.3;
    
    // elliptical normalization
    float2 normDiff = diff / faceRadiusXY;
    float ellipticalDist = length(normDiff);
    
    // anisotropy (top vs bottom)
    float topSens = 1.75;
    float bottomSens = 1.25;
    float verticalBlend = smoothstep(-1.0, 1.0, normDiff.y);
    float anisotropicDist = length(float2(
        normDiff.x,
        normDiff.y / mix(topSens, bottomSens, verticalBlend)
    ));
    
    // falloff masks
    float inner = 0.2;
    float outer = 1.4;
    float smoothMask = 1.0 - smoothstep(inner, outer, anisotropicDist);
    
    float gaussian = exp(-pow(anisotropicDist / 1.2, 2.0));
    
    float weight = smoothMask * gaussian;
    
    // scale factor (adaptive)
    float maxScale = 0.15;
    float scale = 1.0 - normalizedScale * maxScale * (1.0 - 0.25 * ellipticalDist);
    
    // normalized direction
    float2 dir = diff / dist;
    
    // displacement (FIXED: remove extra "dist" multiplication)
    float displacement = (scale - 1.0) * weight * dist;
    
    float2 displacedUV = faceCenter + diff + dir * displacement;
    
    return clamp(displacedUV, 0.0, 1.0);
}


fragment float4 FacePFilter(VertexOut vert [[stage_in]],
                            texture2d<float, access::sample> inputTexture [[texture(0)]],
                            sampler textureSampler [[sampler(0)]],
                            constant float &faceScaleFactor [[buffer(0)]],
                            constant float2 &faceRectCenter [[buffer(1)]],
                            constant float2 &faceRectRadius [[buffer(2)]])
{
    float2 uv = vert.textureCoordinate;

    float2 uvFace = scaleUVForFace(uv, faceRectCenter, faceRectRadius, faceScaleFactor);

    return inputTexture.sample(textureSampler, uvFace);
}

