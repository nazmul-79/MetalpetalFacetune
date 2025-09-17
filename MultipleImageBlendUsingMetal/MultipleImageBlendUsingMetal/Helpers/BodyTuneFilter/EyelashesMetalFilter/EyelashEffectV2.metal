//
//  EyelashEffectV2.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 17/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;


/*// --- Helpers ---

// Inflate a point from the center by a small amount
inline float2 inflatedPoint(float2 p, float2 center, float inflateAmount) {
    float2 dir = p - center;
    float len = length(dir);
    if (len > 0.0) {
        return p + (dir / len) * inflateAmount;
    }
    return p;
}

// Point-in-polygon test with inflated points
inline bool pointInPolygonInflated(float2 uv, device const float2 *points, uint count, float2 center, float inflateAmount) {
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = inflatedPoint(points[i], center, inflateAmount);
        float2 pj = inflatedPoint(points[j], center, inflateAmount);
        if (((pi.y > uv.y) != (pj.y > uv.y)) &&
            (uv.x < (pj.x - pi.x) * (uv.y - pi.y) / (pj.y - pi.y + 1e-6) + pi.x)) {
            inside = !inside;
        }
    }
    return inside;
}

// Distance to polygon edges with inflated points
inline float distanceToPolygonInflated(float2 uv, device const float2 *points, uint count, float2 center, float inflateAmount) {
    float minDist = 1e6;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 p1 = inflatedPoint(points[j], center, inflateAmount);
        float2 p2 = inflatedPoint(points[i], center, inflateAmount);
        float2 edge = p2 - p1;
        float2 toPoint = uv - p1;
        float t = clamp(dot(toPoint, edge) / (dot(edge, edge) + 1e-6), 0.0, 1.0);
        float2 proj = p1 + t * edge;
        minDist = min(minDist, distance(uv, proj));
    }
    return minDist;
}

// --- Fragment Shader ---
fragment float4 eyelashShader(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              constant float &scaleFactor [[buffer(0)]],   // কতটা dark হবে
                              device const float2 *points [[buffer(1)]],
                              constant uint &count [[buffer(2)]])
{
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
       float2 uv = vert.textureCoordinate;
       float4 color = inputTexture.sample(textureSampler, uv);

       // --- Polygon bounds & center ---
       float2 minPoint = points[0];
       float2 maxPoint = points[0];
       for (uint i = 1; i < count; i++) {
           minPoint = min(minPoint, points[i]);
           maxPoint = max(maxPoint, points[i]);
       }
       float2 center = (minPoint + maxPoint) * 0.5;

       // --- Texel size & inflation ---
       float2 texelSize = float2(1.0 / float(inputTexture.get_width()),
                                 1.0 / float(inputTexture.get_height()));
       float inflateAmount = max(texelSize.x, texelSize.y) * 5.0;

       // --- Polygon inclusion ---
       bool inside = pointInPolygonInflated(uv, points, count, center, inflateAmount);
       if (!inside) return color;

       // --- Distance to polygon edges ---
       float dist = distanceToPolygonInflated(uv, points, count, center, inflateAmount);

       // --- Smooth anti-aliased edge mask ---
       float edgeWidth = max(texelSize.x, texelSize.y) * 1.0; // ~1 pixel
       float edgeMask = exp(-pow(dist / edgeWidth, 2.0));     // Gaussian smoothing
       if (edgeMask <= 0.001) return color;                  // skip deep inside

       // --- Effect intensity ---
       float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
       float intensityMultiplier = (factor > 0.0) ? 0.8 : 0.9;
       float finalMask = edgeMask * abs(factor) * intensityMultiplier;

       // --- Eyelash color ---
       float3 lashColor = float3(1.0, 1.0, 1.0);
       color.rgb = mix(color.rgb, lashColor, finalMask);

       return color;
}

*/

