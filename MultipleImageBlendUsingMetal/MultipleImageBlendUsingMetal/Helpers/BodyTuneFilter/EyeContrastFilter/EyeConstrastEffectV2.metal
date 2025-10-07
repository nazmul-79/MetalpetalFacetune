//
//  EyeConstrastEffectV2.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 23/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

// Signed distance to polygon
inline float signedDistancePolygon(float2 p, device const float2* points, uint count) {
    float minDist = 1e5;
    for (uint i = 0; i < count; ++i) {
        float2 a = points[i];
        float2 b = points[(i+1) % count];
        float2 ab = b - a;
        float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
        float2 proj = a + t*ab;
        minDist = min(minDist, distance(p, proj));
    }
    return minDist;
}

// Point in polygon (ray-casting)
inline bool pointInPolygon(float2 p, device const float2* points, uint count) {
    bool inside = false;
    for (uint i = 0, j = count-1; i < count; j=i, i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        if (((pi.y > p.y) != (pj.y > p.y)) &&
            (p.x < (pj.x - pi.x)*(p.y - pi.y)/(pj.y - pi.y) + pi.x)) {
            inside = !inside;
        }
    }
    return inside;
}

float3 rgb2lab(float3 rgb);
float3 lab2rgb(float3 lab);

inline float distanceToPolygonEdge(float2 p, device const float2* points, uint count) {
    float minDist = 1e5;
    for (uint i = 0; i < count; ++i) {
        float2 a = points[i];
        float2 b = points[(i+1) % count];
        float2 ab = b - a;
        float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
        float2 proj = a + t * ab;
        float d = distance(p, proj);
        minDist = min(minDist, d);
    }
    return minDist;
}

