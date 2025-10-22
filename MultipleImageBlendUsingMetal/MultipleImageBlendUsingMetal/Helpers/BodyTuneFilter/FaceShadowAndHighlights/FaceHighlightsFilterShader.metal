//
//  FaceHighlightsFilterShader.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 15/10/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

// --- Extend point for fixed top/bottom ---

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

// --- Segment distance ---
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

        // Distance
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



fragment float4 FaceHighlightsMetalShader(VertexOut vert [[stage_in]],
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
    float2 extPoints[64];
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
        adjusted = base * (1.0 + s * 0.25 * darkMask);
        
        float darkMask = smoothstep(0.0, 0.6, lum); // slightly higher range for smoother darkening
           darkMask = pow(darkMask, 1.3);
           float darkenAmount = -s * 0.15; // positive scalar
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

    // --- Polygon mask ---
    float2 centroid = float2(0.0);
    for (uint i = 0; i < count; i++) centroid += points[i];
    centroid /= float(count);

    const float topScale = 0.25;
    const float bottomScale = 0.2;
    float2 extPoints[32];
    for (uint i = 0; i < count; i++)
        extPoints[i] = extendPoint(points[i], centroid, topScale, bottomScale);

    float dpoly = signedDistancePolygon(uv, extPoints, count);
    float mask = smoothstep(0.04, 0.0, dpoly);
    mask = clamp(mask, 0.0, 1.0);

    // --- Normalize slider (-100..100 → -1..1) ---
    float s = clamp(faceScaleFactor / 200.0, -1.0, 1.0);

    // --- Compute luminance ---
    float lum = dot(base, float3(0.299, 0.587, 0.114));

    // --- Highlights adjustment ---
    float3 adjusted = base;

    if (s > 0.0) {
        // Brighten highlights (same as before)
        float highlightMask = smoothstep(0.2, 1.0, lum);
        highlightMask = pow(highlightMask, 1.2);
        float liftAmount = s * 0.5;
        float3 lifted = base + liftAmount * highlightMask * (1.0 - base);
        lifted = mix(lifted, pow(lifted, float3(1.2)), 0.15 * s);
        adjusted = lifted;
    } else if (s < 0.0) {
        // --- Realistic darkening with preserved highlights ---
        float darkenAmount = -s * 0.45; // stronger but balanced
        float shadowMask = pow(1.0 - lum, 1.8);  // strong in darks, low in brights
        float highlightPreserve = smoothstep(0.6, 1.0, lum); // keeps highlight safe

        // Core darkening curve
        float3 darkened = mix(base, pow(base, float3(1.5)), darkenAmount * shadowMask);

        // Blend in highlight recovery — keep skin reflections alive
        darkened = mix(darkened, base, highlightPreserve * 0.6);

        // Subtle local contrast recovery (prevents flat look)
        float contrast = 1.0 + darkenAmount * 0.4;
        darkened = ((darkened - 0.5) * contrast + 0.5);

        adjusted = darkened;
    }

    // --- Clamp and blend ---
    adjusted = clamp(adjusted, 0.0, 1.0);
    float3 finalColor = mix(base, adjusted, mask);

    return float4(finalColor, alpha);*/
    
    float2 uv = vert.textureCoordinate;
        float4 baseColor = inputTexture.sample(textureSampler, uv);
        float3 base = baseColor.rgb;
        float alpha = baseColor.a;

        // --- Polygon mask ---
        float2 centroid = float2(0.0);
        for (uint i = 0; i < count; i++)
            centroid += points[i];
        centroid /= float(count);

        const float topScale = 0.25;
        const float bottomScale = 0.2;

        float dpoly = signedDistancePolygonExtended(uv, points, count, centroid, topScale, bottomScale);
        float mask = smoothstep(0.04, 0.0, dpoly);
        mask = clamp(mask, 0.0, 1.0);

        // --- Normalize slider (-100..100 → -1..1) ---
        float s = clamp(faceScaleFactor / 200.0, -1.0, 1.0);

        // --- Compute luminance ---
        float lum = dot(base, float3(0.299, 0.587, 0.114));
        float3 adjusted = base;

        // --- Highlights / shadows adjustment ---
        if (s > 0.0) {
            float highlightMask = smoothstep(0.3, 1.0, lum);
            highlightMask = pow(highlightMask, 1.2);
            float liftAmount = s * 0.45;
            float3 lifted = base + liftAmount * highlightMask * (1.0 - base);
            lifted = mix(lifted, pow(lifted, float3(1.3)), 0.2 * s);
            adjusted = lifted;
        } else if (s < 0.0) {
            float darkenAmount = -s * 0.45;
            float shadowMask = pow(1.0 - lum, 1.8);
            float highlightPreserve = smoothstep(0.6, 1.0, lum);
            float3 darkened = mix(base, pow(base, float3(1.5)), darkenAmount * shadowMask);
            darkened = mix(darkened, base, highlightPreserve * 0.6);
            float contrast = 1.0 + darkenAmount * 0.4;
            darkened = ((darkened - 0.5) * contrast + 0.5);
            adjusted = darkened;
        }
    
        adjusted = clamp(adjusted, 0.0, 1.0);
        float3 finalColor = mix(base, adjusted, mask);

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
