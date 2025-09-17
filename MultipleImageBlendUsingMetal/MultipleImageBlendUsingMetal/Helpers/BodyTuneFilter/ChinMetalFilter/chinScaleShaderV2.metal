//
//  chinScaleShaderV2.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 15/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

/*inline bool pointInPolygon(float2 uv, device const float2 *points, uint count) {
    bool inside = false;
    for (uint i=0, j=count-1; i<count; j=i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        if (((pi.y>uv.y)!=(pj.y>uv.y)) &&
            (uv.x < (pj.x-pi.x)*(uv.y-pi.y)/(pj.y-pi.y + 1e-6) + pi.x))
            inside = !inside;
    }
    return inside;
}

// Distance from point to line segment
inline float distanceToSegment(float2 p, float2 a, float2 b) {
    float2 ab = b - a;
    float2 ap = p - a;
    float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
    float2 proj = a + t * ab;
    return length(p - proj);
}

// Draw polygon outline with thickness
inline float polygonEdgeMask(float2 uv, device const float2 *points, uint count, float thickness) {
    float minDist = 1e6;
    for (uint i=0;i<count;i++) {
        uint j = (i+1)%count;
        minDist = min(minDist, distanceToSegment(uv, points[i], points[j]));
    }
    // smoothstep for anti-aliased edge
    return 1.0 - smoothstep(0.0, thickness, minDist);
}


fragment float4 cheeksFilterV2(VertexOut vert [[stage_in]],
                            texture2d<float, access::sample> inputTexture [[texture(0)]],
                            sampler textureSampler [[sampler(0)]],
                            constant float &scaleFactor [[buffer(0)]],
                            device const float2 *points [[buffer(1)]],
                            constant uint &count [[buffer(2)]])
{
    float2 uv = vert.textureCoordinate;
    
    // --- Scale polygon area like before ---
    float2 centroid = float2(0.0);
    for (uint i=0;i<count;i++) centroid += points[i];
    centroid /= float(count);
    
    float2 diff = uv - centroid;
    float maxDist = 0.0;
    for (uint i=0;i<count;i++) maxDist = max(maxDist, length(points[i]-centroid));
    
    float2 dir = diff / (maxDist + 1e-6);
    float2 uvScaled = centroid + dir * maxDist * (scaleFactor/100.0);
    
    // --- Draw polygon edge (outline) ---
    float edgeMask = polygonEdgeMask(uv, points, count, 0.003); // thickness in UV units
    
    float4 texColor = inputTexture.sample(textureSampler, uvScaled);
    
    // Blend edge with red color
    float4 edgeColor = float4(1.0, 0.0, 0.0, 1.0);
    
    float4 finalColor = mix(texColor, edgeColor, edgeMask);
    
    return finalColor;
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

// Point-in-polygon
inline bool pointInPolygon(float2 uv, device const float2 *points, uint count) {
    bool inside = false;
    for (uint i=0, j=count-1; i<count; j=i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        if (((pi.y>uv.y)!=(pj.y>uv.y)) &&
            (uv.x < (pj.x-pi.x)*(uv.y-pi.y)/(pj.y-pi.y + 1e-6) + pi.x))
            inside = !inside;
    }
    return inside;
}

// Distance to segment
inline float distanceToSegment(float2 p, float2 a, float2 b) {
    float2 ab = b - a;
    float2 ap = p - a;
    float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
    float2 proj = a + t * ab;
    return length(p - proj);
}

// Draw polygon edge, skip top-left → top-right
inline float polygonEdgeMaskVShape(float2 uv, device const float2 *points, uint count, float thickness) {
    float minDist = 1e6;
    
    // edges sequential except top-left → top-right
    for (uint i=0; i<count-1; i++) {
        // skip connecting last-left to first-right if it's the top edge
        if (i == 5 && (i+1) == 6) continue; // adjust index according to your points array
        minDist = min(minDist, distanceToSegment(uv, points[i], points[i+1]));
    }
    
    // optional: connect last point to first if needed
    // minDist = min(minDist, distanceToSegment(uv, points[count-1], points[0]));
    
    return 1.0 - smoothstep(0.0, thickness, minDist);
}

fragment float4 cheeksFilterV2(VertexOut vert [[stage_in]],
                            texture2d<float, access::sample> inputTexture [[texture(0)]],
                            sampler textureSampler [[sampler(0)]],
                            constant float &scaleFactor [[buffer(0)]],
                            device const float2 *points [[buffer(1)]],
                            constant uint &count [[buffer(2)]])
{
    float2 uv = vert.textureCoordinate;
    
    // --- Scale polygon area ---
    float2 centroid = float2(0.0);
    for (uint i=0;i<count;i++) centroid += points[i];
    centroid /= float(count);
    
    float2 diff = uv - centroid;
    float maxDist = 0.0;
    for (uint i=0;i<count;i++) maxDist = max(maxDist, length(points[i]-centroid));
    
    float2 dir = diff / (maxDist + 1e-6);
    float2 uvScaled = centroid + dir * maxDist * (scaleFactor/100.0);
    
    // --- Edge mask ---
    float edgeMask = polygonEdgeMaskVShape(uv, points, count, 0.003);
    
    float4 texColor = inputTexture.sample(textureSampler, uvScaled);
    float4 edgeColor = float4(1.0, 0.0, 0.0, 1.0);
    
    return mix(texColor, edgeColor, edgeMask);
}

*/

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

inline float distanceToLineSegment(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    if (l2 < 1e-6) return length(p - v);
    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
    float2 projection = v + t * vw;
    return length(p - projection);
}

inline float pointWeightFromVShape(float2 uv, device const float2* points, uint count, float radius) {
    float minDist = 1e6;
    for (uint i=0;i<count-1;i++) {
        // top-left → top-right special case
        if (i == 5 && (i+1) == 6) {
            float2 v = points[i];
            float2 w = points[i+1];
            float2 mid = (v+w)*0.5;
            float d1 = distanceToLineSegment(uv, v, mid);
            float d2 = distanceToLineSegment(uv, mid, w);
            minDist = min(minDist, min(d1,d2));
            continue;
        }
        minDist = min(minDist, distanceToLineSegment(uv, points[i], points[i+1]));
    }
    return smoothstep(radius, 0.0, minDist);
}

fragment float4 cheeksFilterV2(VertexOut vert [[stage_in]],
                               texture2d<float, access::sample> inputTexture [[texture(0)]],
                               constant float &scaleFactor [[buffer(0)]],
                               device const float2 *points [[buffer(1)]],
                               constant uint &count [[buffer(2)]])
{
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- normalized scale ---
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale);

    // --- weight from V-shape line ---
    float radius = 0.04;
    float weight = pointWeightFromVShape(uv, points, count, radius);
    weight = weight * weight * (3.0 - 2.0 * weight); // smooth falloff

    if (weight < 0.01) return inputTexture.sample(s, uv); // outside area, skip

    // --- scale vector based on distance from nearest line ---
    float2 center = float2(0.0);
    for (uint i = 0; i < count; i++) center += points[i];
    center /= float(count);

    float2 offset = uv - center;

    // --- scale proportional to weight, clamped ---
    float maxScaleH = 0.06; // reduce horizontal max scale
    float maxScaleV = 0.03; // reduce vertical max scale
    float2 newUV = uv + offset * normalizedScale * float2(maxScaleH, maxScaleV) * weight;

    newUV = clamp(newUV, float2(0.0), float2(1.0));
    return inputTexture.sample(s, newUV);
}
