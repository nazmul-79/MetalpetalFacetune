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
    float maxDark = 0.2;  // subtle shadow
    float maxLight = 0.1; // subtle highlight

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
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
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
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
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
    return float4(adjustedColor, alpha);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
        float2 uv = in.textureCoordinate;

        float4 texColor = tex.sample(s, uv);
        if (texColor.a < 0.01) return texColor;

        float3 base = texColor.rgb;

        // --- Signed distance to jaw polygon ---
        float dJaw = signedDistancePolygon(uv, jawPoints, outerCount);

        // --- Soft edge mask ---
        float feather = 0.06;
        float mask = 1.0 - smoothstep(-feather, feather, dJaw);
        mask = mask * mask * (3.0 - 2.0 * mask);

        // --- Find polygon vertical bounds ---
        float2 minP = jawPoints[0];
        float2 maxP = jawPoints[0];
        for (uint i = 1; i < outerCount; i++) {
            minP = float2(min(minP.x, jawPoints[i].x), min(minP.y, jawPoints[i].y));
            maxP = float2(max(maxP.x, jawPoints[i].x), max(maxP.y, jawPoints[i].y));
        }

        // --- Gradient rising from bottom (shadow under jawline) ---
        float gradientY = smoothstep(minP.y - 0.05, maxP.y + 0.05, uv.y);
        float bottomUpFalloff = pow(1.0 - gradientY, 2.0); // stronger below, fades upward

        // --- Combine polygon mask + bottom-up gradient ---
        float shadowMask = mask * bottomUpFalloff;

        // --- Normalize strength (-1 to 1) ---
        float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);

        float maxDark = 0.45; // slightly stronger for under-jaw
        float maxLight = 0.25;

        float3 adjustedColor;

        if (factor > 0.0) {
            // Darken from below the jaw upward
            adjustedColor = base * (1.0 - shadowMask * factor * maxDark);
        } else {
            // Optional lighten upward if negative
            adjustedColor = base + (1.0 - base) * shadowMask * (-factor) * maxLight;
        }

        adjustedColor = clamp(adjustedColor, 0.0, 1.0);

        return float4(adjustedColor, texColor.a);*/
    
   /* constexpr sampler s(address::clamp_to_edge, filter::linear);
       float2 uv = in.textureCoordinate;

       float4 texColor = tex.sample(s, uv);
       if (texColor.a < 0.01) return texColor;
       float3 base = texColor.rgb;

       // --- Determine top and bottom polygon bounds from jaw points ---
       float2 minP = jawPoints[0];
       float2 maxP = jawPoints[0];
       for (uint i = 1; i < outerCount; i++) {
           minP = float2(min(minP.x, jawPoints[i].x), min(minP.y, jawPoints[i].y));
           maxP = float2(max(maxP.x, jawPoints[i].x), max(maxP.y, jawPoints[i].y));
       }

       // add vertical offset for shadow (e.g., ~30 px in UV space)
       float shadowOffset = 0.03; // tweak this to control shadow height
       maxP.y += shadowOffset;

       // --- Check if pixel is inside polygon horizontally and vertically ---
       bool insideX = uv.x >= minP.x && uv.x <= maxP.x;
       bool insideY = uv.y >= minP.y && uv.y <= maxP.y;

       float mask = 0.0;
       if (insideX && insideY) {
           // stronger at top, fades to bottom
           float verticalFalloff = 1.0 - (uv.y - minP.y) / (maxP.y - minP.y);
           mask = pow(clamp(verticalFalloff, 0.0, 1.0), 1.5); // smooth top→bottom
       }

       // --- Normalize factor (-1..1) ---
       float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
       float maxDark = 0.35;
       float maxLight = 0.25;

       float3 adjustedColor;
       if (factor > 0.0) {
           // dark shadow
           adjustedColor = base * (1.0 - mask * factor * maxDark);
       } else {
           // optional light shadow
           adjustedColor = base + (1.0 - base) * mask * (-factor) * maxLight;
       }

       adjustedColor = clamp(adjustedColor, 0.0, 1.0);
       return float4(adjustedColor, texColor.a);*/
    
   /* constexpr sampler s(address::clamp_to_edge, filter::linear);
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

    return float4(adjustedColor, alpha);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    if (alpha < 0.01) return texColor;

    float3 base = texColor.rgb;

    // --- Distance mask for jaw polygon ---
    float dJaw = signedDistancePolygon(uv, jawPoints, outerCount);

    // Feather / soft edges
    float feather = 0.06;
    float mask = 1.0 - smoothstep(-feather, feather, dJaw);
    mask = mask * mask * (3.0 - 2.0 * mask); // cubic smoothstep

    // --- Horizontal falloff from center ---
    float minX = jawPoints[0].x;
    float maxX = jawPoints[0].x;
    for (uint i = 1; i < outerCount; i++) {
        minX = min(minX, jawPoints[i].x);
        maxX = max(maxX, jawPoints[i].x);
    }
    float centerX = (minX + maxX) * 0.5;
    float horizFalloff = 1.0 - abs(uv.x - centerX) / ((maxX - minX) * 0.5);
    horizFalloff = pow(clamp(horizFalloff, 0.0, 1.0), 1.5); // softer on sides

    // --- Combine vertical mask (from polygon) with horizontal falloff ---
    mask *= horizFalloff;

    // --- Normalize factor ---
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
    float maxDark = 0.35;
    float maxLight = 0.25;

    float3 adjustedColor;
    if (factor > 0.0) {
        adjustedColor = base * (1.0 - mask * factor * maxDark); // shadow down
    } else {
        adjustedColor = base + (1.0 - base) * mask * (-factor) * maxLight; // highlight
    }

    adjustedColor = clamp(adjustedColor, 0.0, 1.0);
    return float4(adjustedColor, alpha);*/
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    if (alpha < 0.01) return texColor;

    float3 base = texColor.rgb;

    // --- Polygon distance mask ---
    float dJaw = signedDistancePolygon(uv, jawPoints, outerCount);
    float feather = 0.06;
    float mask = 1.0 - smoothstep(-feather, feather, dJaw);
    mask = mask * mask * (3.0 - 2.0 * mask); // cubic smoothstep

    // --- Horizontal falloff (center → sides) ---
    float minX = jawPoints[0].x;
    float maxX = jawPoints[0].x;
    for (uint i = 1; i < outerCount; i++) {
        minX = min(minX, jawPoints[i].x);
        maxX = max(maxX, jawPoints[i].x);
    }
    float centerX = (minX + maxX) * 0.5;

    // wider horizontal effect: increase denominator slightly
    float horizRange = (maxX - minX) * 0.75; // increase from 0.5 to 0.75
    float horizFalloff = 1.0 - abs(uv.x - centerX) / horizRange;
    horizFalloff = pow(clamp(horizFalloff, 0.0, 1.0), 1.2); // softer exponent

    mask *= horizFalloff;

    // --- Factor ---
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
    float maxDark = 0.25;
    float maxLight = 0.15;

    float3 adjustedColor;
    if (factor > 0.0) {
        adjustedColor = base * (1.0 - mask * factor * maxDark); // shadow
    } else {
        adjustedColor = base + (1.0 - base) * mask * (-factor) * maxLight; // highlight
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