/*// --- Inflate a point from the center ---
inline float2 inflatedPoint(float2 p, float2 center, float inflateAmount) {
    float2 dir = p - center;
    float len = length(dir);
    if (len > 0.0) return p + (dir / len) * inflateAmount;
    return p;
}

// --- Soft distance to polygon edges with smooth corners ---
inline float softDistanceToPolygon(float2 uv,
                                   device const float2 *points,
                                   uint count,
                                   float2 center,
                                   float inflateAmount,
                                   float curve = 0.005) // controls smoothness of corners
{
    float minDist = 1e6;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 p1 = inflatedPoint(points[j], center, inflateAmount);
        float2 p2 = inflatedPoint(points[i], center, inflateAmount);
        float2 edge = p2 - p1;
        float2 toPoint = uv - p1;
        float t = clamp(dot(toPoint, edge) / (dot(edge, edge) + 1e-6), 0.0, 1.0);
        float2 proj = p1 + t * edge;
        float d = distance(uv, proj);

        // smooth corners by blending neighboring edges
        minDist = min(minDist, d - curve);
    }
    return max(minDist, 0.0); // ensure non-negative distance
}

// --- Fragment shader ---
fragment float4 eyelashShader(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              constant float &scaleFactor [[buffer(0)]],
                              device const float2 *points [[buffer(1)]],
                              constant uint &count [[buffer(2)]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(textureSampler, uv);

    // --- Polygon bounds & center ---
    float2 minPoint = points[0];
    float2 maxPoint = points[0];
    for (uint i = 1; i < count; i++) {
        minPoint = min(minPoint, points[i]);
        maxPoint = max(maxPoint, points[i]);
    }
    float2 center = (minPoint + maxPoint) * 0.5;

    // --- Texel size & inflation ---
    float2 texelSize = float2(1.0 / float(inputTexture.get_width()),
                              1.0 / float(inputTexture.get_height()));
    float inflateAmount = max(texelSize.x, texelSize.y) * 4.0;

    // --- Soft distance field ---
    float dist = softDistanceToPolygon(uv, points, count, center, inflateAmount, 0.002);

    // --- Edge mask for smooth border ---
    float edgeWidth = max(texelSize.x, texelSize.y) * 2.0;
    float edgeMask = smoothstep(edgeWidth, 0.0, dist);
    if (edgeMask <= 0.01) return color;

    // --- Effect intensity ---
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
    float intensity = abs(factor) * edgeMask;

    // --- Eyelash color ---
    float3 lashColor = float3(0.1, 0.05, 0.02);

    if (factor > 0.0) {
        color.rgb = mix(color.rgb, lashColor, intensity * 0.8);
    } else {
        float3 lightened = color.rgb * 1.3;
        color.rgb = mix(color.rgb, lightened, intensity * 0.6);
    }

    return color;
}
*/

// --- Quadratic Bezier interpolation ---
inline float2 quadBezier(float2 p0, float2 p1, float2 p2, float t) {
    float u = 1.0 - t;
    return u*u*p0 + 2.0*u*t*p1 + t*t*p2;
}

// --- Tangent of a quad segment ---
inline float2 quadTangent(float2 p0, float2 p1, float2 p2, float t) {
    float u = 1.0 - t;
    return normalize(2.0*u*(p1 - p0) + 2.0*t*(p2 - p1));
}

// --- Distance to inflated quad segment ---
inline float distanceToInflatedQuadSegment(float2 uv, float2 p0, float2 p1, float2 p2, int steps, float inflate, float2 texelSize) {
    float minDist = 1e6;
    for (int i = 0; i <= steps; i++) {
        float t = float(i) / float(steps);
        float2 pos = quadBezier(p0, p1, p2, t);

        // inflate outward along perpendicular
        float2 tangent = quadTangent(p0, p1, p2, t);
        float2 normal = float2(-tangent.y, tangent.x);
        pos += normal * inflate * max(texelSize.x, texelSize.y);

        float distUV = distance(uv, pos) / max(texelSize.x, texelSize.y);
        minDist = min(minDist, distUV);
    }
    return minDist;
}

// --- Distance to full inflated curve ---
inline float distanceToInflatedQuadCurve(float2 uv, device const float2 *points, uint count, int steps, float inflate, float2 texelSize) {
    float minDist = 1e6;
    for (uint i = 0; i < count - 2; i += 2) { // each 3 points = one quad
        float2 p0 = points[i];
        float2 p1 = points[i+1];
        float2 p2 = points[i+2];
        float d = distanceToInflatedQuadSegment(uv, p0, p1, p2, steps, inflate, texelSize);
        minDist = min(minDist, d);
    }
    return minDist;
}

// --- Fragment shader ---
fragment float4 eyelashShader(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              constant float &scaleFactor [[buffer(0)]],
                              device const float2 *points [[buffer(1)]],
                              constant uint &count [[buffer(2)]])
{
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(s, uv);

    float2 texelSize = float2(1.0 / float(inputTexture.get_width()),
                              1.0 / float(inputTexture.get_height()));

    // --- Distance to inflated curve ---
    float inflateAmount = 3.0; // adjust to make the curve “thicker”
    float dist = distanceToInflatedQuadCurve(uv, points, count, 16, inflateAmount, texelSize);

    // --- Edge mask ---
    float thickness = 3.0; // pixels
    float edgeMask = smoothstep(thickness, 0.0, dist);
    if (edgeMask <= 0.01) return color;

    // --- Color ---
    float3 lowerColor = float3(0.06, 0.03, 0.01);
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0); // only positive effect for now
    color.rgb = mix(color.rgb, lowerColor, factor * edgeMask);

    return color;
}
