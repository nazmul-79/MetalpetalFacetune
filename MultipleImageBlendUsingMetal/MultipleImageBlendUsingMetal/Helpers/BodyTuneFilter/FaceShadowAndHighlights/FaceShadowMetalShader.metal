//
//  FaceShadowMetalShader.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 29/9/25.
//
#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

// --- Signed distance from a point to polygon ---
// Negative inside, positive outside
// --- Extend point for fixed top/bottom ---
inline float2 extendPoint(float2 p, float2 centroid, float topScale, float bottomScale)
{
    float2 dir = p - centroid;
    if (dir.y > 0.0) {
        dir.y *= (1.0 + bottomScale);  // extend bottom
    } else {
        dir.y *= (1.0 + topScale);     // extend top
    }
    return centroid + dir;
}

// --- Signed distance polygon (negative inside, positive outside) ---
inline float signedDistancePolygon(float2 p, thread const float2 *pts, uint n)
{
    float minDist = 1e6;
    float winding = 0.0;

    for (uint i = 0; i < n; i++) {
        float2 a = pts[i];
        float2 b = pts[(i + 1) % n];

        float2 e = b - a;
        float2 w = p - a;
        float proj = clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
        float2 closest = a + proj * e;
        minDist = min(minDist, length(p - closest));

        // Winding (angle sum)
        float2 v1 = normalize(a - p);
        float2 v2 = normalize(b - p);
        winding += atan2(v1.x * v2.y - v1.y * v2.x, dot(v1, v2));
    }

    return (abs(winding) > 1.0 ? -minDist : minDist);
}

//fragment float4 FaceShadowMetalShader(VertexOut vert [[stage_in]],
//                            texture2d<float, access::sample> inputTexture [[texture(0)]],
//                            sampler textureSampler [[sampler(0)]],
//                            device const float2 *points [[buffer(0)]],
//                            constant uint &count [[buffer(1)]])
//{
//    float2 uv = vert.textureCoordinate;
//
//       // --- Base color ---
//       float4 color = inputTexture.sample(textureSampler, uv);
//       float3 base = color.rgb;
//       float alpha = color.a;
//
//       // --- Polygon signed distance ---
//       float d = signedDistancePolygon(uv, points, count);
//       bool inside = (d < 0.0);
//
//       float mask = 0.0;
//
//       if (inside) {
//           // --- Centroid ---
//           float2 centroid = float2(0.0);
//           for (uint i = 0; i < count; i++) centroid += points[i];
//           centroid /= float(count);
//
//           float distToCenter = distance(uv, centroid);
//
//           // --- Compute max radius ---
//           float maxRadius = 0.0;
//           for (uint i = 0; i < count; i++)
//               maxRadius = max(maxRadius, distance(points[i], centroid));
//
//           // --- Radial shadow ---
//           float radialShadow = smoothstep(maxRadius * 0.3, maxRadius, distToCenter) * 0.6;
//
//           // --- Directional shadows ---
//           float2 dir = normalize(uv - centroid);
//           float cheek = abs(dir.x) * 0.4;
//           float chin = max(0.0, dir.y) * 0.5;
//           float temple = (abs(dir.x) * max(0.0, -dir.y)) * 0.3;
//
//           float falloff = 1.0 - smoothstep(0.0, maxRadius, distToCenter);
//           float directional = (cheek + chin + temple) * falloff;
//
//           mask = radialShadow + directional;
//
//           // --- Center light boost ---
//           float centerLight = 1.0 - smoothstep(0.0, maxRadius * 0.4, distToCenter);
//           mask *= (1.0 - centerLight * 0.5);
//
//           // --- Feather near border for natural blending ---
//           float borderFeather = smoothstep(0.005, 0.0, -d); // inside fade
//           mask *= borderFeather;
//       }
//
//       // --- Apply shadow ---
//       float shadowIntensity = 0.4;
//       float3 shadowColor = base * (1.0 - mask * shadowIntensity);
//
//       // Slight cool tone
//       float3 coolTone = float3(0.92, 0.95, 1.0);
//       shadowColor *= mix(float3(1.0), coolTone, mask * 0.1);
//
//       return float4(shadowColor, alpha);
//}