fragment float4 eyeContrastShader(VertexOut in [[stage_in]],
                                  texture2d<float> tex [[texture(0)]],
                                  device const float2* leftContourPoints [[buffer(0)]],
                                  constant uint &leftContourCount [[buffer(1)]],
                                  device const float2* rightContourPoints [[buffer(2)]],
                                  constant uint &rightContourCount [[buffer(3)]],
                                  device const float2* leftIrisPoints [[buffer(4)]],
                                  constant uint &leftIrisCount [[buffer(5)]],
                                  device const float2* rightIrisPoints [[buffer(6)]],
                                  constant uint &rightIrisCount [[buffer(7)]],
                                  constant float &scaleFactor [[buffer(8)]]) {

    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;

    // Compute distances to contours
    float dLeft = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
    float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);

    // Thin line mask around contour
    float lineWidth = 0.002; // adjust thickness
    float leftLine = 1.0 - smoothstep(-lineWidth, lineWidth, dLeft);
    float rightLine = 1.0 - smoothstep(-lineWidth, lineWidth, dRight);

    // Combine both eyes
    float lineMask = max(leftLine, rightLine);

    // Set line color (e.g., red)
    float3 lineColor = float3(1.0, 0.0, 0.0);

    // Blend the line with the original
    float3 result = mix(base, lineColor, lineMask);

    return float4(result, color.a);*/
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;

    // --- Distance fields for eyes ---
    float dLeft  = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
    float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);

    // --- Iris exclusion ---
    bool inLeftIris = pointInPolygon(uv, leftIrisPoints, leftIrisCount);
    bool inRightIris = pointInPolygon(uv, rightIrisPoints, rightIrisCount);
    bool inIris = inLeftIris || inRightIris;

    // --- Eye area mask (inside contour, feathered) ---
    float feather = 0.018; // softness
    float leftMask  = 1.0 - smoothstep(-feather, feather, dLeft);
    float rightMask = 1.0 - smoothstep(-feather, feather, dRight);
    float eyeMask = max(leftMask, rightMask) * float(!inIris); // exclude iris

    // --- Factor ---
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);

    // --- Brightness boost ---
    float brightnessStrength = 0.15 * factor;
    float3 brightened = base + brightnessStrength;

    // --- Contrast boost ---
    float contrastStrength = 0.6 * factor;
    float3 contrasted = (brightened - 0.5) * (1.0 + contrastStrength) + 0.5;

    // --- Saturation boost ---
    float saturationStrength = 0.2 * factor; // 0 = no change, >0 = more saturation
    float luminance = dot(contrasted, float3(0.299, 0.587, 0.114));
    float3 saturated = mix(float3(luminance), contrasted, 1.0 + saturationStrength);

    // --- Clamp final color ---
    saturated = clamp(saturated, 0.0, 1.0);

    // --- Blend only inside eye area ---
    float3 result = mix(base, saturated, eyeMask);

    return float4(result, color.a);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;

    // --- Distance fields for eyes ---
    float dLeft  = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
    float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);

    // --- Iris exclusion ---
    bool inLeftIris = pointInPolygon(uv, leftIrisPoints, leftIrisCount);
    bool inRightIris = pointInPolygon(uv, rightIrisPoints, rightIrisCount);
    bool inIris = inLeftIris || inRightIris;

    // --- Eye area mask (inside contour, feathered) ---
    float feather = 0.018; // softness
    float leftMask  = 1.0 - smoothstep(-feather, feather, dLeft);
    float rightMask = 1.0 - smoothstep(-feather, feather, dRight);
    float eyeMask = max(leftMask, rightMask) * float(!inIris); // exclude iris

    // --- Gradient to reduce lower-inner light ---
    float innerFalloff = smoothstep(0.0, 0.5, uv.x); // reduces effect near left side of eye
    float lowerFalloff = smoothstep(0.0, 0.5, uv.y); // reduces effect near bottom of eye
    eyeMask *= innerFalloff * lowerFalloff;

    // --- Factor ---
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);

    // --- Brightness boost ---
    float brightnessStrength = 0.15 * factor;
    float3 brightened = base + brightnessStrength;

    // --- Contrast boost ---
    float contrastStrength = 0.6 * factor;
    float3 contrasted = (brightened - 0.5) * (1.0 + contrastStrength) + 0.5;

    // --- Saturation boost ---
    float saturationStrength = 0.2 * factor;
    float luminance = dot(contrasted, float3(0.299, 0.587, 0.114));
    float3 saturated = mix(float3(luminance), contrasted, 1.0 + saturationStrength);

    // --- Clamp final color ---
    saturated = clamp(saturated, 0.0, 1.0);

    // --- Blend only inside eye area with gradient -->
    float3 result = mix(base, saturated, eyeMask);

    return float4(result, color.a);*/

    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;

    // --- Distance fields for eyes ---
    float dLeft  = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
    float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);

    // --- Iris exclusion ---
    bool inLeftIris = pointInPolygon(uv, leftIrisPoints, leftIrisCount);
    bool inRightIris = pointInPolygon(uv, rightIrisPoints, rightIrisCount);
    bool inIris = inLeftIris || inRightIris;

    // --- Eye mask with feather ---
    float feather = 0.012;
    float leftMask  = 1.0 - smoothstep(-feather, feather, dLeft);
    float rightMask = 1.0 - smoothstep(-feather, feather, dRight);
    float eyeMaskRaw = max(leftMask, rightMask) * float(!inIris);

    // --- Eye centroid ---
    float2 eyeCentroid = float2(0.0);
    for (uint i = 0; i < leftContourCount; i++) eyeCentroid += leftContourPoints[i];
    for (uint i = 0; i < rightContourCount; i++) eyeCentroid += rightContourPoints[i];
    eyeCentroid /= float(leftContourCount + rightContourCount);

    // --- Distance to centroid for radial falloff ---
    float distanceToCenter = distance(uv, eyeCentroid);
    float radial = 1.0 - smoothstep(0.0, 0.25, distanceToCenter);

    // --- Combined eye mask ---
    float eyeMask = pow(eyeMaskRaw, 1.5) * radial; // soften exponent
    eyeMask = clamp(eyeMask, 0.0, 1.0);

    // --- Scale factor normalization (-100..100 → -1..1) ---
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
    if (factor == 0.0) return color;

    // --- Adjust brightness/contrast per pixel ---
    float3 adjusted = base;

    if (factor > 0.0) {
        // Brighten & slight contrast
        float brightnessBoost = 0.5 * factor; // increased from 0.08
        adjusted = base + brightnessBoost * eyeMask;
    } else if (factor < 0.0) {
        // Darken
        float darkenAmount = 0.4 * (-factor); // increased from 0.1
        adjusted = base - darkenAmount * eyeMask;
    }

    // Clamp final color
    adjusted = clamp(adjusted, 0.0, 1.0);

    return float4(adjusted, color.a);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;

    // --- Distance fields for eyes ---
    float dLeft  = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
    float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);

    // --- Iris exclusion ---
    bool inLeftIris = pointInPolygon(uv, leftIrisPoints, leftIrisCount);
    bool inRightIris = pointInPolygon(uv, rightIrisPoints, rightIrisCount);
    bool inIris = inLeftIris || inRightIris;

    // --- Eye mask with soft feather ---
    float feather = 0.025;
    float leftMask  = 1.0 - smoothstep(-feather, feather, dLeft);
    float rightMask = 1.0 - smoothstep(-feather, feather, dRight);
    float eyeMaskRaw = max(leftMask, rightMask) * float(!inIris);

    // --- Eye centroid ---
    float2 eyeCentroid = float2(0.0);
    for (uint i = 0; i < leftContourCount; i++) eyeCentroid += leftContourPoints[i];
    for (uint i = 0; i < rightContourCount; i++) eyeCentroid += rightContourPoints[i];
    eyeCentroid /= float(leftContourCount + rightContourCount);

    // --- Radial falloff ---
    float distanceToCenter = distance(uv, eyeCentroid);
    float radial = 1.0 - smoothstep(0.0, 0.35, distanceToCenter);

    // --- Combined eye mask (spatial) ---
    float eyeMask = pow(eyeMaskRaw, 1.2) * pow(radial, 1.3);
    eyeMask = clamp(eyeMask, 0.0, 1.0);
    if (eyeMask < 0.01) return color; // skip pixels outside mask

    // --- Normalize scale factor (make effect stronger) ---
    float factor = clamp(scaleFactor / 50.0, -1.0, 1.0); // divide by 50 instead of 100

    // --- Pixel luminance aware variation ---
    float luminance = dot(base, float3(0.299, 0.587, 0.114));
    float variation = pow(luminance, 0.6); // subtle dark pixel damping

    // --- Adjust per pixel ---
    float3 adjusted = base;
    if (factor > 0.0) {
        float brightness = 0.8 * factor * variation;
        float3 contrastColor = (base - 0.5) * (1.0 + 0.3 * factor * variation) + 0.5;
        adjusted = base + brightness;
        adjusted = mix(adjusted, contrastColor, 0.6); // subtle contrast
    } else if (factor < 0.0) {
        float darken = 0.7 * (-factor) * variation;
        float3 contrastColor = (base - 0.5) * (1.0 - 0.25 * (-factor) * variation) + 0.5;
        adjusted = base - darken;
        adjusted = mix(adjusted, contrastColor, 0.6);
    }

    // --- Final blend using eyeMask for smooth edge ---
    float3 finalColor = mix(base, adjusted, eyeMask);

    return float4(finalColor, color.a);*/
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;

    // --- Distance fields for eyes ---
    float dLeft  = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
    float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);

    // --- Eye mask with soft feather ---
    float feather = 0.025;
    float leftMask  = 1.0 - smoothstep(-feather, feather, dLeft);
    float rightMask = 1.0 - smoothstep(-feather, feather, dRight);
    float eyeMaskRaw = max(leftMask, rightMask);

    // --- Eye centroid ---
    float2 eyeCentroid = float2(0.0);
    for (uint i = 0; i < leftContourCount; i++) eyeCentroid += leftContourPoints[i];
    for (uint i = 0; i < rightContourCount; i++) eyeCentroid += rightContourPoints[i];
    eyeCentroid /= float(leftContourCount + rightContourCount);

    // --- Radial falloff ---
    float distanceToCenter = distance(uv, eyeCentroid);
    float radial = 1.0 - smoothstep(0.0, 0.35, distanceToCenter);

    // --- Combined eye mask (softer) ---
    float eyeMask = eyeMaskRaw * radial;
    eyeMask = clamp(eyeMask, 0.0, 1.0);

    // --- Normalize scale factor ---
    float factor = clamp(scaleFactor / 50.0, -1.0, 1.0);

    // Skip if no effect needed
    if (abs(factor) < 0.01) return color;

    // --- Adjust per pixel ---
    float3 adjusted = base;

    if (factor > 0.0) {
        // SUBTLE brightness + contrast enhancement
        float brightness = 0.3 * factor; // Reduced from 0.8
        float contrast = 1.0 + 0.2 * factor; // Reduced from 0.4
        
        // Apply contrast first
        adjusted = (base - 0.5) * contrast + 0.5;
        // Then add subtle brightness
        adjusted += brightness;
        
        // Clamp to avoid overexposure
        adjusted = clamp(adjusted, 0.0, 1.0);
        
    } else if (factor < 0.0) {
        // SUBTLE darken + contrast reduction
        float darken = 0.3 * (-factor); // Reduced from 0.7
        float contrast = 1.0 - 0.15 * (-factor); // Reduced from 0.3
        
        // Apply contrast first
        adjusted = (base - 0.5) * contrast + 0.5;
        // Then subtract darken
        adjusted -= darken;
        
        // Clamp to avoid complete black
        adjusted = clamp(adjusted, 0.0, 1.0);
    }

    // --- Final blend with smooth mask ---
    float3 finalColor = mix(base, adjusted, eyeMask);

    return float4(finalColor, color.a);

}

