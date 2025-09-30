//
//  NeckShadowFragmentShader.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 29/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

#include <metal_stdlib>
using namespace metalpetal;

// --- Signed distance to polygon ---
inline float signedDistancePolygon(float2 p, device const float2 *points, uint count) {
    float minDist = 1e6;
    bool inside = false;
    for (uint i = 0; i < count; i++) {
        float2 a = points[i];
        float2 b = points[(i + 1) % count];
        float2 ab = b - a;
        float2 ap = p - a;
        float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
        float2 proj = a + t * ab;
        float dist = distance(p, proj);
        minDist = min(minDist, dist);

        // Winding test
        if (((a.y > p.y) != (b.y > p.y)) &&
            (p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x)) {
            inside = !inside;
        }
    }
    return inside ? -minDist : minDist;
}

float edgeMaskTriangle(float2 uv, float2 p0, float2 p1, float2 p2, float width) {
    // Barycentric coordinates
    float2 v0 = p1 - p0;
    float2 v1 = p2 - p0;
    float2 v2 = uv - p0;
    float d00 = dot(v0, v0);
    float d01 = dot(v0, v1);
    float d11 = dot(v1, v1);
    float d20 = dot(v2, v0);
    float d21 = dot(v2, v1);
    float denom = d00 * d11 - d01 * d01;
    float u = (d11*d20 - d01*d21) / denom;
    float v = (d00*d21 - d01*d20) / denom;

    // Inside triangle? (with feather for soft edge)
    float f = smoothstep(-width, 0.0, u) * smoothstep(-width, 0.0, v) * smoothstep(-width, 0.0, 1.0 - u - v);
    return f;
}

fragment float4 neckShadowShader(
    VertexOut in [[stage_in]],
    texture2d<float> tex [[texture(0)]],
    device const float2 *jawPoints [[buffer(0)]],
    constant uint &outerCount [[buffer(1)]],
    constant float &scaleFactor [[buffer(2)]]
)
{
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    if (alpha < 0.01) return texColor;

    float3 base = texColor.rgb;

    // --- Distance mask ---
    float dJaw = signedDistancePolygon(uv, jawPoints, outerCount);

    // Feather / soft edges
    float feather = 0.06;
    float mask = 1.0 - smoothstep(-feather, feather, dJaw);
    mask = mask*mask*(3.0 - 2.0*mask); // cubic smoothstep for corners

    // --- Normalize slider -100..100 → -1..1 ---
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);

    // --- Shadow / highlight strengths ---
    float maxDark = 0.3;  // subtle shadow
    float maxLight = 0.2; // subtle highlight

    float3 adjustedColor;

    if (factor > 0.0) {
        // DARK: scale each pixel proportionally
        adjustedColor = base * (1.0 - mask * factor * maxDark);
    } else {
        // LIGHT: add subtle brightness proportionally
        adjustedColor = base + (1.0 - base) * mask * (-factor) * maxLight;
    }

    adjustedColor = clamp(adjustedColor, 0.0, 1.0);

    return float4(adjustedColor, alpha);*/
    
   /* constexpr sampler s(address::clamp_to_edge, filter::linear);
        float2 uv = in.textureCoordinate;

        float4 texColor = tex.sample(s, uv);
        float alpha = texColor.a;
        if (alpha < 0.01) return texColor;

        float3 base = texColor.rgb;
        float mask = 0.0;
        float lineThickness = 0.0025;  // UV thickness
        float lineLength = 0.08;       // hardcoded line length in UV space (~80 pixels if normalized)

        for (uint i = 0; i < outerCount; i++) {
            float2 topPoint = jawPoints[i];
            float2 bottomPoint = float2(topPoint.x, topPoint.y + lineLength); // vertical down

            float2 dir = bottomPoint - topPoint;
            float2 perp = normalize(float2(-dir.y, dir.x));
            float2 diff = uv - topPoint;

            float dist = abs(dot(diff, perp));
            float t = dot(diff, dir) / dot(dir, dir);

            if (t >= 0.0 && t <= 1.0) {
                float lineMask = smoothstep(lineThickness, 0.0, dist);
                mask = max(mask, lineMask);
            }
        }

        float3 lineColor = float3(1.0, 0.0, 0.0); // red
        float3 finalColor = mix(base, lineColor, mask);

        return float4(finalColor, alpha);*/
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    if (alpha < 0.01) return texColor;

    float3 base = texColor.rgb;
    float mask = 0.0;
    float lineWidth = 0.0025;
    float lineLength = 0.08;

    // Bottom points (corresponding)
    float2 bottomPoints[10];
    for (uint i = 0; i < outerCount; i++) {
        bottomPoints[i] = jawPoints[i] + float2(0.0, lineLength);
    }

    // Iterate neighbors to form triangles (quad)
    for (uint i = 0; i < outerCount - 1; i++) {
        float2 topA = jawPoints[i];
        float2 topB = jawPoints[i+1];
        float2 bottomA = bottomPoints[i];
        float2 bottomB = bottomPoints[i+1];

        // Triangle 1: topA, bottomA, topB
        float mask1 = edgeMaskTriangle(uv, topA, bottomA, topB, lineWidth);

        // Triangle 2: topB, bottomA, bottomB
        float mask2 = edgeMaskTriangle(uv, topB, bottomA, bottomB, lineWidth);

        mask = max(mask, max(mask1, mask2));
    }

    // Optional cubic smoothstep
    mask = mask*mask*(3.0 - 2.0*mask);

    // --- Apply shadow/highlight factor ---
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
    float maxDark = 0.35;
    float maxLight = 0.25;
    float3 adjustedColor;
    if (factor > 0.0) {
        adjustedColor = base * (1.0 - mask * factor * maxDark);
    } else {
        adjustedColor = base + (1.0 - base) * mask * (-factor) * maxLight;
    }
    adjustedColor = clamp(adjustedColor, 0.0, 1.0);
    return float4(adjustedColor, alpha);
}

    
/*// --- Fragment shader ---
fragment float4 neckShadowShader(
    VertexOut in [[stage_in]],
    texture2d<float> tex [[texture(0)]],
    device const float2 *jawPoints [[buffer(0)]],
    constant uint &outerCount [[buffer(1)]],
    constant float &scaleFactor [[buffer(2)]]
)
{
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    if (alpha < 0.01) return texColor;

    float3 base = texColor.rgb;

    // --- Distance mask ---
    float dJaw = signedDistancePolygon(uv, jawPoints, outerCount);

    // Feather / soft edges
    float feather = 0.06;  // increased for very smooth blending
    float mask = 1.0 - smoothstep(-feather, feather, dJaw);

    // Smooth corners using cubic smoothstep
    mask = mask*mask*(3.0 - 2.0*mask);

    // --- Normalize slider -100..100 → -1..1 ---
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);

    // --- Shadow / highlight strengths ---
    float maxDark = 0.35;  // subtle shadow
    float maxLight = 0.25; // subtle highlight

    float3 adjustedColor;
    if (factor > 0.0) {
        // Darker: apply smooth shadow
        adjustedColor = base * (1.0 - mask * factor * maxDark);
    } else {
        // Lighter: apply smooth highlight
        adjustedColor = base + (1.0 - base) * mask * (-factor) * maxLight;
    }

    adjustedColor = clamp(adjustedColor, 0.0, 1.0);

    return float4(adjustedColor, alpha);
}
*/