fragment float4 FaceShadowMetalShader(VertexOut vert [[stage_in]],
                            texture2d<float, access::sample> inputTexture [[texture(0)]],
                            sampler textureSampler [[sampler(0)]],
                            constant float &faceScaleFactor [[buffer(0)]],
                            constant float2 &faceRectCenter [[buffer(1)]],
                            constant float2 &faceRectRadius [[buffer(2)]],
                            device const float2 *points [[buffer(3)]],
                            constant uint &count [[buffer(4)]])
{
    /*float2 uv = vert.textureCoordinate;
     float4 baseColor = inputTexture.sample(textureSampler, uv);
     float3 base = baseColor.rgb;
     float alpha = baseColor.a;
     
     // --- Compute centroid ---
     float2 centroid = float2(0.0);
     for (uint i = 0; i < count; i++) centroid += points[i];
     centroid /= float(count);
     
     // --- Fixed top/bottom extension ---
     const float topScale    = 0.2;
     const float bottomScale = 0.05;
     thread float2 extPoints[128];
     for (uint i = 0; i < count; i++)
     extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);
     
     // --- Signed distance for extended polygon ---
     float dpoly = signedDistancePolygon(uv, extPoints, count);
     
     // --- Polygon mask ---
     float mask = 0.0;
     if (dpoly < 0.0) {
     mask = smoothstep(0.0, -dpoly, -dpoly); // inside polygon
     }
     
     if (mask <= 0.0) {
     return float4(base, alpha); // outside polygon → original
     }
     
     // --- Shadow adjustment like CIHighlightShadowAdjust ---
     float sf = clamp(faceScaleFactor / 200.0, -0.5, +0.5);
     float shadowIntensity = 0.4 * (1.0 + sf);
     
     // Luminance
     float luminance = dot(base, float3(0.3, 0.3, 0.3));
     
     // Shadow result (adjust shadows only)
     float3 shadowResult = max(base, base * (luminance + shadowIntensity));
     
     // Smoothly blend inside polygon
     float3 finalColor = mix(base, shadowResult, mask);
     
     // Optional slight cool tone
     float3 coolTone = float3(0.92, 0.95, 1.0);
     finalColor *= mix(float3(1.0), coolTone, mask * 0.1);
     
     return float4(finalColor, alpha);*/
    
    /*float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 base = baseColor.rgb;
    float alpha = baseColor.a;
    
    // --- Compute centroid ---
    float2 centroid = float2(0.0);
    for (uint i = 0; i < count; i++) centroid += points[i];
    centroid /= float(count);
    
    // --- Fixed top/bottom extension ---
    const float topScale    = 0.2;
    const float bottomScale = 0.05;
    thread float2 extPoints[128];
    for (uint i = 0; i < count; i++)
            extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);
    
    // --- Signed distance for extended polygon ---
    float dpoly = signedDistancePolygon(uv, extPoints, count);
    
    // --- Improved polygon mask with soft edges ---
    float mask = 0.0;
    float edgeWidth = 0.015; // Soft edge width
    
    if (dpoly < edgeWidth) {
        mask = 1.0 - smoothstep(-edgeWidth, edgeWidth, dpoly);
    }
    
    if (mask <= 0.0) {
        return float4(base, alpha); // outside polygon → original
    }
    
    // --- Enhanced shadow adjustment ---
    float sf = clamp(faceScaleFactor / 200.0, -0.5, +0.5);
    float shadowIntensity = 0.4 * (1.0 + sf);
    
    // Calculate luminance
    float luminance = dot(base, float3(0.299, 0.587, 0.114));
    
    // Enhanced shadow with multiple effects
    float3 shadowResult = base * (1.0 - shadowIntensity * 0.5); // Darken
    shadowResult = mix(shadowResult, shadowResult * float3(0.92, 0.95, 1.0), 0.1); // Cool tone
    
    // Add some contrast to shadows
    shadowResult = (shadowResult - 0.5) * (1.0 + shadowIntensity * 0.3) + 0.5;
    
    // Smoothly blend with distance falloff
    float distanceToCenter = distance(uv, centroid);
    float distanceFactor = 1.0 - smoothstep(0.0, 0.4, distanceToCenter);
    float finalMask = mask * distanceFactor;
    
    float3 finalColor = mix(base, shadowResult, finalMask);
    
    return float4(finalColor, alpha);*/
    
    float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 base = baseColor.rgb;
    float alpha = baseColor.a;

    // --- Compute centroid ---
    float2 centroid = float2(0.0);
    for (uint i = 0; i < count; i++) centroid += points[i];
    centroid /= float(count);

    // --- Fixed top/bottom extension ---
    const float topScale    = 0.2;
    const float bottomScale = 0.1;
    thread float2 extPoints[128];
    for (uint i = 0; i < count; i++)
        extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

    // --- Signed distance for extended polygon ---
    float dpoly = signedDistancePolygon(uv, extPoints, count);

    // --- Polygon mask with soft edges ---
    float mask = 0.0;
    float edgeWidth = 0.015;
    if (dpoly < edgeWidth) {
        mask = 1.0 - smoothstep(-edgeWidth, edgeWidth, dpoly);
    }
    if (mask <= 0.0) {
        return float4(base, alpha);
    }

    // --- Normalize scale factor (-100..100 → -1..1) ---
    float sf = clamp(faceScaleFactor / 200.0, -1.0, 1.0);

    // --- Distance falloff (area based blending) ---
    float distanceToCenter = distance(uv, centroid);
    float distanceFactor = 1.0 - smoothstep(0.0, 0.5, distanceToCenter);
    float finalMask = mask * distanceFactor * abs(sf); // stronger when |sf| is high

    // --- Shadow (darken) ---
    float3 shadowResult = base * (1.0 - 0.5 * abs(sf));
    shadowResult = (shadowResult - 0.5) * (1.0 + 0.3 * abs(sf)) + 0.5;

    // --- Highlight (whitish glow) ---
    float3 highlightResult = mix(base, float3(1.0, 1.0, 1.0), 0.4 * abs(sf));

    // --- Choose based on sign of sf ---
    float3 target = (sf < 0.0) ? shadowResult : highlightResult;

    // --- Final smooth blend ---
    float3 finalColor = mix(base, target, finalMask);

    return float4(finalColor, alpha);
    
    /*float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 base = baseColor.rgb;
    float alpha = baseColor.a;

    // --- Compute centroid ---
    float2 centroid = float2(0.0);
    for (uint i = 0; i < count; i++) centroid += points[i];
    centroid /= float(count);

    // --- Fixed top/bottom extension ---
    const float topScale    = 0.2;
    const float bottomScale = 0.05;

    constexpr uint MAX_POINTS = 64;           // reduced from 128
    thread float2 extPoints[MAX_POINTS];

    // Safety: clamp count to MAX_POINTS
    uint safeCount = min(count, MAX_POINTS);

    for (uint i = 0; i < safeCount; i++)
        extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

    // --- Signed distance for extended polygon ---
    float dpoly = signedDistancePolygon(uv, extPoints, safeCount);

    // --- Polygon mask with soft edges ---
    float mask = 0.0;
    float edgeWidth = 0.015; // Soft edge width

    if (dpoly < edgeWidth) {
        mask = 1.0 - smoothstep(-edgeWidth, edgeWidth, dpoly);
    }

    if (mask <= 0.0) {
        return float4(base, alpha); // outside polygon → original
    }

    // --- Normalize scale factor (-100..100 → -1..1) ---
    float sf = clamp(faceScaleFactor / 200.0, -1.0, 1.0);

    // --- Distance falloff (area based blending) ---
    float distanceToCenter = distance(uv, centroid);
    float distanceFactor = 1.0 - smoothstep(0.0, 0.5, distanceToCenter);
    float finalMask = mask * distanceFactor * abs(sf); // stronger when |sf| is high

    // --- Shadow (darken) ---
    float3 shadowResult = base * (1.0 - 0.5 * abs(sf));
    shadowResult = (shadowResult - 0.5) * (1.0 + 0.3 * abs(sf)) + 0.5;

    // --- Highlight (whitish glow) ---
    float3 highlightResult = mix(base, float3(1.0, 1.0, 1.0), 0.4 * abs(sf));

    // --- Choose based on sign of sf ---
    float3 target = (sf < 0.0) ? shadowResult : highlightResult;

    // --- Final smooth blend ---
    float3 finalColor = mix(base, target, finalMask);

    return float4(finalColor, alpha);*/
    
   /* float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 base = baseColor.rgb;
    float alpha = baseColor.a;

    // --- Compute centroid ---
    float2 centroid = float2(0.0);
    for (uint i = 0; i < count; i++) centroid += points[i];
    centroid /= float(count);

    // --- Fixed top/bottom extension ---
    const float topScale    = 0.5;
    const float bottomScale = 0.05;
    constexpr uint MAX_POINTS = 64;
    thread float2 extPoints[MAX_POINTS];
    uint safeCount = min(count, MAX_POINTS);
    for (uint i = 0; i < safeCount; i++)
        extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

    // --- Signed distance for extended polygon ---
    float dpoly = signedDistancePolygon(uv, extPoints, safeCount);

    // --- Polygon mask with soft edges ---
    float mask = 0.0;
    float edgeWidth = 0.015;
    if (dpoly < edgeWidth) {
        mask = 1.0 - smoothstep(-edgeWidth, edgeWidth, dpoly);
    }
    if (mask <= 0.0) {
        return float4(base, alpha); // outside polygon → original
    }

    // --- Normalize scale factor (0..100 → 0..1) ---
    float highlightStrength = clamp(faceScaleFactor / 50.0, 0.0, 1.0);

    // --- Distance falloff ---
    float distanceToCenter = distance(uv, centroid);
    float distanceFactor = 1.0 - smoothstep(0.0, 0.5, distanceToCenter);

    // --- Pixel luminance based highlight ---
    float luminance = dot(base, float3(0.299, 0.587, 0.114));
    float highlightMask = smoothstep(0.6, 1.0, luminance); // adjust threshold

    // --- Combined mask ---
    float finalMask = mask * distanceFactor * highlightMask * highlightStrength;

    // --- Highlight color (white) ---
    float3 highlightResult = mix(base, float3(1.0, 1.0, 1.0), 0.5 * highlightMask);

    // --- Final blended color ---
    float3 finalColor = mix(base, highlightResult, finalMask);

    return float4(finalColor, alpha);*/


    /*float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 base = baseColor.rgb;
    float alpha = baseColor.a;

    // --- Compute centroid ---
    float2 centroid = float2(0.0);
    for (uint i = 0; i < count; i++) centroid += points[i];
    centroid /= float(count);

    // --- Fixed top/bottom extension ---
    const float topScale    = 0.5;
    const float bottomScale = 0.05;
    constexpr uint MAX_POINTS = 64;
    thread float2 extPoints[MAX_POINTS];
    uint safeCount = min(count, MAX_POINTS);
    for (uint i = 0; i < safeCount; i++)
        extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

    // --- Signed distance for extended polygon ---
    float dpoly = signedDistancePolygon(uv, extPoints, safeCount);

    // --- Polygon mask with soft edges ---
    float mask = 0.0;
    float edgeWidth = 0.015;
    if (dpoly < edgeWidth) {
        mask = 1.0 - smoothstep(-edgeWidth, edgeWidth, dpoly);
    }
    if (mask <= 0.0) {
        return float4(base, alpha); // outside polygon → original
    }

    // --- Normalize scale factor (-100..100 → -1..1) ---
    float sf = clamp(faceScaleFactor / 100.0, -1.0, 1.0);

    // --- Use only positive for highlight ---
    float highlightStrength = max(sf, 0.0);

    // --- Distance falloff ---
    float distanceToCenter = distance(uv, centroid);
    float distanceFactor = 1.0 - smoothstep(0.0, 0.5, distanceToCenter);

    // --- Pixel luminance based highlight (all skin tones friendly) ---
    float luminance = dot(base, float3(0.299, 0.587, 0.114));
    float highlightMask = clamp(luminance + 0.3 * highlightStrength, 0.0, 1.0);

    // --- Combined final mask ---
    float finalMask = mask * distanceFactor * highlightMask * highlightStrength;

    // --- Highlight color (white) ---
    float3 highlightResult = mix(base, float3(1.0, 1.0, 1.0), 0.5 * highlightMask);

    // --- Final blended color ---
    float3 finalColor = mix(base, highlightResult, finalMask);

    return float4(finalColor, alpha);*/

}