/*
 
 constexpr sampler s(address::clamp_to_edge, filter::linear);
 float2 uv = in.textureCoordinate;
 float4 color = tex.sample(s, uv);
 float3 base = color.rgb;

 // --- Feather and padding ---
 float feather = 0.01;
 float padding = 0.002; // inward shift

 // --- Left eye mask ---
 float dLeft = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
 float leftMask = 1.0 - smoothstep(padding, feather + padding, dLeft);

 // --- Right eye mask ---
 float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);
 float rightMask = 1.0 - smoothstep(padding, feather + padding, dRight);

 // --- Iris exclusion ---
 bool inLeftIris = pointInPolygon(uv, leftIrisPoints, leftIrisCount);
 bool inRightIris = pointInPolygon(uv, rightIrisPoints, rightIrisCount);

 // Apply mask only inside eye contour and outside iris
 float applyLeft = leftMask * float(!inLeftIris);
 float applyRight = rightMask * float(!inRightIris);

 // --- Apply subtle RGB boost ---
 float3 result = base;
 if (scaleFactor > 0.001) {
     float factor = 0.01 * scaleFactor;

     // Use linear blend to avoid edges being too bright
     float3 boostedLeft = base + (base * factor - base) * applyLeft;
     float3 boostedRight = boostedLeft + (boostedLeft * factor - boostedLeft) * applyRight;

     result = clamp(boostedRight, 0.0, 1.0);
 }

 return float4(result, color.a);
 
 constexpr sampler s(address::clamp_to_edge, filter::linear);
 float2 uv = in.textureCoordinate;
 float4 color = tex.sample(s, uv);
 float3 base = color.rgb;

 // --- Line width ---
 float lineWidth = 0.002; // adjust thickness

 // --- Distance to left iris polygon edges ---
 float leftDist = distanceToPolygonEdge(uv, leftIrisPoints, leftIrisCount);
 float leftLine = smoothstep(lineWidth, 0.0, leftDist); // smooth line

 // --- Distance to right iris polygon edges ---
 float rightDist = distanceToPolygonEdge(uv, rightIrisPoints, rightIrisCount);
 float rightLine = smoothstep(lineWidth, 0.0, rightDist);

 // --- Combine left and right masks ---
 float lineMask = max(leftLine, rightLine);

 // --- Red line color ---
 float3 lineColor = float3(1.0, 0.0, 0.0);

 // --- Blend with original color ---
 float3 result = mix(base, lineColor, lineMask);

 return float4(result, color.a);
 
 
 */
