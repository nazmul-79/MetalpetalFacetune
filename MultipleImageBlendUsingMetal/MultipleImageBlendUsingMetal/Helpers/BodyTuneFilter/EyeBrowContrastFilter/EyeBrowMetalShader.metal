//
//  EyeBrowMetalShader.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 28/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

// --- Distance function to polygon ---
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

        // winding check
        if (((a.y > p.y) != (b.y > p.y)) &&
            (p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x)) {
            inside = !inside;
        }
    }
    return inside ? -minDist : minDist;
}

fragment float4 eyeBrowBrighterShader(VertexOut in [[stage_in]],
                                      texture2d<float> tex [[texture(0)]],
                                      device const float2 *leftbrowPoints [[buffer(0)]],
                                      constant uint &leftbrowCount [[buffer(1)]],
                                      device const float2 *rightbrowPoints [[buffer(2)]],
                                      constant uint &rightbrowCount [[buffer(3)]],
                                      constant float &scaleFactor [[buffer(4)]]) {
   /* constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    if (alpha < 0.01) return texColor;

    float3 base = texColor.rgb;

    // --- Distance fields ---
    float dLeft  = signedDistancePolygon(uv, leftbrowPoints, leftbrowCount);
    float dRight = signedDistancePolygon(uv, rightbrowPoints, rightbrowCount);

    float feather = 0.01;
    float maskLeft  = 1.0 - smoothstep(-feather, feather, dLeft);
    float maskRight = 1.0 - smoothstep(-feather, feather, dRight);
    float mask = max(maskLeft, maskRight);

    // Normalize factor (-100 to 100 → -1.0 to 1.0)
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);

    if (abs(factor) < 0.001) return texColor;

    // --- Brightness/contrast adjustment ---
    float3 color = base;

    // Shift contrast around mid-gray (0.5)
    if (factor > 0.0) {
        // Darker eyebrows (more defined)
        color = mix(color, color * 0.7, factor); // reduce brightness
    } else {
        // Lighter eyebrows (fade)
        color = mix(color, color + (1.0 - color) * 0.4, -factor);
    }

    // Blend smoothly with mask
    float3 finalColor = mix(base, color, mask * abs(factor));

    return float4(finalColor, alpha);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
       float2 uv = in.textureCoordinate;

       float4 texColor = tex.sample(s, uv);

       // --- Border thickness in UV space ---
       float border = 0.002;

       // Distance to polygons
       float dLeft  = signedDistancePolygon(uv, leftbrowPoints, leftbrowCount);
       float dRight = signedDistancePolygon(uv, rightbrowPoints, rightbrowCount);

       // Border masks
       float leftBorder  = 1.0 - smoothstep(-border, border, dLeft);
       float rightBorder = 1.0 - smoothstep(-border, border, dRight);

       float borderMask = max(leftBorder, rightBorder);

       // Border color (red here, can change)
       float3 borderColor = float3(1.0, 0.0, 0.0);

       // Mix base with border
       float3 finalColor = mix(texColor.rgb, borderColor, borderMask);

       return float4(finalColor, texColor.a);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    if (alpha < 0.01) return texColor;

    float3 base = texColor.rgb;

    // --- Distance fields ---
    float dLeft  = signedDistancePolygon(uv, leftbrowPoints, leftbrowCount);
    float dRight = signedDistancePolygon(uv, rightbrowPoints, rightbrowCount);

    float feather = 0.015;
    float maskLeft  = 1.0 - smoothstep(-feather, feather, dLeft);
    float maskRight = 1.0 - smoothstep(-feather, feather, dRight);
    float mask = max(maskLeft, maskRight);

    // Clamp scale factor (-100..100 → -1..1)
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
    if (abs(factor) < 0.001) return texColor;

    // --- Convert base color to HSL ---
    float3 hsl = rgb2hsl(base);

    // --- Adjust lightness & saturation only (keep hue same) ---
    if (factor > 0.0) {
        // DARKER / DEEPER
        hsl.z = clamp(hsl.z * (1.0 - 0.1 * factor), 0.0, 1.0);  // decrease lightness
        hsl.y = clamp(hsl.y * (1.0 + 0.3 * factor), 0.0, 1.0);  // increase saturation
    } else {
        // LIGHTER / SOFTER
        hsl.z = clamp(hsl.z + (1.0 - hsl.z) * 0.1 * (-factor), 0.0, 1.0);  // increase lightness
        hsl.y = clamp(hsl.y * (1.0 - 0.2 * (-factor)), 0.0, 1.0);            // decrease saturation
    }

    // Convert back to RGB
    float3 adjustedColor = hsl2rgb(hsl);

    // --- Smooth blend with mask ---
    float3 finalColor = mix(base, adjustedColor, mask * abs(factor));

    return float4(finalColor, alpha);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    if (alpha < 0.01) return texColor;

    float3 base = texColor.rgb;

    // --- Distance fields ---
    float dLeft  = signedDistancePolygon(uv, leftbrowPoints, leftbrowCount);
    float dRight = signedDistancePolygon(uv, rightbrowPoints, rightbrowCount);

    float feather = 0.015;
    float maskLeft  = 1.0 - smoothstep(-feather, feather, dLeft);
    float maskRight = 1.0 - smoothstep(-feather, feather, dRight);
    float mask = max(maskLeft, maskRight);

    // --- Smooth mask ---
    mask = pow(mask, 1.2); // edges softer

    // Clamp scale factor (-100..100 → -1..1)
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
    if (abs(factor) < 0.001) return texColor;

    // --- Convert base color to HSL ---
    float3 hsl = rgb2hsl(base);

    // --- Gradual effect ---
    float effect = mask * abs(factor);   // use as interpolation weight
    effect = smoothstep(0.0, 1.0, effect); // makes transition gradual

    if (factor > 0.0) {
        // DARKER / DEEPER
        hsl.z = clamp(hsl.z * (1.0 - 0.15 * effect), 0.0, 1.0);
        hsl.y = clamp(hsl.y * (1.0 + 0.2 * effect), 0.0, 1.0);
    } else {
        // LIGHTER / SOFTER
        hsl.z = clamp(hsl.z + (1.0 - hsl.z) * 0.15 * effect, 0.0, 1.0);
        hsl.y = clamp(hsl.y * (1.0 - 0.2 * effect), 0.0, 1.0);
    }

    // Convert back to RGB
    float3 adjustedColor = hsl2rgb(hsl);

    // Blend with original
    float3 finalColor = mix(base, adjustedColor, effect);

    return float4(finalColor, alpha);*/
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    if (alpha < 0.01) return texColor;

    float3 base = texColor.rgb;

    // --- Distance fields to left/right brow polygons ---
    float dLeft  = signedDistancePolygon(uv, leftbrowPoints, leftbrowCount);
    float dRight = signedDistancePolygon(uv, rightbrowPoints, rightbrowCount);

    // --- Feather / mask ---
    float feather = 0.015;
    float maskLeft  = 1.0 - smoothstep(-feather, feather, dLeft);
    float maskRight = 1.0 - smoothstep(-feather, feather, dRight);
    float mask = max(maskLeft, maskRight);
    mask = pow(mask, 1.2); // soften edges

    // --- Slider factor (-100..100 -> -1..1) ---
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
    if (abs(factor) < 0.001) return texColor;

    // --- Pixel-wise contrast scaling ---
    float effect = mask; // mask only for edges
    float contrastScale = 1.0 + 0.3 * factor * effect; // adjust 0.25 for intensity

    // Contrast around mid-gray (0.5)
    float3 contrastedColor = (base - 0.5) * contrastScale + 0.5;
    contrastedColor = clamp(contrastedColor, 0.0, 1.0);

    return float4(contrastedColor, alpha);


}
