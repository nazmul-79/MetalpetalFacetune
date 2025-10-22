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
/*inline float2 extendPoint(float2 p, float2 centroid, float topScale, float bottomScale)
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
*/

inline float sdSegment(float2 p, float2 a, float2 b) {
    float2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// --- Extend point vertically based on centroid ---
inline float2 extendPoint(float2 p, float2 centroid, float topScale, float bottomScale) {
    float2 dir = normalize(p - centroid);
    float scale = mix(bottomScale, topScale, step(centroid.y, p.y));
    return centroid + dir * (1.0 + scale) * length(p - centroid);
}

// --- Signed distance polygon without array ---
inline float signedDistancePolygonExtended(float2 uv,
                                    device const float2 *points,
                                    uint count,
                                    float2 centroid,
                                    float topScale,
                                    float bottomScale)
{
    float minDist = 1e5;
    float winding = 0.0;

    for (uint i = 0; i < count; i++) {
        float2 a = extendPoint(points[i], centroid, topScale, bottomScale);
        float2 b = extendPoint(points[(i + 1) % count], centroid, topScale, bottomScale);

        float segDist = sdSegment(uv, a, b);
        minDist = min(minDist, segDist);

        // Winding test (inside/outside)
        if (((a.y <= uv.y) && (b.y > uv.y)) || ((a.y > uv.y) && (b.y <= uv.y))) {
            float xCross = a.x + (uv.y - a.y) * (b.x - a.x) / (b.y - a.y);
            if (xCross > uv.x)
                winding += (b.y > a.y) ? 1.0 : -1.0;
        }
    }

    float sign = (fabs(winding) > 0.5) ? -1.0 : 1.0;
    return minDist * sign;
}

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
    
   /* float2 uv = vert.textureCoordinate;
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
    
    /*float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 base = baseColor.rgb;
    float alpha = baseColor.a;

    // --- Compute centroid ---
    float2 centroid = float2(0.0);
    for (uint i = 0; i < count; i++) centroid += points[i];
    centroid /= float(count);

    // --- Extended polygon region ---
    const float topScale    = 0.2;
    const float bottomScale = 0.1;
    thread float2 extPoints[128];
    for (uint i = 0; i < count; i++)
        extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

    // --- Polygon mask (full-area with smooth edges) ---
    float dpoly = signedDistancePolygon(uv, extPoints, count);
    float edgeSoftness = 0.03;
    float mask = smoothstep(-edgeSoftness, 0.0, -dpoly);
    mask = clamp(mask, 0.0, 1.0);

    // --- Normalize control factor (-100..100 → -1..1) ---
    float s = clamp(faceScaleFactor / 400.0, -1.0, 1.0);

    // --- Compute luminance ---
    float lum = dot(base, float3(0.299, 0.587, 0.114));

    // --- Improved shadow adjustment ---
    float3 adjusted;

    if (s >= 0.0) {
        // Lift shadows - only affect dark areas, preserve bright areas
        float liftAmount = s * 0.4;
        float shadowMask = 1.0 - lum; // stronger effect on darker pixels
        shadowMask = pow(shadowMask, 2.0); // smooth curve
        adjusted = base + (liftAmount * shadowMask);
    } else {
        // Deepen shadows - subtle darkening without crushing blacks
        float darkenAmount = abs(s) * 0.4;
        float shadowMask = lum; // stronger effect on brighter pixels
        shadowMask = pow(shadowMask, 0.5); // smooth curve
        adjusted = base * (1.0 - darkenAmount * shadowMask);
    }

    // Clamp to prevent overshoot
    adjusted = clamp(adjusted, 0.0, 1.0);

    // --- Blend using full-area mask ---
    float3 finalColor = mix(base, adjusted, mask);

    // --- Output ---
    return float4(finalColor, alpha);*/
    
    /*float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 base = baseColor.rgb;
    float alpha = baseColor.a;

    // --- Compute centroid ---
    float2 centroid = float2(0.0);
    for (uint i = 0; i < count; i++) centroid += points[i];
    centroid /= float(count);

    // --- Extended polygon region ---
    const float topScale    = 0.25;
    const float bottomScale = 0.2;
    float2 extPoints[64];
    for (uint i = 0; i < count; i++)
        extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

    // --- Polygon mask (full-area with smooth edges) ---
    float dpoly = signedDistancePolygon(uv, extPoints, count);
    float edgeSoftness = 0.03;
    float mask = smoothstep(edgeSoftness, 0.0, dpoly);
    mask = clamp(mask, 0.0, 1.0);

    // --- Normalize control factor (-100..100 → -1..1) ---
    float s = clamp(faceScaleFactor / 400.0, -1.0, 1.0);

    // --- Compute luminance ---
    float lum = dot(base, float3(0.299, 0.587, 0.114));

    // --- Smooth shadow adjustment ---
    float3 adjusted;

    if (s >= 0.0) {
        // Lift shadows - S-shaped smooth curve
        float liftAmount = s * 0.3; // max lift strength
        float shadowMask = 1.0 / (1.0 + exp((lum - 0.25) * 2.0));
        // Darker pixels -> mask ~1, mid -> ~0.5, bright -> ~0
        adjusted = base + liftAmount * shadowMask;
    } else {
        // Deepen shadows smoothly
        float darkenAmount = abs(s) * 0.25;
        float shadowMask = pow(lum, 0.6); // preserve highlights
        adjusted = base * (1.0 - darkenAmount * shadowMask);
    }

    // Clamp to avoid overshoot
    adjusted = clamp(adjusted, 0.0, 1.0);

    // --- Blend using smooth full-area mask ---
    float3 finalColor = mix(base, adjusted, mask);

    // --- Output ---
    return float4(finalColor, alpha);*/
    
    /*float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 base = baseColor.rgb;
    float alpha = baseColor.a;

    // --- Compute centroid ---
    float2 centroid = float2(0.0);
    for (uint i = 0; i < count; i++) centroid += points[i];
    centroid /= float(count);

    // --- Extended polygon region ---
    const float topScale    = 0.2;
    const float bottomScale = 0.1;
    thread float2 extPoints[128];
    for (uint i = 0; i < count; i++)
        extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

    // --- Polygon mask (soft edges) ---
    float dpoly = signedDistancePolygon(uv, extPoints, count);
    float edgeSoftness = 0.03;
    float mask = smoothstep(edgeSoftness, 0.0, dpoly);
    mask = clamp(mask, 0.0, 1.0);

    // --- Normalize control factor (-100..100 → 0..1) ---
    float s = clamp(faceScaleFactor / 200.0, 0.0, 1.0); // highlight amount 0–1

    // --- Compute luminance ---
    float lum = dot(base, float3(0.299, 0.587, 0.114));

    // --- Natural “Highlights” curve (like Core Image’s CIHighlightShadowAdjust) ---
    float highlightStrength = s * 0.8;  // overall strength
    float highlightMask = smoothstep(0.5, 1.0, lum); // starts in mid-brights
    highlightMask = pow(highlightMask, 1.6);          // softer roll-off

    // Lift only highlights while preserving midtone detail
    float3 lifted = mix(base, float3(1.0), highlightMask * highlightStrength);

    // Gentle contrast recovery so whites aren’t washed out
    float3 contrastPreserve = mix(lifted, lifted * lifted, 0.25 * s);

    // Clamp and blend by polygon mask
    float3 adjusted = clamp(contrastPreserve, 0.0, 1.0);
    float3 finalColor = mix(base, adjusted, mask);

    // Output
    return float4(finalColor, alpha);*/
    
    /*float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 base = baseColor.rgb;
    float alpha = baseColor.a;

    // --- Polygon mask ---
    float2 centroid = float2(0.0);
    for (uint i = 0; i < count; i++) centroid += points[i];
    centroid /= float(count);

    const float topScale = 0.2;
    const float bottomScale = 0.1;
    thread float2 extPoints[128];
    for (uint i = 0; i < count; i++)
        extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

    float dpoly = signedDistancePolygon(uv, extPoints, count);
    float mask = smoothstep(0.03, 0.0, dpoly);
    mask = clamp(mask, 0.0, 1.0);

    // --- Slider normalize (-100..100 → -1..1) ---
    float s = clamp(faceScaleFactor / 400.0, -1.0, 1.0); // higher scaling for visible effect

    // --- Luminance ---
    float lum = dot(base, float3(0.299, 0.587, 0.114));

    float3 adjusted = base;

    if (s > 0.0) {
        // Positive: lift highlights like CIHighlightShadowAdjust
        float highlightMask = smoothstep(0.5, 1.0, lum);
        highlightMask = pow(highlightMask, 1.5);           // smooth roll-off
        adjusted = base + highlightMask * s * 0.5;         // lift up to 50%
    } else if (s < 0.0) {
        // Negative: subtle midtone darken
        float darkMask = smoothstep(0.0, 0.7, lum);
        darkMask = pow(darkMask, 1.4);
        adjusted = base * (1.0 + s * 0.25 * darkMask);     // s < 0, multiplies <1 → darken
    }

    // Clamp
    adjusted = clamp(adjusted, 0.0, 1.0);

    // Blend via polygon mask
    float3 finalColor = mix(base, adjusted, mask);

    return float4(finalColor, alpha);*/
    
    /*float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 base = baseColor.rgb;
    float alpha = baseColor.a;

    // --- Polygon mask ---
    float2 centroid = float2(0.0);
    for (uint i = 0; i < count; i++) centroid += points[i];
    centroid /= float(count);

    const float topScale = 0.25;
    const float bottomScale = 0.2;
    thread float2 extPoints[128];
    for (uint i = 0; i < count; i++)
        extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

    float dpoly = signedDistancePolygon(uv, extPoints, count);
    float mask = smoothstep(0.04, 0.0, dpoly);
    mask = clamp(mask, 0.0, 1.0);

    // --- Normalize slider (-100..100 → -1..1) ---
    float s = clamp(faceScaleFactor / 250.0, -1.0, 1.0);

    // --- Compute luminance ---
    float lum = dot(base, float3(0.299, 0.587, 0.114));

    // --- Highlights adjustment ---
    float3 adjusted = base;

    if (s > 0.0) {
        // Apply lift across all pixels, stronger for brighter pixels
        float highlightMask = smoothstep(0.2, 1.0, lum);   // starts lifting from midtones
        highlightMask = pow(highlightMask, 1.2);           // smooth roll-off
        float liftAmount = s * 0.5;
        float3 lifted = base + liftAmount * highlightMask * (1.0 - base); // scale by distance to white
        // Gentle contrast recovery for natural look
        lifted = mix(lifted, pow(lifted, float3(1.2)), 0.15 * s);
        adjusted = lifted;
    } else if (s < 0.0) {
        // Optional: subtle midtone darken, very low effect
        float darkMask = smoothstep(0.0, 0.5, lum);
        darkMask = pow(darkMask, 1.4);
        adjusted = base * (1.0 + s * 0.25 * darkMask);*/
        
       /* float darkMask = smoothstep(0.0, 0.6, lum); // slightly higher range for smoother darkening
           darkMask = pow(darkMask, 1.3);
           float darkenAmount = -s * 0.2; // positive scalar
           float3 darkened = base * (1.0 - darkenAmount * darkMask); // safe, never goes negative
           adjusted = darkened;
    }

    // --- Clamp and blend ---
    adjusted = clamp(adjusted, 0.0, 1.0);
    float3 finalColor = mix(base, adjusted, mask);

    return float4(finalColor, alpha);*/
    
    
    /*float2 uv = vert.textureCoordinate;
       float4 baseColor = inputTexture.sample(textureSampler, uv);
       float3 base = baseColor.rgb;
       float alpha = baseColor.a;

       // --- Compute centroid ---
       float2 centroid = float2(0.0);
       for (uint i = 0; i < count; i++) centroid += points[i];
       centroid /= float(count);

       // --- Extended polygon region ---
       const float topScale    = 0.25;
       const float bottomScale = 0.2;
       float2 extPoints[64];
       for (uint i = 0; i < count; i++)
           extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

       // --- Polygon mask ---
       float dpoly = signedDistancePolygon(uv, extPoints, count);
       float mask = smoothstep(0.03, 0.0, dpoly);
       mask = clamp(mask, 0.0, 1.0);

       // --- Normalize control factor (-100..100 → -1..1) ---
       float s = clamp(faceScaleFactor / 400.0, -1.0, 1.0);

       // --- Compute luminance ---
       float lum = dot(base, float3(0.299, 0.587, 0.114));

       // --- Shadow adjustment ---
       float3 adjusted = base;

       if (s >= 0.0) {
           // Lift shadows (brightening)
           float liftAmount = s * 0.3;
           float shadowMask = 1.0 / (1.0 + exp((lum - 0.25) * 2.0));
           adjusted = base + liftAmount * shadowMask * (1.0 - base);
       } else {
           // Deepen shadows more realistically
           float darkenAmount = abs(s) * 0.35;
           float shadowMask   = pow(1.0 - lum, 1.6);
           float3 darkened    = base - darkenAmount * shadowMask * base;
           // Add slight contrast recovery to keep image rich
           darkened = mix(darkened, pow(darkened, float3(0.85)), 0.4 * abs(s));
           adjusted = darkened;
       }

       // --- Sharpening (local contrast boost) ---
       float2 texel = 1.0 / float2(inputTexture.get_width(), inputTexture.get_height());
       float3 north = inputTexture.sample(textureSampler, uv + float2(0.0, -texel.y)).rgb;
       float3 south = inputTexture.sample(textureSampler, uv + float2(0.0,  texel.y)).rgb;
       float3 east  = inputTexture.sample(textureSampler, uv + float2(texel.x, 0.0)).rgb;
       float3 west  = inputTexture.sample(textureSampler, uv + float2(-texel.x, 0.0)).rgb;
       float3 blur  = (north + south + east + west + base) / 5.0;
       float3 highpass = base - blur;
       float sharpStrength = 0.7 + abs(s) * 0.6; // stronger with darker slider
       float3 sharpened = adjusted + highpass * sharpStrength;
       sharpened = clamp(sharpened, 0.0, 1.0);

       // --- Blend using smooth mask ---
       float3 finalColor = mix(base, sharpened, mask);

       return float4(finalColor, alpha);*/
    
    /*float2 uv = vert.textureCoordinate;
        float4 baseColor = inputTexture.sample(textureSampler, uv);
        float3 base = baseColor.rgb;
        float alpha = baseColor.a;

        // --- Compute centroid ---
        float2 centroid = float2(0.0);
        for (uint i = 0; i < count; i++) centroid += points[i];
        centroid /= float(count);

        // --- Extended polygon region ---
        const float topScale    = 0.25;
        const float bottomScale = 0.2;
        float2 extPoints[64];
        for (uint i = 0; i < count; i++)
            extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

        // --- Polygon mask ---
        float dpoly = signedDistancePolygon(uv, extPoints, count);
        float mask = smoothstep(0.03, 0.0, dpoly);
        mask = clamp(mask, 0.0, 1.0);

        // --- Normalize control factor (-100..100 → -1..1) ---
        float s = clamp(faceScaleFactor / 350.0, -1.0, 1.0);

        // --- Compute luminance ---
        float lum = dot(base, float3(0.299, 0.587, 0.114));

        // --- Shadow adjustment ---
        float3 adjusted = base;

        if (s >= 0.0) {
            // Lift shadows (brightening, softer)
            float liftAmount = s * 0.3;
            float shadowMask = smoothstep(0.0, 0.5, 0.4 - lum);
            adjusted = base + liftAmount * shadowMask * (1.0 - base);
        } else {
            // More realistic deep shadows (filmic)
            float darkenAmount = abs(s) * 0.45; // increased depth
            float shadowMask   = pow(1.0 - lum, 2.0);
            float3 darkened    = mix(base, pow(base, float3(1.6)), darkenAmount * shadowMask);

            // Add mild contrast boost for realism
            float contrast = 1.0 + darkenAmount * 0.6;
            darkened = ((darkened - 0.5) * contrast + 0.5);

            // Slight saturation drop for cinematic tone
            float lumDark = dot(darkened, float3(0.299, 0.587, 0.114));
            darkened = mix(float3(lumDark), darkened, 0.9 - 0.2 * darkenAmount);

            adjusted = darkened;
        }

        // --- Sharpening (local contrast boost) ---
        float2 texel = 1.0 / float2(inputTexture.get_width(), inputTexture.get_height());
        float3 north = inputTexture.sample(textureSampler, uv + float2(0.0, -texel.y)).rgb;
        float3 south = inputTexture.sample(textureSampler, uv + float2(0.0,  texel.y)).rgb;
        float3 east  = inputTexture.sample(textureSampler, uv + float2(texel.x, 0.0)).rgb;
        float3 west  = inputTexture.sample(textureSampler, uv + float2(-texel.x, 0.0)).rgb;
        float3 blur  = (north + south + east + west + base) / 5.0;

        float3 highpass = base - blur;
        float sharpStrength = mix(0.7, 1.5, abs(s)); // stronger when darker
        float3 sharpened = adjusted + highpass * sharpStrength;
        sharpened = clamp(sharpened, 0.0, 1.0);

        // --- Blend inside region ---
        float3 finalColor = mix(base, sharpened, mask);

        return float4(finalColor, alpha);*/
    
    float2 uv = vert.textureCoordinate;
       float4 baseColor = inputTexture.sample(textureSampler, uv);
       float3 base = baseColor.rgb;
       float alpha = baseColor.a;

       // --- Compute centroid ---
       float2 centroid = float2(0.0);
       for (uint i = 0; i < count; i++) centroid += points[i];
       centroid /= float(count);

       const float topScale = 0.25;
       const float bottomScale = 0.2;

       // --- Polygon mask (array-free) ---
       float dpoly = signedDistancePolygonExtended(uv, points, count, centroid, topScale, bottomScale);
       float mask = smoothstep(0.03, 0.0, dpoly);
       mask = clamp(mask, 0.0, 1.0);

       // --- Normalize control factor (-100..100 → -1..1) ---
       float s = clamp(faceScaleFactor / 350.0, -1.0, 1.0);

       // --- Compute luminance ---
       float lum = dot(base, float3(0.299, 0.587, 0.114));
       float3 adjusted = base;

       // --- Shadow / highlight adjustment ---
       if (s >= 0.0) {
           float liftAmount = s * 0.3;
           float shadowMask = smoothstep(0.0, 0.5, 0.4 - lum);
           adjusted = base + liftAmount * shadowMask * (1.0 - base);
       } else {
           float darkenAmount = abs(s) * 0.45;
           float shadowMask = pow(1.0 - lum, 2.0);
           float3 darkened = mix(base, pow(base, float3(1.6)), darkenAmount * shadowMask);
           float contrast = 1.0 + darkenAmount * 0.6;
           darkened = ((darkened - 0.5) * contrast + 0.5);
           float lumDark = dot(darkened, float3(0.299, 0.587, 0.114));
           darkened = mix(float3(lumDark), darkened, 0.9 - 0.2 * darkenAmount);
           adjusted = darkened;
       }

       // --- Sharpening (local contrast) ---
       float2 texel = 1.0 / float2(inputTexture.get_width(), inputTexture.get_height());
       float3 north = inputTexture.sample(textureSampler, uv + float2(0.0, -texel.y)).rgb;
       float3 south = inputTexture.sample(textureSampler, uv + float2(0.0,  texel.y)).rgb;
       float3 east  = inputTexture.sample(textureSampler, uv + float2(texel.x, 0.0)).rgb;
       float3 west  = inputTexture.sample(textureSampler, uv + float2(-texel.x, 0.0)).rgb;
       float3 blur  = (north + south + east + west + base) / 5.0;

       float3 highpass = base - blur;
       float sharpStrength = mix(0.7, 1.5, abs(s));
       float3 sharpened = adjusted + highpass * sharpStrength;
       sharpened = clamp(sharpened, 0.0, 1.0);

       // --- Blend inside polygon mask ---
       float3 finalColor = mix(base, sharpened, mask);

       return float4(finalColor, alpha);

}


