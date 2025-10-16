//
//  EyeConstrastEffectV2.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 23/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;


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

inline float signedDistancePolygon(float2 p, device const float2* points, uint count) {
    float minDist = 1e5;
    bool inside = false;
    for (uint i = 0; i < count; ++i) {
        float2 a = points[i];
        float2 b = points[(i+1) % count];
        float2 ab = b - a;

        // distance to edge
        float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
        float2 proj = a + t * ab;
        float d = distance(p, proj);
        minDist = min(minDist, d);

        // ray crossing test for inside/outside
        if (((a.y > p.y) != (b.y > p.y)) &&
            (p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x)) {
            inside = !inside;
        }
    }
    return inside ? -minDist : minDist;
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
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
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
     
     return float4(finalColor, color.a);*/
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
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
     
     // --- Combined eye mask ---
     float eyeMask = clamp(eyeMaskRaw * radial, 0.0, 1.0);
     
     // --- Normalize intensity ---
     float factor = clamp(scaleFactor / 50.0, -1.0, 1.0);
     if (abs(factor) < 0.01) return color;
     
     // --- Local contrast detection (sharpness proxy) ---
     float2 texel = 1.0 / float2(tex.get_width(), tex.get_height());
     float3 c = base;
     float3 blur =
     (tex.sample(s, uv + float2(texel.x, 0)).rgb +
     tex.sample(s, uv - float2(texel.x, 0)).rgb +
     tex.sample(s, uv + float2(0, texel.y)).rgb +
     tex.sample(s, uv - float2(0, texel.y)).rgb) * 0.25;
     
     // Difference = sharpness amount
     float3 highpass = c - blur;
     float sharpness = dot(abs(highpass), float3(0.333));
     
     // --- Adaptive sharpening ---
     float clarity = 1.0 + 2.0 * factor;          // sharpen strength
     float softener = smoothstep(0.05, 0.3, sharpness);  // less sharpening on already sharp pixels
     float3 enhanced = c + highpass * clarity * (1.0 - softener);
     
     // --- Tone normalization ---
     enhanced = clamp(enhanced, 0.0, 1.0);
     
     // --- Blend only in the eye area ---
     float3 finalColor = mix(base, enhanced, eyeMask);
     
     return float4(finalColor, color.a);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
     
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
     
     // --- Combined eye mask ---
     float eyeMask = clamp(eyeMaskRaw * radial, 0.0, 1.0);
     
     // --- Normalize 0–100 range ---
     float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
     if (factor < 0.01) return color;
     
     // --- Improved sharpening with multiple samples ---
     float2 texel = 1.0 / float2(tex.get_width(), tex.get_height());
     float3 c = base;
     
     // 3x3 Gaussian blur for better sharpening
     float3 blur = float3(0.0);
     constexpr float kernelWeights[9] = {1.0, 2.0, 1.0, 2.0, 4.0, 2.0, 1.0, 2.0, 1.0};
     constexpr float kernelSum = 16.0;
     
     int sampleIndex = 0;
     for (int y = -1; y <= 1; y++) {
     for (int x = -1; x <= 1; x++) {
     float2 offset = float2(x, y) * texel;
     blur += tex.sample(s, uv + offset).rgb * kernelWeights[sampleIndex];
     sampleIndex++;
     }
     }
     blur /= kernelSum;
     
     // --- Enhanced highpass for sharpening ---
     float3 highpass = c - blur;
     float sharpness = length(highpass);
     
     // --- Adaptive sharpening with stronger effect ---
     float clarityStrength = mix(1.5, 4.5, factor);
     float edgeThreshold = 0.02;
     float softener = smoothstep(edgeThreshold, 0.15, sharpness);
     float3 enhanced = c + highpass * clarityStrength * (1.0 - softener);
     
     // --- Add contrast enhancement ---
     float contrast = 1.0 + (0.3 * factor);
     enhanced = (enhanced - 0.5) * contrast + 0.5;
     
     // --- Protect from clipping ---
     enhanced = clamp(enhanced, 0.01, 0.99);
     
     // --- Blend only in the eye area ---
     float3 finalColor = mix(base, enhanced, eyeMask);
     
     return float4(finalColor, color.a);*/
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
     float2 uv = in.textureCoordinate;
     float4 color = tex.sample(s, uv);
     float3 base = color.rgb;
     
     // --- Distance fields for eyes ---
     float dLeft  = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
     float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);
     
     // --- Eye mask with slightly smoother edge ---
     float feather = 0.035; // only slightly more than before
     float leftMask  = 1.0 - smoothstep(-feather, feather, dLeft);
     float rightMask = 1.0 - smoothstep(-feather, feather, dRight);
     float eyeMaskRaw = max(leftMask, rightMask);
     
     // --- Eye centroid ---
     float2 eyeCentroid = float2(0.0);
     for (uint i = 0; i < leftContourCount; i++) eyeCentroid += leftContourPoints[i];
     for (uint i = 0; i < rightContourCount; i++) eyeCentroid += rightContourPoints[i];
     eyeCentroid /= float(leftContourCount + rightContourCount);
     
     // --- Radial falloff (softened a bit) ---
     float distanceToCenter = distance(uv, eyeCentroid);
     float radial = 1.0 - smoothstep(0.0, 0.40, distanceToCenter);
     
     // --- Combined eye mask ---
     float eyeMask = clamp(eyeMaskRaw * radial, 0.0, 1.0);
     eyeMask = smoothstep(0.0, 1.0, eyeMask); // smoother transition
     eyeMask = pow(eyeMask, 1.2); // mild curve for soft blend
     
     // --- Normalize 0–100 range ---
     float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
     if (factor < 0.01) return color;
     
     // --- Improved sharpening with multiple samples (same as before) ---
     float2 texel = 1.0 / float2(tex.get_width(), tex.get_height());
     float3 c = base;
     
     // 3x3 Gaussian blur for better sharpening
     float3 blur = float3(0.0);
     constexpr float kernelWeights[9] = {1.0, 2.0, 1.0, 2.0, 4.0, 2.0, 1.0, 2.0, 1.0};
     constexpr float kernelSum = 16.0;
     
     int sampleIndex = 0;
     for (int y = -1; y <= 1; y++) {
     for (int x = -1; x <= 1; x++) {
     float2 offset = float2(x, y) * texel;
     blur += tex.sample(s, uv + offset).rgb * kernelWeights[sampleIndex];
     sampleIndex++;
     }
     }
     blur /= kernelSum;
     
     // --- Enhanced highpass for sharpening (same clarity as before) ---
     float3 highpass = c - blur;
     float sharpness = length(highpass);
     
     float clarityStrength = mix(1.5, 4.5, factor);
     float edgeThreshold = 0.02;
     float softener = smoothstep(edgeThreshold, 0.15, sharpness);
     float3 enhanced = c + highpass * clarityStrength * (1.0 - softener);
     
     // --- Add contrast enhancement ---
     float contrast = 1.0 + (0.3 * factor);
     enhanced = (enhanced - 0.5) * contrast + 0.5;
     
     // --- Protect from clipping ---
     enhanced = clamp(enhanced, 0.01, 0.99);
     
     // --- Blend smoothly in the eye area (no edge artifacts) ---
     float3 finalColor = mix(base, enhanced, eyeMask);
     
     return float4(finalColor, color.a);*/
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
     float2 uv = in.textureCoordinate;
     float4 color = tex.sample(s, uv);
     float3 base = color.rgb;
     
     // --- Distance fields for eyes ---
     float dLeft  = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
     float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);
     
     // --- Smooth eye mask with feather ---
     float feather = 0.008; // increase feather for smooth edges
     float leftMask  = 1.0 - smoothstep(-feather, feather, dLeft);
     float rightMask = 1.0 - smoothstep(-feather, feather, dRight);
     float eyeMaskRaw = max(leftMask, rightMask);
     
     // --- Eye centroid ---
     float2 eyeCentroid = float2(0.0);
     for (uint i = 0; i < leftContourCount; i++) eyeCentroid += leftContourPoints[i];
     for (uint i = 0; i < rightContourCount; i++) eyeCentroid += rightContourPoints[i];
     eyeCentroid /= float(leftContourCount + rightContourCount);
     
     // --- Radial falloff for inner softness ---
     float distanceToCenter = distance(uv, eyeCentroid);
     float radial = 1.0 - smoothstep(0.0, 0.40, distanceToCenter);
     
     // --- Combined mask ---
     float eyeMask = clamp(eyeMaskRaw * radial, 0.0, 1.0);
     eyeMask = pow(eyeMask, 0.9); // slightly stronger mask
     
     // --- Early exit if factor too low ---
     float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
     if (factor < 0.01) return color;
     
     // --- Gaussian blur 3x3 ---
     float2 texel = 1.0 / float2(tex.get_width(), tex.get_height());
     float3 blur = float3(0.0);
     constexpr float kernelWeights[9] = {1,2,1,2,4,2,1,2,1};
     int sampleIndex = 0;
     for (int y = -1; y <= 1; y++) {
     for (int x = -1; x <= 1; x++) {
     float2 offset = float2(x, y) * texel;
     blur += tex.sample(s, uv + offset).rgb * kernelWeights[sampleIndex];
     sampleIndex++;
     }
     }
     blur /= 16.0;
     
     // --- High-pass filter ---
     float3 highpass = base - blur;
     float sharpness = length(highpass);
     
     // --- Adaptive clarity ---
     float clarityStrength = mix(1.0, 2.5, factor);
     float softener = smoothstep(0.04, 0.15, sharpness);
     float localVariance = dot(highpass, highpass);
     float adaptiveStrength = mix(clarityStrength, clarityStrength * 1.8, smoothstep(0.0, 0.01, localVariance));
     
     float3 enhanced = base + highpass * adaptiveStrength * (1.0 - softener);
     
     // --- Optional: second high-pass ---
     float3 highpass2 = base - blur;
     enhanced += highpass2 * (clarityStrength * 0.5) * (1.0 - softener);
     
     // --- Clamp to avoid clipping ---
     enhanced = clamp(enhanced, 0.0, 1.0);
     
     // --- Blend with original in eye area with smooth mask ---
     float3 finalColor = mix(base, enhanced, eyeMask);
     
     return float4(finalColor, color.a);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
     float2 uv = in.textureCoordinate;
     float4 color = tex.sample(s, uv);
     float3 base = color.rgb;
     
     // --- Distance fields for eyes ---
     float dLeft  = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
     float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);
     
     // --- Smooth eye mask with feather ---
     float feather = 0.008;
     float leftMask  = 1.0 - smoothstep(-feather, feather, dLeft);
     float rightMask = 1.0 - smoothstep(-feather, feather, dRight);
     float eyeMaskRaw = max(leftMask, rightMask);
     
     // --- Eye centroid ---
     float2 eyeCentroid = float2(0.0);
     for (uint i = 0; i < leftContourCount; i++) eyeCentroid += leftContourPoints[i];
     for (uint i = 0; i < rightContourCount; i++) eyeCentroid += rightContourPoints[i];
     eyeCentroid /= float(leftContourCount + rightContourCount);
     
     // --- Radial falloff for inner softness ---
     float distanceToCenter = distance(uv, eyeCentroid);
     float radial = 1.0 - smoothstep(0.0, 0.40, distanceToCenter);
     
     // --- Combined mask ---
     float eyeMask = clamp(eyeMaskRaw * radial, 0.0, 1.0);
     eyeMask = pow(eyeMask, 0.9);
     
     // --- Early exit if factor too low ---
     float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
     if (factor < 0.01) return color;
     
     // --- Adaptive kernel size based on image resolution ---
     float2 texel = 1.0 / float2(tex.get_width(), tex.get_height());
     float imageSize = min(tex.get_width(), tex.get_height());
     
     // Small image e kernel size adjust koro
     float kernelScale = 1.0;
     if (imageSize < 500.0) {
     kernelScale = 0.5; // Small image e half kernel
     } else if (imageSize < 800.0) {
     kernelScale = 0.7; // Medium image e reduced kernel
     }
     
     float3 blur = float3(0.0);
     constexpr float kernelWeights[9] = {1,2,1,2,4,2,1,2,1};
     int sampleIndex = 0;
     
     for (int y = -1; y <= 1; y++) {
     for (int x = -1; x <= 1; x++) {
     float2 offset = float2(x, y) * texel * kernelScale; // Scale the offset
     blur += tex.sample(s, uv + offset).rgb * kernelWeights[sampleIndex];
     sampleIndex++;
     }
     }
     blur /= 16.0;
     
     // --- Alternative: Simple unsharp mask for small images ---
     float3 sharpened;
     if (imageSize < 500.0) {
     // Small image er jonno simpler approach
     float3 blurred = (base + blur) * 0.5; // Softer blur
     sharpened = base + (base - blurred) * factor * 2.0;
     } else {
     // Original image er jonno detailed approach
     float3 highpass = base - blur;
     float sharpness = length(highpass);
     
     float clarityStrength = mix(1.0, 3.0, factor);
     float softener = smoothstep(0.01, 0.15, sharpness);
     float localVariance = dot(highpass, highpass);
     float adaptiveStrength = mix(clarityStrength, clarityStrength * 1.8,
     smoothstep(0.0, 0.01, localVariance));
     
     sharpened = base + highpass * adaptiveStrength * (1.0 - softener);
     
     // Optional second pass only for large images
     if (imageSize > 1200.0) {
     float3 highpass2 = base - blur;
     sharpened += highpass2 * (clarityStrength * 0.5) * (1.0 - softener);
     }
     }
     
     // --- Clamp and blend ---
     sharpened = clamp(sharpened, 0.0, 1.0);
     
     // Small image e softer blending
     float blendStrength = eyeMask;
     if (imageSize < 500.0) {
     blendStrength = eyeMask * 0.8; // Reduced effect for small images
     }
     
     float3 finalColor = mix(base, sharpened, blendStrength);
     
     return float4(finalColor, color.a);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
     float2 uv = in.textureCoordinate;
     float4 color = tex.sample(s, uv);
     float3 base = color.rgb;
     
     // --- Distance fields for eyes ---
     float dLeft  = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
     float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);
     
     // --- Smooth eye mask with feather ---
     float feather = 0.008;
     float leftMask  = 1.0 - smoothstep(-feather, feather, dLeft);
     float rightMask = 1.0 - smoothstep(-feather, feather, dRight);
     float eyeMaskRaw = max(leftMask, rightMask);
     
     // --- Eye centroid ---
     float2 eyeCentroid = float2(0.0);
     for (uint i = 0; i < leftContourCount; i++) eyeCentroid += leftContourPoints[i];
     for (uint i = 0; i < rightContourCount; i++) eyeCentroid += rightContourPoints[i];
     eyeCentroid /= float(leftContourCount + rightContourCount);
     
     // --- Radial falloff for inner softness ---
     float distanceToCenter = distance(uv, eyeCentroid);
     float radial = 1.0 - smoothstep(0.0, 0.40, distanceToCenter);
     
     // --- Combined mask ---
     float eyeMask = clamp(eyeMaskRaw * radial, 0.0, 1.0);
     eyeMask = pow(eyeMask, 0.9);
     
     // --- Early exit if factor too low ---
     float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
     factor = pow(factor, 0.85); // slightly more aggressive response
     if (factor < 0.01) return color;
     
     // --- Adaptive kernel size based on image resolution ---
     float2 texel = 1.0 / float2(tex.get_width(), tex.get_height());
     float imageSize = min(tex.get_width(), tex.get_height());
     
     float kernelScale = 1.0;
     if (imageSize < 500.0) kernelScale = 0.5;
     else if (imageSize < 800.0) kernelScale = 0.7;
     else kernelScale = 1.2;
     
     // --- 3x3 blur kernel (for soft clarity + noise suppression) ---
     float3 blur = float3(0.0);
     constexpr float kernelWeights[9] = {1,2,1,2,4,2,1,2,1};
     int sampleIndex = 0;
     for (int y = -1; y <= 1; y++) {
     for (int x = -1; x <= 1; x++) {
     float2 offset = float2(x, y) * texel * kernelScale;
     blur += tex.sample(s, uv + offset).rgb * kernelWeights[sampleIndex];
     sampleIndex++;
     }
     }
     blur /= 16.0;
     
     // --- Soft clarity highpass ---
     float3 highpass = base - blur;
     float sharpness = length(highpass);
     
     // --- Adaptive strength based on local contrast ---
     float clarityStrength = mix(1.0, 4.0, factor); // stronger edges
     float softener = smoothstep(0.01, 0.15, sharpness);
     float localVariance = dot(highpass, highpass);
     float adaptiveStrength = mix(clarityStrength, clarityStrength * 1.8,
     smoothstep(0.0, 0.01, localVariance));
     
     // --- Apply highpass with softener for smooth edges + noise reduction ---
     float3 sharpened = base + highpass * adaptiveStrength * (1.0 - softener);
     
     // --- Optional second pass for very large images ---
     if (imageSize > 1200.0) {
     float3 highpass2 = base - blur;
     sharpened += highpass2 * (clarityStrength * 0.7) * (1.0 - softener);
     }
     
     // --- Soft tonal compression to reduce noise while keeping sharpness ---
     sharpened = pow(sharpened, float3(0.95)); // slightly compress highlights
     
     // --- Clamp and blend using eye mask ---
     sharpened = clamp(sharpened, 0.0, 1.0);
     float blendStrength = min(1.0, eyeMask * 1.25); // slightly stronger effect
     float3 finalColor = mix(base, sharpened, blendStrength);
     
     return float4(finalColor, color.a);*/
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;

    // --- Distance fields for eyes ---
    float dLeft  = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
    float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);

    // --- Smooth eye mask ---
    float feather = 0.008;
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
    float radial = 1.0 - smoothstep(0.0, 0.40, distanceToCenter);
    float eyeMask = clamp(pow(eyeMaskRaw * radial, 0.9), 0.0, 1.0);

    // --- Early exit ---
    float factor = pow(clamp(scaleFactor / 100.0, 0.0, 1.0), 0.85);
    if (factor < 0.01) return color;

    // --- Adaptive kernel size ---
    float2 texel = 1.0 / float2(tex.get_width(), tex.get_height());
    float imageSize = min(tex.get_width(), tex.get_height());
    float kernelScale = (imageSize < 500.0) ? 0.5 : (imageSize < 800.0 ? 0.7 : 1.2);

    // --- 3x3 blur kernel for highpass ---
    float3 blur = float3(0.0);
    constexpr float kernelWeights[9] = {1,2,1,2,4,2,1,2,1};
    int sampleIndex = 0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 offset = float2(x, y) * texel * kernelScale;
            blur += tex.sample(s, uv + offset).rgb * kernelWeights[sampleIndex];
            sampleIndex++;
        }
    }
    blur /= 16.0;

    // --- Highpass (clarity / sharpening) ---
    float3 highpass = base - blur;
    float sharpness = length(highpass);

    // --- Adaptive sharpening strength ---
    float clarityStrength = mix(1.2, 4.0, factor);
    float softener = smoothstep(0.01, 0.15, sharpness);
    float localVariance = dot(highpass, highpass);
    float adaptiveStrength = mix(clarityStrength, clarityStrength * 1.8,
                                 smoothstep(0.0, 0.01, localVariance));

    // --- Apply sharpening ---
    float3 sharpened = base + highpass * adaptiveStrength * (1.0 - softener);

    // --- Optional second pass for very large images ---
    if (imageSize > 1200.0) {
        sharpened += highpass * (clarityStrength * 0.7) * (1.0 - softener);
    }

    // --- Soft tonal compression (keep noise) ---
    sharpened = pow(sharpened, float3(0.97));
    sharpened = clamp(sharpened, 0.0, 1.0);

    // --- Blend with eye mask ---
    float blendStrength = min(1.0, eyeMask * 1.25);
    float3 finalColor = mix(base, sharpened, blendStrength);

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
 
 
 constexpr sampler s(address::clamp_to_edge, filter::linear);
 float2 uv = in.textureCoordinate;
 float4 color = tex.sample(s, uv);
 float3 base = color.rgb;

 // --- Distance fields for eyes ---
 float dLeft  = signedDistancePolygon(uv, leftContourPoints, leftContourCount);
 float dRight = signedDistancePolygon(uv, rightContourPoints, rightContourCount);

 // --- Border thickness ---
 float thickness = 0.01;   // UV units
 float feather   = 0.005;  // soft edge

 float leftBorder  = smoothstep(thickness + feather, thickness - feather, dLeft) - smoothstep(-thickness - feather, -thickness + feather, dLeft);
 float rightBorder = smoothstep(thickness + feather, thickness - feather, dRight) - smoothstep(-thickness - feather, -thickness + feather, dRight);

 float borderMask = max(leftBorder, rightBorder);

 // --- Border color ---
 float3 borderColor = float3(1.0, 0.0, 0.0);

 // --- Blend border with original ---
 float3 finalColor = mix(base, borderColor, borderMask);

 return float4(finalColor, color.a);
 
 constexpr sampler s(address::clamp_to_edge, filter::linear);
 float2 uv = in.textureCoordinate;
     float4 color = tex.sample(s, uv);
     float3 base = color.rgb;

     float lineWidth = 0.001; // thickness of the line

     float minDist = 1e5;
 
 

     // loop through consecutive points
     for (uint i = 0; i < leftContourCount; ++i) {
         float2 a = leftContourPoints[i];
         float2 b = leftContourPoints[(i + 1) % leftContourCount]; // wrap last to first

         float2 ab = b - a;
         float t = clamp(dot(uv - a, ab) / dot(ab, ab), 0.0, 1.0);
         float2 proj = a + t * ab;
         float d = length(uv - proj);
         minDist = min(minDist, d);
     }

     // Draw line only if within lineWidth
     float lineMask = minDist < lineWidth ? 1.0 : 0.0;

     float3 lineColor = float3(1.0, 1.0, 1.0); // white line
     float3 finalColor = mix(base, lineColor, lineMask);

     return float4(finalColor, color.a);
 
 */
