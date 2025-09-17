//
//  noseScaleShaderV2.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 16/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

// ---------------------------------------------------------
// Utility: point-in-polygon (ray casting)
// ---------------------------------------------------------
inline bool pointInPolygon(float2 uv, device const float2 *points, uint count) {
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        if (((pi.y > uv.y) != (pj.y > uv.y)) &&
            (uv.x < (pj.x - pi.x) * (uv.y - pi.y) / (pj.y - pi.y) + pi.x))
        {
            inside = !inside;
        }
    }
    return inside;
}

// ---------------------------------------------------------
// Utility: clamp UV to polygon boundary
// ---------------------------------------------------------
inline float2 clampToPolygon(float2 uv, device const float2 *points, uint count) {
    float2 closest = uv;
    float minDist = 1e6;

    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 a = points[j];
        float2 b = points[i];

        float2 ab = b - a;
        float denom = dot(ab, ab);
        float t = denom > 0.0 ? clamp(dot(uv - a, ab) / denom, 0.0, 1.0) : 0.0;

        float2 proj = a + t * ab;
        float d = distance(uv, proj);

        if (d < minDist) {
            minDist = d;
            closest = proj;
        }
    }

    if (!pointInPolygon(uv, points, count)) {
        return closest;   // outside → clamp to boundary
    }
    return uv; // inside → keep
}

// ---------------------------------------------------------
// Main scaling with polygon clamp
// ---------------------------------------------------------
inline float2 scaleUVForNoseV2(float2 uv,
                               float2 noseCenter,
                               float2 noseRadiusXY,
                               float noseScaleFactor,
                               float falloffPower,
                               float horizontalPadding,
                               float verticalPadding,
                               device const float2 *nosePoints,
                               uint noseCount)
{
    float2 adjustedCenter = noseCenter;
    float2 diff = uv - adjustedCenter;

    // Ellipse padding
    float2 paddedRadius = noseRadiusXY + float2(horizontalPadding * 0.75,
                                                verticalPadding * 0.05);

    // Ellipse distance
    float2 normDiff = diff / paddedRadius;
    float dist = length(normDiff);

    // Smooth falloff
    float radialWeight = exp(-pow(dist, falloffPower * 1.2));
    radialWeight = clamp(radialWeight, 0.0, 1.0);

    // Vertical attenuation
    float verticalAttenuation = (diff.y + paddedRadius.y) / (2.0 * paddedRadius.y);
    verticalAttenuation = pow(verticalAttenuation, 1.5);

    float weight = radialWeight * verticalAttenuation;

    // Scale factor
    float normalizedScale = clamp(noseScaleFactor / 100.0, -1.0, 1.0);
    float scaleX = 1.0 - normalizedScale * mix(0.05, 0.25, verticalAttenuation);

    // Final displacement
    float2 scaled = float2(diff.x * scaleX, diff.y);
    float2 newUV = adjustedCenter + mix(diff, scaled, weight);

    // Clamp result to polygon boundary
    return clampToPolygon(newUV, nosePoints, noseCount);
}


fragment float4 noseScaleShaderV2(VertexOut vert [[stage_in]],
                                  texture2d<float> inputTexture [[texture(0)]],
                                  constant float &lipScaleFactor [[buffer(0)]],
                                  constant float2 &lipCenter [[buffer(1)]],
                                  constant float2 &lipRadiusXY [[buffer(2)]],
                                  device const float2 *nosePoints [[buffer(3)]],
                                  constant uint &noseCount [[buffer(4)]]) {
     
     constexpr sampler textureSampler (mag_filter::linear,
                                       min_filter::linear);

     float2 uv = vert.textureCoordinate;
     
     float2 uvNose = scaleUVForNoseV2(uv,
                                      lipCenter,
                                      lipRadiusXY,
                                      lipScaleFactor,
                                      5.0,
                                      0.02,
                                      0.0,
                                      nosePoints,
                                      noseCount);

     return inputTexture.sample(textureSampler, uvNose);
 }