/*float2 uv = vert.textureCoordinate;
float4 baseColor = inputTexture.sample(textureSampler, uv);
float3 base = baseColor.rgb;
float alpha = baseColor.a;

// --- Compute centroid ---
float2 centroid = float2(0.0);
for (uint i = 0; i < count; i++) centroid += points[i];
centroid /= float(count);

// --- Extended polygon region ---
const float topScale = 0.2;
const float bottomScale = 0.1;
thread float2 extPoints[128];
for (uint i = 0; i < count; i++)
    extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

// --- Polygon mask (soft edges) ---
float dpoly = signedDistancePolygon(uv, extPoints, count);
float mask = smoothstep(0.03, 0.0, dpoly);
mask = clamp(mask, 0.0, 1.0);

// --- Normalize slider (-100..100 → -1..1) ---
float s = clamp(faceScaleFactor / 100.0, -1.0, 1.0); // negative for shadows, positive for highlights

// --- Compute luminance ---
float lum = dot(base, float3(0.299, 0.587, 0.114));

// --- Highlights / Shadows adjustment ---
float3 adjusted = base;

if (s > 0.0) {
    // Lift highlights
    float highlightMask = smoothstep(0.5, 1.0, lum);   // mid-brights to whites
    highlightMask = pow(highlightMask, 1.6);           // smooth roll-off
    adjusted = mix(base, float3(1.0), highlightMask * s * 0.8);
    // gentle contrast recovery
    adjusted = mix(adjusted, adjusted * adjusted, 0.25 * s);
} else if (s < 0.0) {
    // Deepen shadows
    float shadowMask = smoothstep(0.0, 0.5, lum);      // dark areas only
    shadowMask = pow(shadowMask, 0.6);                 // smooth curve
    float darkenAmount = abs(s) * 0.6;
    adjusted = base * (1.0 - darkenAmount * (1.0 - shadowMask));
}

// Clamp to prevent overshoot
adjusted = clamp(adjusted, 0.0, 1.0);

// --- Blend using polygon mask ---
float3 finalColor = mix(base, adjusted, mask);

// Output
return float4(finalColor, alpha);*/
