//
//  LipsBrigherShader.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 17/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

// --- Distance to line segment ---
/*inline float distanceToSegment(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    if (l2 == 0.0) return distance(p, v);
    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
    float2 projection = v + t * vw;
    return distance(p, projection);
}

// --- Signed distance from polygon (negative inside) ---
inline float signedDistancePolygon(float2 p,
                                   device const float2* points,
                                   uint count) {
    float d = distance(p, points[0]);
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        d = min(d, distanceToSegment(p, pi, pj));
        if (((pi.y > p.y) != (pj.y > p.y)) &&
            (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)) {
            inside = !inside;
        }
    }
    return inside ? -d : d;
}

// --- Softlight blend (per channel) ---
inline float3 softlight(float3 base, float3 blend) {
    return float3(
        (blend.r < 0.5) ? (2.0 * base.r * blend.r + base.r * base.r * (1.0 - 2.0 * blend.r))
                        : (sqrt(base.r) * (2.0 * blend.r - 1.0) + (2.0 * base.r * (1.0 - blend.r))),
        (blend.g < 0.5) ? (2.0 * base.g * blend.g + base.g * base.g * (1.0 - 2.0 * blend.g))
                        : (sqrt(base.g) * (2.0 * blend.g - 1.0) + (2.0 * base.g * (1.0 - blend.g))),
        (blend.b < 0.5) ? (2.0 * base.b * blend.b + base.b * base.b * (1.0 - 2.0 * blend.b))
                        : (sqrt(base.b) * (2.0 * blend.b - 1.0) + (2.0 * base.b * (1.0 - blend.b)))
    );
}

// --- Gaussian-like feather for smooth mask ---
inline float featherMask(float d, float feather) {
    // distance-based soft mask
    return clamp(1.0 - smoothstep(0.0, feather, abs(d)), 0.0, 1.0);
}

// --- RGB ↔ HSV helpers ---
inline float3 rgb2hsv(float3 c) {
    float4 K = float4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    float4 p = (c.g < c.b) ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
    float4 q = (c.r < p.x) ? float4(p.xyw, c.r) : float4(c.r, p.yzx);
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),
                  d / (q.x + e),
                  q.x);
}

inline float3 hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


fragment float4 lipsEffectShader(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 device const float2 *outerPoints [[buffer(0)]],
                                 constant uint &outerCount [[buffer(1)]],
                                 device const float2 *innerPoints [[buffer(2)]],
                                 constant uint &innerCount [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);
        float2 uv = in.textureCoordinate;

        // --- Distance to outer polygon only (inner lips preserved) ---
        float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);

        // --- Adaptive feather ---
        float2 minP = outerPoints[0], maxP = outerPoints[0];
        for (uint i = 1; i < outerCount; i++) {
            minP = min(minP, outerPoints[i]);
            maxP = max(maxP, outerPoints[i]);
        }
        float lipSize = max(maxP.x - minP.x, maxP.y - minP.y);
        float feather = 0.02 * lipSize;

        // --- Edge mask ---
        float outerMask = clamp(1.0 - smoothstep(0.0, feather, abs(dOuter)), 0.0, 1.0);
        float mask = pow(outerMask, 0.8);

        // --- Sample base color ---
        float4 baseColor = tex.sample(s, uv);
        float3 lipColor = float3(0.85, 0.25, 0.35);

        if (mask > 0.0) {
            // --- Softlight blend ---
            float3 blended = softlight(baseColor.rgb, lipColor);

            // --- Minor HSV adjustments ---
            float3 hsv = rgb2hsv(blended);
            hsv.y = clamp(hsv.y * 0.5 + mask * 0.25 * (scaleFactor / 100.0), 0.0, 1.0);
            hsv.z = clamp(hsv.z + mask * 0.05 * (scaleFactor / 100.0), 0.0, 1.0);
            blended = hsv2rgb(hsv);

            // --- Apply fade only at edges ---
            float fade = mask * (scaleFactor / 100.0);
            baseColor.rgb = mix(baseColor.rgb, blended, fade);
        }

        return baseColor;
}*/

/*
// --- Distance to line segment ---
inline float distanceToSegment(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    if (l2 == 0.0) return distance(p, v);
    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
    float2 projection = v + t * vw;
    return distance(p, projection);
}

// --- Signed distance from polygon (negative inside) ---
inline float signedDistancePolygon(float2 p,
                                   device const float2* points,
                                   uint count) {
    float d = distance(p, points[0]);
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        d = min(d, distanceToSegment(p, pi, pj));
        if (((pi.y > p.y) != (pj.y > p.y)) &&
            (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)) {
            inside = !inside;
        }
    }
    return inside ? -d : d;
}

// --- More natural lip color blending ---
inline float3 naturalLipBlend(float3 base, float3 lipColor, float mask) {
    // Preserve the natural texture and variation of lips
    float a = (base.r + base.g + base.b) / 3.0;
    float softA = pow(a, 0.7);       // tweak exponent for stronger/weaker effect
    float3 blended = mix(base, lipColor, softA);
    
    return blended;
    
    // Enhance natural lip tones rather than replacing them
    blended.r = mix(blended.r, lipColor.r, 0.6);
    blended.g = mix(blended.g, lipColor.g * 0.7, 0.4);
    blended.b = mix(blended.b, lipColor.b * 0.8, 0.5);
    
    // Maintain some of the original color variation
    return mix(base, blended, mask * 0.9);
}

fragment float4 lipsEffectShader(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 device const float2 *outerPoints [[buffer(0)]],
                                 constant uint &outerCount [[buffer(1)]],
                                 device const float2 *innerPoints [[buffer(2)]],
                                 constant uint &innerCount [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
        float2 uv = in.textureCoordinate;

        // --- Sample base color ---
        float4 baseColor = tex.sample(s, uv);
        float3 base = baseColor.rgb;

        // --- Signed distances for lip polygon ---
        float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
        float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

        // --- Feathering for soft edges ---
        float outerFeather = 0.0002;
        float innerFeather = 0.0015;
        float outerMask = 1.0 - smoothstep(-outerFeather, outerFeather, dOuter);
        float innerMask = smoothstep(-innerFeather, innerFeather, dInner);

        // Combine masks
        float mask = outerMask * innerMask;

        // --- Find dominant color channel in the lip area ---
        float maxChannel = max(base.r, max(base.g, base.b));
        float minChannel = min(base.r, min(base.g, base.b));
        float dominance = maxChannel - minChannel;
        
        // Determine which color channel is most dominant
        float redDominance = base.r - max(base.g, base.b);
        float greenDominance = base.g - max(base.r, base.b);
        float blueDominance = base.b - max(base.r, base.g);
        
        // Calculate color enhancement based on dominant channel
        float3 enhancedColor = base;
        
        if (redDominance > greenDominance && redDominance > blueDominance) {
            // Enhance red tones
            enhancedColor.r *= 1.0 + scaleFactor * 0.02;
            enhancedColor.g *= 0.95;
            enhancedColor.b *= 0.95;
        } else if (greenDominance > redDominance && greenDominance > blueDominance) {
            // Enhance natural pink tones (balance of red and green)
            enhancedColor.r *= 1.0 + scaleFactor * 0.015;
            enhancedColor.g *= 1.0 + scaleFactor * 0.005;
            enhancedColor.b *= 0.95;
        } else {
            // For blue dominance or equal channels, create natural lip color
            enhancedColor.r *= 1.0 + scaleFactor * 0.01;
            enhancedColor.g *= 0.98;
            enhancedColor.b *= 0.97;
        }
        
        // Apply saturation boost to make lips pop
        float luminance = dot(enhancedColor, float3(0.299, 0.587, 0.114));
        float3 saturated = mix(float3(luminance), enhancedColor, 1.0 + scaleFactor * 0.01);
        
        // --- Apply blend with intensity ---
        float intensity = clamp(scaleFactor / 100.0, 0.0, 1.0);
        float3 blended = mix(base, saturated, mask);
        baseColor.rgb = mix(base, blended, intensity);

        return baseColor;
}



*/


/*// --- Distance to line segment ---
inline float distanceToSegment(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    if (l2 == 0.0) return distance(p, v);
    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
    float2 projection = v + t * vw;
    return distance(p, projection);
}

// --- Signed distance from polygon (negative inside) ---
inline float signedDistancePolygon(float2 p,
                                   device const float2* points,
                                   uint count) {
    float d = distance(p, points[0]);
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        d = min(d, distanceToSegment(p, pi, pj));
        if (((pi.y > p.y) != (pj.y > p.y)) &&
            (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)) {
            inside = !inside;
        }
    }
    return inside ? -d : d;
}

inline float3 overlayBlend(float3 base, float3 color) {
    float3 res;
    res.r = (base.r < 0.5) ? (2.0 * base.r * color.r) : (1.0 - 2.0 * (1.0 - base.r) * (1.0 - color.r));
    res.g = (base.g < 0.5) ? (2.0 * base.g * color.g) : (1.0 - 2.0 * (1.0 - base.g) * (1.0 - color.g));
    res.b = (base.b < 0.5) ? (2.0 * base.b * color.b) : (1.0 - 2.0 * (1.0 - base.b) * (1.0 - color.b));
    return res;
}

// --- Soft Dodge Blend (texture-preserving) ---
inline float3 softDodge(float3 base, float3 color, float strength) {
    return base + (base * color) * strength;
}

float3 blurSample(texture2d<float> tex, float2 uv, sampler s) {
    float2 off = 1.0 / float2(tex.get_width(), tex.get_height());
    return ( tex.sample(s, uv).rgb +
             tex.sample(s, uv + off).rgb +
             tex.sample(s, uv - off).rgb +
             tex.sample(s, uv + float2(off.x, -off.y)).rgb +
             tex.sample(s, uv - float2(off.x, -off.y)).rgb ) / 5.0;
}

// --- General color airbrush blend (any target color) ---
inline float3 applyColor(float3 base, float3 targetColor, float strength) {
    // strength: 0 = no change, 1 = full targetColor
    return mix(base, targetColor, strength);
}

fragment float4 lipsEffectShader(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 device const float2 *outerPoints [[buffer(0)]],
                                 constant uint &outerCount [[buffer(1)]],
                                 device const float2 *innerPoints [[buffer(2)]],
                                 constant uint &innerCount [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {

    // --- Lip color ---
    float3 lipColor = float3(0.0,0.0,0.0);

    // --- Airbrush-style tint applied on low-frequency base ---
    constexpr sampler s(address::clamp_to_edge, filter::linear);
       float2 uv = in.textureCoordinate;

       // --- Sample base color ---
       float3 base = tex.sample(s, uv).rgb;

       // --- Build feathered lip mask ---
       float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
       float dInner = signedDistancePolygon(uv, innerPoints, innerCount);
       float outerMask = 1.0 - smoothstep(-0.004, 0.004, dOuter);   // feather edges
       float innerMask = smoothstep(-0.003, 0.003, dInner);
       float mask = outerMask * innerMask;

       // --- Low-frequency base (blurred) for airbrush effect ---
       float3 lowFreq = blurSample(tex, uv, s);

       // --- High-frequency details (preserve pores & wrinkles) ---
       float3 details = base / max(lowFreq, 0.001);

       // --- Apply target color on low-frequency base ---
       float strength = 0.6; // adjust for airbrush effect
       float3 tinted = applyColor(lowFreq, lipColor, strength);

       // --- Restore high-frequency details ---
       float3 texturedLip = tinted * details;

       // --- Apply mask with intensity control ---
       float intensity = clamp(scaleFactor / 100.0, 0.0, 1.0);
       float3 finalColor = mix(base, texturedLip, mask * intensity);

       return float4(finalColor, 1.0);
}
*/

// --- Distance to line segment ---
/*inline float distanceToSegment(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    if (l2 == 0.0) return distance(p, v);
    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
    float2 projection = v + t * vw;
    return distance(p, projection);
}

// --- Signed distance from polygon (negative inside) ---
inline float signedDistancePolygon(float2 p,
                                   device const float2* points,
                                   uint count) {
    float d = distance(p, points[0]);
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        d = min(d, distanceToSegment(p, pi, pj));
        if (((pi.y > p.y) != (pj.y > p.y)) &&
            (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)) {
            inside = !inside;
        }
    }
    return inside ? -d : d;
}

// --- Soft Dodge blend for preserving texture ---
inline float3 softDodge(float3 base, float3 color, float strength) {
    return base + (base * color) * strength;
}

// --- Dynamic blur sample for any texture size ---
float3 blurSample(texture2d<float> tex, float2 uv, sampler s) {
    float2 off = 1.0 / float2(tex.get_width(), tex.get_height());
    return ( tex.sample(s, uv).rgb +
             tex.sample(s, uv + off).rgb +
             tex.sample(s, uv - off).rgb +
             tex.sample(s, uv + float2(off.x, -off.y)).rgb +
             tex.sample(s, uv - float2(off.x, -off.y)).rgb ) / 5.0;
}

// --- Airbrush-style color application (any color) ---
inline float3 applyColor(float3 base, float3 targetColor, float strength) {
    return mix(base, targetColor, strength);
}

fragment float4 lipsEffectShader(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 device const float2 *outerPoints [[buffer(0)]],
                                 constant uint &outerCount [[buffer(1)]],
                                 device const float2 *innerPoints [[buffer(2)]],
                                 constant uint &innerCount [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);
       float2 uv = in.textureCoordinate;

       // --- Base color ---
       float3 base = tex.sample(s, uv).rgb;

       // --- Feathered lip mask ---
       float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
       float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

       // Vertical spread factor (more feather at top/bottom)
       float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0; // center = 1, top/bottom = 0
       float featherOuter = 0.008 * verticalFactor;         // outer feather spreads top/bottom
       float outerMask = 1.0 - smoothstep(-featherOuter, featherOuter, dOuter);
       float innerMask = smoothstep(-featherOuter*0.95, featherOuter*0.75, dInner);
       float mask = outerMask * innerMask;
       mask = pow(mask, 0.9); // soften mask edges

       // --- Low-frequency blur for airbrush ---
       float blurStrength = mix(0.2, 0.6, mask); // less blur near edges
       float3 lowFreq = blurSample(tex, uv, s) * (1.0 - blurStrength) + base * blurStrength;

       // --- High-frequency details (pores/wrinkles) ---
       float3 details = base / max(lowFreq, 0.001);

       // --- Lip color ---
       float3 lipColor = float3(0.0,0.0,0.0); // black example

       // --- Apply color on low-frequency base ---
       float3 tinted = applyColor(lowFreq, lipColor, mask * 0.8); // stronger in center

       // --- Restore texture details ---
       float3 texturedLip = tinted * details;

       // --- Final mix with intensity control ---
       float intensity = clamp(scaleFactor / 100.0, 0.0, 1.0);
       float3 finalColor = mix(base, texturedLip, intensity);

       return float4(finalColor, 1.0);
}

*/

/*// --- Distance to line segment ---
inline float distanceToSegment(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    if (l2 == 0.0) return distance(p, v);
    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
    float2 projection = v + t * vw;
    return distance(p, projection);
}

// --- Signed distance from polygon (negative inside) ---
inline float signedDistancePolygon(float2 p,
                                   device const float2* points,
                                   uint count) {
    float d = distance(p, points[0]);
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        d = min(d, distanceToSegment(p, pi, pj));
        if (((pi.y > p.y) != (pj.y > p.y)) &&
            (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)) {
            inside = !inside;
        }
    }
    return inside ? -d : d;
}

// --- Soft dodge blend (preserve texture) ---
inline float3 softDodge(float3 base, float3 color, float strength) {
    return base + (base * color) * strength;
}

// --- Dynamic blur for any texture size ---
float3 blurSample(texture2d<float> tex, float2 uv, sampler s) {
    float2 off = 1.0 / float2(tex.get_width(), tex.get_height());
    return ( tex.sample(s, uv).rgb +
             tex.sample(s, uv + off).rgb +
             tex.sample(s, uv - off).rgb +
             tex.sample(s, uv + float2(off.x, -off.y)).rgb +
             tex.sample(s, uv - float2(off.x, -off.y)).rgb ) / 5.0;
}

// --- General airbrush color application ---
inline float3 applyColor(float3 base, float3 targetColor, float strength) {
    return mix(base, targetColor, strength);
}

// --- Main Lips Shader ---
fragment float4 lipsEffectShader(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 device const float2 *outerPoints [[buffer(0)]],
                                 constant uint &outerCount [[buffer(1)]],
                                 device const float2 *innerPoints [[buffer(2)]],
                                 constant uint &innerCount [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    // --- Base color ---
    float3 base = tex.sample(s, uv).rgb;

    // --- Signed distances ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    // --- Outer feather ensures full coverage ---
    float minFeather = 0.003; // minimum to cover polygon fully
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0; // center=1, top/bottom=0
    float featherOuter = max(0.008 * verticalFactor, minFeather);
    float outerMask = 1.0 - smoothstep(-featherOuter, featherOuter, dOuter);

    // --- Inner mask feather ---
    float innerMask = smoothstep(-featherOuter*0.75, featherOuter*0.75, dInner);
    float mask = outerMask * innerMask;
    mask = pow(mask, 0.9); // smooth edges
    
    if (dOuter <= 0.0) {
        outerMask = 1.0; // fully inside polygon
    } else {
        outerMask = 1.0 - smoothstep(0.0, featherOuter, dOuter); // only feather at edges
    }


    // --- Low-frequency blur for airbrush ---
    float blurStrength = mix(0.2, 0.6, mask); // less blur near edges
    float3 lowFreq = blurSample(tex, uv, s) * (1.0 - blurStrength) + base * blurStrength;

    // --- High-frequency details ---
    float3 details = base / max(lowFreq, 0.001);

    // --- Lip color (black example, change RGB as needed) ---
    float3 lipColor = float3(1.0, 0.5, 0.5);

    // --- Apply color on low-frequency base ---
    float3 tinted = applyColor(lowFreq, lipColor, mask * 0.8);

    // --- Restore texture details ---
    float3 texturedLip = tinted * details;

    // --- Final mix with intensity control ---
    float intensity = clamp((scaleFactor / 100.0) * 0.45, 0.0, 1.0);
    float3 finalColor = mix(base, texturedLip, intensity);

    return float4(finalColor, 1.0);
}

*/

/*// --- Distance to line segment ---
inline float distanceToSegment(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    if (l2 == 0.0) return distance(p, v);
    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
    float2 projection = v + t * vw;
    return distance(p, projection);
}

// --- Signed distance from polygon (negative inside) ---
inline float signedDistancePolygon(float2 p,
                                   device const float2* points,
                                   uint count) {
    float d = distance(p, points[0]);
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        d = min(d, distanceToSegment(p, pi, pj));
        if (((pi.y > p.y) != (pj.y > p.y)) &&
            (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)) {
            inside = !inside;
        }
    }
    return inside ? -d : d;
}

// --- Dynamic blur for any texture size ---
inline float3 blurSample(texture2d<float> tex, float2 uv, sampler s) {
    float2 off = 1.0 / float2(tex.get_width(), tex.get_height());
    return ( tex.sample(s, uv).rgb +
             tex.sample(s, uv + off).rgb +
             tex.sample(s, uv - off).rgb +
             tex.sample(s, uv + float2(off.x, -off.y)).rgb +
             tex.sample(s, uv - float2(off.x, -off.y)).rgb ) / 5.0;
}

// --- Apply color softly ---
inline float3 applyColor(float3 base, float3 targetColor, float strength) {
    return mix(base, targetColor, strength);
}

// --- Main Lips Shader ---
fragment float4 lipsEffectShader(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 device const float2 *outerPoints [[buffer(0)]],
                                 constant uint &outerCount [[buffer(1)]],
                                 device const float2 *innerPoints [[buffer(2)]],
                                 constant uint &innerCount [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    // --- Base color from texture ---
    float3 base = tex.sample(s, uv).rgb;

    // --- Signed distances ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    // --- Feather control for smooth lips mask ---
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float featherOuter = max(0.008 * verticalFactor, minFeather);
    float outerMask = 1.0 - smoothstep(-featherOuter, featherOuter, dOuter);
    float innerMask = smoothstep(-featherOuter * 0.75, featherOuter * 0.75, dInner);
    float mask = outerMask * innerMask;
    mask = pow(mask, 0.9);

    if (dOuter <= 0.0) {
        outerMask = 1.0;
    } else {
        outerMask = 1.0 - smoothstep(0.0, featherOuter, dOuter);
    }

    // --- Low-frequency blur (airbrush base) ---
    float blurStrength = mix(0.2, 0.6, mask);
    float3 lowFreq = blurSample(tex, uv, s) * (1.0 - blurStrength) + base * blurStrength;

    // --- High-frequency detail preservation ---
    float3 details = (base + 0.001) / (lowFreq + 0.001);

    // --- Lipstick target color (change this for other shades) ---
    float3 lipColor = float3(0.929, 0.247, 0.153);

    // --- Tint base with lip color ---
    float3 tinted = applyColor(lowFreq, lipColor, mask * 0.6);

    // --- Restore fine details (natural lip lines) ---
    float detailStrength = 0.6; // 0 = flat, 1 = full detail
    float3 texturedLip = mix(tinted, tinted * details, detailStrength);

    // --- Final mix with intensity control ---
    float intensity = clamp((scaleFactor / 100.0) * 0.45, 0.0, 1.0);
    float3 finalColor = mix(base, texturedLip, intensity);

    return float4(finalColor, 1.0);
}

*/

//inner lips detection

/*// --- Distance to line segment ---
inline float distanceToSegment(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    if (l2 == 0.0) return distance(p, v);
    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
    float2 projection = v + t * vw;
    return distance(p, projection);
}

// --- Signed distance from polygon (negative inside) ---
inline float signedDistancePolygon(float2 p,
                                   device const float2* points,
                                   uint count) {
    float d = distance(p, points[0]);
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        d = min(d, distanceToSegment(p, pi, pj));
        if (((pi.y > p.y) != (pj.y > p.y)) &&
            (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)) {
            inside = !inside;
        }
    }
    return inside ? -d : d;
}

// --- Dynamic blur for low-frequency base ---
inline float3 blurSample(texture2d<float> tex, float2 uv, sampler s) {
    float2 off = 1.0 / float2(tex.get_width(), tex.get_height());
    return ( tex.sample(s, uv).rgb +
             tex.sample(s, uv + off).rgb +
             tex.sample(s, uv - off).rgb +
             tex.sample(s, uv + float2(off.x, -off.y)).rgb +
             tex.sample(s, uv - float2(off.x, -off.y)).rgb ) / 5.0;
}

// --- Soft-light blend for natural tint ---
inline float3 softLight(float3 base, float3 color, float strength) {
    float3 result = (1.0 - 2.0*color)*base*base + 2.0*color*base;
    return mix(base, result, strength);
}

// --- Main Lips Shader ---
fragment float4 lipsEffectShader(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 device const float2 *outerPoints [[buffer(0)]],
                                 constant uint &outerCount [[buffer(1)]],
                                 device const float2 *innerPoints [[buffer(2)]],
                                 constant uint &innerCount [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    // --- Base texture color ---
    float3 base = tex.sample(s, uv).rgb;

    // --- Signed distances ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    // --- Adaptive feather for smooth mask ---
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    // --- Outer & inner masks ---
    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    float innerMask = smoothstep(-feather, feather, dInner);

    // --- Gap-free, smooth lips mask ---
    float mask = outerMask * (1.0 - innerMask);
    mask = smoothstep(0.05, 0.95, clamp(mask, 0.0, 1.0)); // smooth edges

    // --- Low-frequency blur (airbrush base) ---
    float blurStrength = mix(0.15, 0.45, mask);
    float3 lowFreq = blurSample(tex, uv, s) * (1.0 - blurStrength) + base * blurStrength;

    // --- High-frequency details (softened) ---
    float3 highPass = base - lowFreq + 0.5;
    float3 details = clamp(highPass, 0.8, 1.2);
    float detailStrength = 0.5;
    float3 texturedBase = mix(lowFreq, lowFreq * details, detailStrength);

    // --- Lipstick color ---
    float3 lipColor = float3(0.929, 0.247, 0.153); // rgb(237,63,39)

    // --- Apply color with soft-light blending ---
    float3 tinted = softLight(texturedBase, lipColor, mask * 0.7);

    // --- Subtle gloss highlight ---
    float gloss = pow(saturate(1.0 - abs(uv.y - 0.5)), 8.0) * 0.15;
    tinted += gloss * mask;

    // --- Final mix constrained by mask and intensity ---
    float intensity = clamp((scaleFactor / 100.0) * 0.5, 0.0, 1.0);
    float3 finalColor = mix(base, tinted, intensity * mask);

    return float4(finalColor, 1.0);
}

*/
 //final version
// --- Distance to line segment ---
/*inline float distanceToSegment(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    if (l2 == 0.0) return distance(p, v);
    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
    float2 projection = v + t * vw;
    return distance(p, projection);
}

// --- Signed distance from polygon (negative inside) ---
inline float signedDistancePolygon(float2 p,
                                   device const float2* points,
                                   uint count) {
    float d = distance(p, points[0]);
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        d = min(d, distanceToSegment(p, pi, pj));
        if (((pi.y > p.y) != (pj.y > p.y)) &&
            (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)) {
            inside = !inside;
        }
    }
    return inside ? -d : d;
}

// --- Dynamic blur for low-frequency base ---
inline float3 blurSample(texture2d<float> tex, float2 uv, sampler s) {
    float2 off = 1.0 / float2(tex.get_width(), tex.get_height());
    return ( tex.sample(s, uv).rgb +
             tex.sample(s, uv + off).rgb +
             tex.sample(s, uv - off).rgb +
             tex.sample(s, uv + float2(off.x, -off.y)).rgb +
             tex.sample(s, uv - float2(off.x, -off.y)).rgb ) / 5.0;
}

// --- Soft-light blend for natural tint ---
inline float3 softLight(float3 base, float3 color, float strength) {
    float3 result = (1.0 - 2.0*color)*base*base + 2.0*color*base;
    return mix(base, result, strength);
}

// --- Main Lips Shader ---
fragment float4 lipsEffectShader(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 device const float2 *outerPoints [[buffer(0)]],
                                 constant uint &outerCount [[buffer(1)]],
                                 device const float2 *innerPoints [[buffer(2)]],
                                 constant uint &innerCount [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    // --- Base texture color ---
    float3 base = tex.sample(s, uv).rgb;

    // --- Signed distances ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    // --- Adaptive feather for smooth mask ---
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    // --- Outer & inner masks ---
    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    float innerMask = smoothstep(-feather, feather, dInner);

    // --- Combined smooth mask ---
    // Outer full apply, inner feather softens edges
    float mask = outerMask;           // outer lips fully
    mask *= mix(1.0, innerMask, 0.5); // inner lips subtle feather

    // Smooth edges
    mask = smoothstep(0.05, 0.95, clamp(mask, 0.0, 1.0));

    // --- Low-frequency blur (airbrush base) ---
    float blurStrength = mix(0.15, 0.45, mask);
    float3 lowFreq = blurSample(tex, uv, s) * (1.0 - blurStrength) + base * blurStrength;

    // --- High-frequency details (softened) ---
    float3 highPass = base - lowFreq + 0.5;
    float3 details = clamp(highPass, 0.8, 1.2);
    float detailStrength = 0.5;
    float3 texturedBase = mix(lowFreq, lowFreq * details, detailStrength);

    // --- Lipstick color ---
    //float3 lipColor = float3(0.929, 0.247, 0.153); // rgb(237,63,39)
    float3 lipColor = float3(0.231, 0.0078, 0.439);

    // --- Apply color with soft-light blending ---
    float3 tinted = softLight(texturedBase, lipColor, mask * 0.7);

    // --- Subtle gloss highlight ---
    float gloss = pow(saturate(1.0 - abs(uv.y - 0.5)), 8.0) * 0.15;
    tinted += gloss * mask;

    // --- Final mix constrained by mask and intensity ---
    float intensity = clamp((scaleFactor / 100.0) * 0.8, 0.0, 1.0);
    float3 finalColor = mix(base, tinted, intensity * mask);

    return float4(finalColor, 1.0);
}

*/
//innerl lips a
// --- Distance to line segment ---
inline float distanceToSegment(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    if (l2 == 0.0) return distance(p, v);
    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
    float2 projection = v + t * vw;
    return distance(p, projection);
}

// --- Signed distance from polygon ---
inline float signedDistancePolygon(float2 p, device const float2* points, uint count) {
    float d = distance(p, points[0]);
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        d = min(d, distanceToSegment(p, pi, pj));
        if (((pi.y > p.y) != (pj.y > p.y)) &&
            (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)) {
            inside = !inside;
        }
    }
    return inside ? -d : d;
}

// --- Dynamic blur ---
inline float3 blurSample(texture2d<float> tex, float2 uv, sampler s) {
    float2 off = 1.0 / float2(tex.get_width(), tex.get_height());
    return ( tex.sample(s, uv).rgb +
             tex.sample(s, uv + off).rgb +
             tex.sample(s, uv - off).rgb +
             tex.sample(s, uv + float2(off.x, -off.y)).rgb +
             tex.sample(s, uv - float2(off.x, -off.y)).rgb ) / 5.0;
}

// --- Brighten only ---
inline float3 brightenOnly(float3 color, float mask, float brightness) {
    return saturate(color + brightness * mask);
}

inline float3 adjustSaturationSafe(float3 color, float mask, float intensity) {
    float3 gray = float3((color.r + color.g + color.b) / 3.0);
    float scale = clamp(1.0 + intensity * mask, 0.0, 1.5); // max 1.5 avoid overbright
    return saturate(mix(gray, color, scale));
}


/*// --- Main Lips Shader (Outer lips only, brightness + saturation) ---
fragment float4 lipsEffectShader(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 device const float2 *outerPoints [[buffer(0)]],
                                 constant uint &outerCount [[buffer(1)]],
                                 device const float2 *innerPoints [[buffer(2)]],
                                 constant uint &innerCount [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    // --- Base color ---
    float3 base = tex.sample(s, uv).rgb;

    // --- Distance masks ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    float mask = smoothstep(0.05, 0.95, clamp(outerMask, 0.0, 1.0)); // outer lips only

    // --- Low-frequency blur ---
    float blurStrength = mix(0.15, 0.45, mask);
    float3 lowFreq = blurSample(tex, uv, s) * (1.0 - blurStrength) + base * blurStrength;

    // --- High-frequency details ---
    float3 highPass = base - lowFreq + 0.5;
    float3 details = clamp(highPass, 0.8, 1.2);
    float detailStrength = 0.5;
    float3 texturedBase = mix(lowFreq, lowFreq * details, detailStrength);

    // --- Brightness only ---
    float3 brightened = saturate(texturedBase + 0.05 * mask); // brightness boost

    // --- Saturation only ---
    float intensity = clamp((scaleFactor / 100.0) * 0.3, -1.0, 1.0);
    float3 gray = float3((brightened.r + brightened.g + brightened.b) / 3.0);
    float3 saturated = saturate(mix(gray, brightened, 1.0 + intensity * mask));

    // --- Gloss highlight (subtle) ---
    float gloss = pow(saturate(1.0 - abs(uv.y - 0.5)), 8.0) * 0.05;
    saturated += gloss * mask;

    // --- Final color mix ---
    float3 finalColor = mix(base, saturated, mask);

    return float4(finalColor, 1.0);
}*/


//Brighter lips
// --- Distance to line segment ---
//inline float distanceToSegment(float2 p, float2 v, float2 w) {
//    float2 vw = w - v;
//    float l2 = dot(vw, vw);
//    if (l2 == 0.0) return distance(p, v);
//    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
//    float2 projection = v + t * vw;
//    return distance(p, projection);
//}
//
//// --- Signed distance from polygon ---
//inline float signedDistancePolygon(float2 p, device const float2* points, uint count) {
//    float d = distance(p, points[0]);
//    bool inside = false;
//    for (uint i = 0, j = count - 1; i < count; j = i++) {
//        float2 pi = points[i];
//        float2 pj = points[j];
//        d = min(d, distanceToSegment(p, pi, pj));
//        if (((pi.y > p.y) != (pj.y > p.y)) &&
//            (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)) {
//            inside = !inside;
//        }
//    }
//    return inside ? -d : d;
//}
//
//// --- Dynamic blur ---
//inline float3 blurSample(texture2d<float> tex, float2 uv, sampler s) {
//    float2 off = 1.0 / float2(tex.get_width(), tex.get_height());
//    return ( tex.sample(s, uv).rgb +
//             tex.sample(s, uv + off).rgb +
//             tex.sample(s, uv - off).rgb +
//             tex.sample(s, uv + float2(off.x, -off.y)).rgb +
//             tex.sample(s, uv - float2(off.x, -off.y)).rgb ) / 5.0;
//}

// --- Main Lips Shader (Outer lips only, brightness + saturation) ---
fragment float4 lipsEffectShader(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 device const float2 *outerPoints [[buffer(0)]],
                                 constant uint &outerCount [[buffer(1)]],
                                 device const float2 *innerPoints [[buffer(2)]],
                                 constant uint &innerCount [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {

    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    // --- Base color ---
    float3 base = tex.sample(s, uv).rgb;

    // --- Distance masks ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    // Outer lips mask
    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    // Inner lips mask to exclude
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);

    // Subtract inner from outer
    float mask = max(outerMask - innerMask, 0.0);
    mask = smoothstep(0.05, 0.95, mask);

    // --- Low-frequency blur ---
    float blurStrength = mix(0.15, 0.45, mask);
    float3 lowFreq = blurSample(tex, uv, s) * (1.0 - blurStrength) + base * blurStrength;

    // --- High-frequency details ---
    float3 highPass = base - lowFreq + 0.5;
    float3 details = clamp(highPass, 0.8, 1.2);
    float detailStrength = 0.5;
    float3 texturedBase = mix(lowFreq, lowFreq * details, detailStrength);

    // --- Brightness only ---
    float3 brightened = saturate(texturedBase + 0.05 * mask); // brightness boost

    // --- Saturation only ---
    float intensity = clamp((scaleFactor / 100.0) * 0.25, -1.0, 1.0);
    float3 gray = float3((brightened.r + brightened.g + brightened.b) / 3.0);
    float3 saturated = saturate(mix(gray, brightened, 1.0 + intensity * mask));

    // --- Gloss highlight (subtle) ---
    float gloss = pow(saturate(1.0 - abs(uv.y - 0.5)), 8.0) * 0.05;
    saturated += gloss * mask;

    // --- Final color mix ---
    float3 finalColor = mix(base, saturated, mask);

    return float4(finalColor, 1.0);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    // --- Base color ---
    float3 base = tex.sample(s, uv).rgb;

    // --- Distance masks ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    // Outer lips mask
    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    // Inner lips mask to exclude
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);

    // Subtract inner from outer
    float mask = max(outerMask - innerMask, 0.0);
    mask = pow(mask, 1.5); // smooth radial falloff

    // --- Factor ---
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    if (factor < 0.001) return float4(base, 1.0); // zero scaleFactor, return original

    // --- Low-frequency blur ---
    float blurStrength = 0.02 * factor; // reduce overall blur
    float3 lowFreq = blurSample(tex, uv, s) * (1.0 - blurStrength) + base * blurStrength;

    // --- High-frequency details ---
    float3 highPass = base - lowFreq + 0.5;
    float3 details = clamp(highPass, 0.85, 1.15); // reduce extreme boost
    float detailStrength = 0.8 * factor;
    float3 texturedBase = mix(lowFreq, lowFreq * details, detailStrength);

    // --- Brightness ---
    float3 brightened = saturate(texturedBase + 0.03 * factor * mask); // subtle brightness

    // --- Saturation ---
    float3 gray = float3((brightened.r + brightened.g + brightened.b) / 3.0);
    float3 saturated = saturate(mix(gray, brightened, 1.0 + 0.4 * factor * mask));

    // --- Gloss highlight (subtle) ---
    float gloss = pow(saturate(1.0 - abs(uv.y - 0.5)), 6.0) * 0.03 * factor;
    saturated += gloss * mask;

    // --- Final mix ---
    float3 finalColor = mix(base, saturated, mask * factor);

    return float4(finalColor, 1.0);*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    // --- Base color ---
    float3 base = tex.sample(s, uv).rgb;

    // --- Distance masks ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    // Outer lips mask
    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    // Inner lips mask to exclude
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);

    // Subtract inner from outer
    float mask = max(outerMask - innerMask, 0.0);
    mask = pow(mask, 1.5); // smooth radial falloff

    // --- Factor ---
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    if (factor < 0.001) return float4(base, 1.0); // zero scaleFactor, return original

    // --- Brightness ---
    float3 brightened = saturate(base + 0.03 * factor * mask);

    // --- Saturation ---
    float3 gray = float3((brightened.r + brightened.g + brightened.b) / 3.0);
    float3 saturated = saturate(mix(gray, brightened, 1.0 + 0.4 * factor * mask));

    // --- Gloss highlight (subtle) ---
    float gloss = pow(saturate(1.0 - abs(uv.y - 0.5)), 6.0) * 0.03 * factor;
    saturated += gloss * mask;

    // --- Final mix ---
    float3 finalColor = mix(base, saturated, mask * factor);

    return float4(finalColor, 1.0);*/
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    // --- Base color ---
    /*float3 base = tex.sample(s, uv).rgb;

    // --- Distance masks ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    // Outer lips mask
    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    // Inner lips mask to exclude
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);

    // Subtract inner from outer
    float mask = max(outerMask - innerMask, 0.0);
    mask = pow(mask, 1.5); // smooth radial falloff

    // --- Factor ---
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    if (factor < 0.001) return float4(base, 1.0); // zero scaleFactor, return original

    // --- Saturation only ---
    float3 gray = float3((base.r + base.g + base.b) / 3.0);
    float3 saturated = saturate(mix(gray, base, 1.0 + 0.5 * factor * mask));

    // --- Final mix ---
    float3 finalColor = mix(base, saturated, mask * factor);

    return float4(finalColor, 1.0);*/
    
    /*float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    float3 base = texColor.rgb;

    // skip fully transparent pixels
    if (alpha < 0.01) return texColor;

    // --- Distance masks ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    // Outer lips mask
    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    // Inner lips mask to exclude
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);

    // Subtract inner from outer
    float mask = max(outerMask - innerMask, 0.0);
    mask = pow(mask, 1.5); // smooth radial falloff

    // --- Factor ---
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    if (factor < 0.001) return texColor; // zero scaleFactor, return original

    // --- Saturation only ---
    float3 gray = float3((base.r + base.g + base.b) / 3.0);
    float3 saturated = saturate(mix(gray, base, 1.0 + 0.5 * factor * mask));

    // --- Final mix ---
    float3 finalColor = mix(base, saturated, mask * factor);

    return float4(finalColor, alpha);*/
    
    /*float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    float3 base = texColor.rgb;

    if (alpha < 0.01) return texColor;

    // --- Distance masks ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
    float mask = max(outerMask - innerMask, 0.0);

    // Slightly feathered mask
    mask = pow(mask, 0.75); // soft edges

    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    if (factor < 0.001) return texColor;

    float depthFactor = 0.08;

    // --- Convert to HSL ---
    float3 hsl = rgb2hsl(base);

    // --- Linear effect for smooth slider ---
    float effect = factor * mask;

    // Smooth saturation increase
    hsl.y = clamp(hsl.y + (1.0 - hsl.y) * 0.1 * effect, 0.0, 1.0);

    // Smooth deepening
    hsl.z = clamp(hsl.z - hsl.z * depthFactor * effect, 0.0, 1.0);

    float3 deepColor = hsl2rgb(hsl);

    // --- Final blend ---
    float3 finalColor = mix(base, deepColor, effect);

    return float4(finalColor, alpha);*/
    
    /*float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    float3 base = texColor.rgb;

    if (alpha < 0.01) return texColor;

    // --- Distance masks ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
    float mask = max(outerMask - innerMask, 0.0);

    // Slightly feathered mask for smooth edges
    mask = pow(mask, 0.85); // soft edges but still strong in center

    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    if (factor < 0.001) return texColor;

    float depthFactor = 0.15; // subtle natural deepening

    // --- Convert to HSL ---
    float3 hsl = rgb2hsl(base);

    // --- Linear effect for smooth slider ---
    float effect = factor * mask;

    // Smooth saturation increase (gradual and natural)
    hsl.y = clamp(hsl.y + (1.0 - hsl.y) * 0.1 * effect, 0.0, 1.0);

    // Smooth deepening (gradual, proportional)
    hsl.z = clamp(hsl.z - hsl.z * depthFactor * effect, 0.0, 1.0);

    // Convert back to RGB
    float3 deepColor = hsl2rgb(hsl);

    // --- Final blend with linear interpolation ---
    float3 finalColor = mix(base, deepColor, effect);

    return float4(finalColor, alpha);*/
    
    /*float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    float3 base = texColor.rgb;

    if (alpha < 0.01) return texColor;

    // --- Distance masks for lip area ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    // Feather for smooth edges
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
    float mask = max(outerMask - innerMask, 0.0);
    mask = pow(mask, 0.85); // smooth edges

    // --- Scale factor normalized 0–100 ---
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    if (factor < 0.001) return texColor;

    // --- Compute per-pixel saturation ---
    float3 maxRGB = max(max(base.r, base.g), base.b);
    float3 minRGB = min(min(base.r, base.g), base.b);
    float3 saturation = (maxRGB - minRGB);

    // --- Calculate proportional boost for low-saturation pixels ---
    float3 satBoost = (1.0 - saturation) * 0.4 * factor; // adjust 0.4 for strength

    // --- Apply proportional saturation boost ---
    float3 enhanced = base + (base - float3((base.r + base.g + base.b)/3.0)) * satBoost;

    // Clamp enhanced color
    enhanced = clamp(enhanced, 0.0, 1.0);

    // --- Final blend with feathered mask ---
    float3 finalColor = mix(base, enhanced, mask);

    return float4(finalColor, alpha);*/
    
    /*float4 texColor = tex.sample(s, uv);
    float alpha = texColor.a;
    float3 base = texColor.rgb;

    if (alpha < 0.01) return texColor;

    // --- Distance masks for lip area ---
    float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

    // Feather for smooth edges
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
    float mask = max(outerMask - innerMask, 0.0);
    mask = pow(mask, 0.85); // smooth edges

    // --- Scale factor normalized 0–100 ---
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    if (factor < 0.001) return texColor;

    // --- Vibrance enhancement ---
    float3 maxRGB = max(max(base.r, base.g), base.b);
    float3 minRGB = min(min(base.r, base.g), base.b);
    float3 saturation = maxRGB - minRGB;

    float3 satBoost = (1.0 - saturation) * 0.4 * factor; // proportional to low saturation
    float3 enhanced = base + (base - float3((base.r + base.g + base.b)/3.0)) * satBoost;
    enhanced = clamp(enhanced, 0.0, 1.0);

    // --- Subtle Gaussian blur 3x3 to smooth vibrance ---
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

    // Mix original enhanced color with blurred version for smoothness
    enhanced = mix(enhanced, blur, 0.3); // adjust 0.3 for blur strength

    // --- Final blend with feathered mask ---
    float3 finalColor = mix(base, enhanced, mask);

    return float4(finalColor, alpha);*/
     
     float4 texColor = tex.sample(s, uv);
        float alpha = texColor.a;
        float3 base = texColor.rgb;

        if (alpha < 0.01) return texColor;

        // --- Distance masks for lip area ---
        float dOuter = signedDistancePolygon(uv, outerPoints, outerCount);
        float dInner = signedDistancePolygon(uv, innerPoints, innerCount);

        // Feather for smooth edges
        float minFeather = 0.003;
        float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
        float feather = max(0.012 * verticalFactor, minFeather);

        float outerMask = 1.0 - smoothstep(-feather, feather, dOuter);
        float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
        float mask = max(outerMask - innerMask, 0.0);
        mask = pow(mask, 0.85); // smooth edges

        // --- Scale factor normalized 0–100 ---
        float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
        if (factor < 0.001) return texColor;

        // --- Vibrance enhancement ---
        float3 maxRGB = max(max(base.r, base.g), base.b);
        float3 minRGB = min(min(base.r, base.g), base.b);
        float3 saturation = maxRGB - minRGB;

        float3 satBoost = (1.0 - saturation) * 0.5 * factor; // proportional to low saturation
        float3 enhanced = base + (base - float3((base.r + base.g + base.b)/3.0)) * satBoost;
        enhanced = clamp(enhanced, 0.0, 1.0);

        // --- Subtle Gaussian blur 3x3 to smooth vibrance ---
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

        // Mix original enhanced color with blurred version for smoothness
        enhanced = mix(enhanced, blur, 0.5); // adjust 0.3 for blur strength

        // --- Final blend with feathered mask ---
        float3 finalColor = mix(base, enhanced, mask);

        return float4(finalColor, alpha);

  
}


float3 rgb2hsl12(float3 color) {
    float3 rgb = saturate(color);
    
    float MIN = min(min(rgb.r, rgb.g), rgb.b);
    float MAX = max(max(rgb.r, rgb.g), rgb.b);
    float delta = MAX - MIN;
    
    // Lightness
    float l = (MAX + MIN) / 2.0;
    
    // Saturation
    float s = 0.0;
    if (delta > 1e-6) {
        s = (l < 0.5) ? (delta / (MAX + MIN)) : (delta / (2.0 - MAX - MIN));
    }
    
    // Hue
    float h = 0.0;
    if (delta > 1e-6) {
        if (MAX == rgb.r) {
            h = (rgb.g - rgb.b) / delta;
            if (h < 0.0) h += 6.0;
        } else if (MAX == rgb.g) {
            h = 2.0 + (rgb.b - rgb.r) / delta;
        } else {
            h = 4.0 + (rgb.r - rgb.g) / delta;
        }
        h /= 6.0; // Convert to 0-1 range
    }
    
    return float3(h, s, l);
}

float3 hsl2rgb12(float3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;
    
    float r, g, b;
    
    if (s < 1e-6) {
        r = g = b = l; // Grayscale
    } else {
        float q = (l < 0.5) ? l * (1.0 + s) : l + s - l * s;
        float p = 2.0 * l - q;
        
        r = hue2rgb(p, q, h + 1.0/3.0);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1.0/3.0);
    }
    
    return float3(r, g, b);
}

/*inline float distanceToSegment(float2 p, float2 v, float2 w) {
    float2 vw = w - v;
    float l2 = dot(vw, vw);
    if (l2 == 0.0) return distance(p, v);
    float t = clamp(dot(p - v, vw) / l2, 0.0, 1.0);
    float2 projection = v + t * vw;
    return distance(p, projection);
}

inline float signedDistancePolygon(float2 p, device const float2* points, uint count) {
    float d = distance(p, points[0]);
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        d = min(d, distanceToSegment(p, pi, pj));
        if (((pi.y > p.y) != (pj.y > p.y)) &&
            (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x)) {
            inside = !inside;
        }
    }
    return inside ? -d : d;
}*/

inline float3 softLight(float3 base, float3 blend, float mask)
{
    float3 result;
    for (int i = 0; i < 3; i++)
    {
        if (blend[i] < 0.5)
            result[i] = base[i] - (1.0 - 2.0 * blend[i]) * base[i] * (1.0 - base[i]);
        else
            result[i] = base[i] + (2.0 * blend[i] - 1.0) * (sqrt(base[i]) - base[i]);
    }
    return mix(base, result, mask);
}

// --- Utility: RGB -> XYZ
// --- Helpers ---
inline float toLinear(float v) {
    return (v <= 0.04045) ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4);
}

inline float toGamma(float v) {
    return (v <= 0.0031308) ? 12.92 * v : 1.055 * pow(v, 1.0/2.4) - 0.055;
}

inline float fLab(float t) {
    return (t > 0.008856) ? pow(t, 1.0/3.0) : (7.787 * t + 16.0/116.0);
}

inline float fInvLab(float t) {
    float t3 = t * t * t;
    return (t3 > 0.008856) ? t3 : (t - 16.0/116.0) / 7.787;
}

// --- RGB -> XYZ ---
inline float3 rgb2xyz(float3 c) {
    float3 rgb = float3(toLinear(c.r), toLinear(c.g), toLinear(c.b));

    float x = rgb.r * 0.4124564 + rgb.g * 0.3575761 + rgb.b * 0.1804375;
    float y = rgb.r * 0.2126729 + rgb.g * 0.7151522 + rgb.b * 0.0721750;
    float z = rgb.r * 0.0193339 + rgb.g * 0.1191920 + rgb.b * 0.9503041;

    return float3(x, y, z);
}

// --- XYZ -> Lab ---
inline float3 xyz2lab(float3 xyz) {
    float3 ref = float3(0.95047, 1.0, 1.08883);
    float3 v = xyz / ref;

    float fx = fLab(v.x);
    float fy = fLab(v.y);
    float fz = fLab(v.z);

    float L = (116.0 * fy) - 16.0;
    float a = 500.0 * (fx - fy);
    float b = 200.0 * (fy - fz);

    return float3(L, a, b);
}

// --- Lab -> XYZ ---
inline float3 lab2xyz(float3 lab) {
    float fy = (lab.x + 16.0) / 116.0;
    float fx = fy + lab.y / 500.0;
    float fz = fy - lab.z / 200.0;

    float3 ref = float3(0.95047, 1.0, 1.08883);
    float3 xyz = float3(fInvLab(fx), fInvLab(fy), fInvLab(fz)) * ref;

    return xyz;
}

// --- XYZ -> RGB ---
inline float3 xyz2rgb(float3 xyz) {
    float r = xyz.x *  3.2404542 + xyz.y * -1.5371385 + xyz.z * -0.4985314;
    float g = xyz.x * -0.9692660 + xyz.y *  1.8760108 + xyz.z *  0.0415560;
    float b = xyz.x *  0.0556434 + xyz.y * -0.2040259 + xyz.z *  1.0572252;

    return float3(toGamma(r), toGamma(g), toGamma(b));
}

// --- Main wrappers ---
 float3 rgb2lab(float3 rgb) {
    return xyz2lab(rgb2xyz(rgb));
}

 float3 lab2rgb(float3 lab) {
    return xyz2rgb(lab2xyz(lab));
}


// --- Inner Lips Teeth Whitening Only ---
/*fragment float4 lipsEffectShader(VertexOut in [[stage_in]],
                                 texture2d<float> tex [[texture(0)]],
                                 device const float2 *outerPoints [[buffer(0)]],
                                 constant uint &outerCount [[buffer(1)]],
                                 device const float2 *innerPoints [[buffer(2)]],
                                 constant uint &innerCount [[buffer(3)]],
                                 constant float &scaleFactor [[buffer(4)]]) {

    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
       float2 uv = in.textureCoordinate;

       float4 color = tex.sample(s, uv);

       // --- Inner lips mask ---
       float dInner = signedDistancePolygon(uv, innerPoints, innerCount);
       float minFeather = 0.003;
       float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
       float feather = max(0.012 * verticalFactor, minFeather);
       float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
       innerMask = smoothstep(0.05, 0.98, innerMask);

       float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);

       if (innerMask > 0.01 && factor > 0.001) {
           float3 c = color.rgb;

           // Convert to HSL
           float3 hsl = rgb2hsl12(c);

           if (hsl.x < 0.05 || hsl.x > 0.75) {
               hsl.z *= (1.0 + 0.06 * factor);        // slight lightness up
               c = ((c - 0.5) * (1.0 + 0.02 * factor)) + 0.5; // contrast boost
               hsl.y *= (1.0 - (factor * 0.1));       // slight saturation reduce
               c = hsl2rgb(hsl);
               c.b *= (1.0 + 0.04 * factor);          // subtle blue boost
               c = clamp(c, 0.0, 1.0);
           } else {
               hsl.z *= (1.0 + 0.15 * factor);        // more lightness
               c = ((c - 0.5) * (1.0 + 0.1 * factor)) + 0.5;  // contrast
               hsl.y *= (1.0 - (factor * 0.3));       // reduce saturation
               c = hsl2rgb12(hsl);
               c.b *= (1.0 + 0.06 * factor);          // subtle blue boost
               c = clamp(c, 0.0, 1.0);
           }

           // Mix with base color using mask
           c = mix(color.rgb, c, innerMask);
           return float4(c, color.a);
       }

       return color;*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    float4 color = tex.sample(s, uv);

    // --- Inner lips mask ---
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
    innerMask = smoothstep(0.05, 0.95, innerMask);

    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);

    if (innerMask > 0.01 && factor > 0.001) {
        float3 c = color.rgb;

        // Convert to HSL
        float3 hsl = rgb2hsl12(c);

        if (hsl.x < 0.05 || hsl.x > 0.75) {
            // yellowish
            hsl.z *= (1.0 + 0.06 * factor);
            hsl.y *= (1.0 - (0.1 * factor));
            c = hsl2rgb12(hsl);
            c = ((c - 0.5) * (1.0 + 0.02 * factor)) + 0.5;
            c.b *= (1.0 + 0.04 * factor);
        } else {
            // neutral/gray
            hsl.z *= (1.0 + 0.15 * factor);
            hsl.y *= (1.0 - (0.3 * factor));
            c = hsl2rgb12(hsl);
            c = ((c - 0.5) * (1.0 + 0.1 * factor)) + 0.5;
            c.b *= (1.0 + 0.06 * factor);
        }

        // Clamp after operations
        c = clamp(c, 0.0, 1.0);

        // --- Natural blending ---
        float maskSoft = pow(innerMask, 1.0);                   // soften mask edge
        float lum = dot(color.rgb, float3(0.299, 0.587, 0.114)); // original brightness
        float detailPreserve = 0.5 + 0.5 * lum;                  // brighter teeth get less overwrite
        float3 blended = mix(color.rgb, c, maskSoft * detailPreserve);

        return float4(blended, color.a);
    }

    return color;*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;

    // --- Base color ---
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;

    // --- Teeth mask ---
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
    innerMask = smoothstep(0.05, 0.98, innerMask);

    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);

    if (innerMask > 0.01 && factor > 0.001)
    {
        float3 c = base;
        float3 hsl = rgb2hsl12(c);

        // Whitening logic
        if (hsl.x < 0.05 || hsl.x > 0.85)
        {
            // yellowish teeth
            hsl.z *= (1.0 + 0.06 * factor);        // brighten
            hsl.y *= (1.0 - 0.1 * factor);         // slightly desaturate
            c = hsl2rgb12(hsl);
            c = ((c - 0.5) * (1.0 + 0.02 * factor)) + 0.5; // contrast boost
            c.b *= (1.0 + 0.05 * factor);          // subtle blue boost
        }
        else
        {
            // neutral/gray teeth
            hsl.z *= (1.0 + 0.15 * factor);
            hsl.y *= (1.0 - 0.3 * factor);
            c = hsl2rgb12(hsl);
            c = ((c - 0.5) * (1.0 + 0.1 * factor)) + 0.5;
            c.b *= (1.0 + 0.08 * factor);
        }

        c = clamp(c, 0.0, 1.0);

        // --- Apply directly with mask ---
        float maskSoft = innerMask; // linear blending, no soft-light
        float3 blended = mix(base, c, maskSoft);

        return float4(blended, color.a);
    }

    // fallback: original color
    return color;*/
    
     /*float2 uv = in.textureCoordinate;
      float4 color = tex.sample(s, uv);
      float3 base = color.rgb;

      // --- Teeth mask ---
      float dInner = signedDistancePolygon(uv, innerPoints, innerCount);
      float minFeather = 0.003;
      float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
      float feather = max(0.012 * verticalFactor, minFeather);
      float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
      innerMask = smoothstep(0.05, 0.98, innerMask);

      float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    
    float3 lab = rgb2lab(base);
    bool isTeeth = (lab.x > 15.0) && (lab.y < 15.0) && (lab.z > 0.0);
    //bool isTeeth = (lab.x > 55.0 && lab.x < 95.0) &&    // lightness 55~95
                    //(lab.y > -10.0 && lab.y < 15.0) &&  // a* small, not red/pink
                    //(lab.z > 0.0 && lab.z < 40.0);      // b* yellowish
    
    bool isNotGumTongue = (base.r - base.g > 0.1); // teeth less red than tongue
    //isTeeth = isTeeth && isNotGumTongue;

    if (innerMask > 0.01 && factor > 0.001 && isTeeth) {
        float3 lab = rgb2lab(base);

        // Whitening adjustments
        lab.x += 6.0 * factor;          // brighten L
        lab.y *= (1.0 - 0.35 * factor); // mild a* reduction
        if (lab.z > 0.0) {
            lab.z *= (1.0 - 1.0 * factor);
        } else {
            lab.z *= (1.0 - 0.55 * factor); // normal mild reduction
        }
       // lab.z *= (1.0 - 0.75 * factor);  // mild b* reduction

        float3 c = lab2rgb(lab);
        c = clamp(c, 0.0, 1.0);

        // Preserve details
        float3 detail = base - c;
        c += detail * (0.4 * (1.0 - factor));

        // Subtle blue boost
        c.b *= (1.0 + 0.03 * factor);

        // Masked blend
        float3 blended = base + (c - base) * innerMask;
        return float4(blended, color.a);
    }

      return color;*/
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;
    
    // --- Teeth mask ---
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
    innerMask = smoothstep(0.05, 0.98, innerMask);
    
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    
    // --- Lab conversion ---
    float3 lab = rgb2lab(base);
    
    // Teeth color heuristic: L, a, b ranges
    bool isTeeth = (lab.x > 15.0) && (lab.y < 20.0) && (lab.z > -5.0);*/
    
    /*if (innerMask > 0.01 && factor > 0.001 && isTeeth) {
        
        // Adaptive yellow correction
        float yellowFactor = clamp((lab.z - 5.0)/50.0, 0.0, 1.0);
        lab.z -= yellowFactor * 10.0 * factor;  // reduce yellow proportionally
        
        // Whitening adjustments
        lab.x += 8.0 * factor;           // brighten L
        lab.y *= (1.0 - 0.5 * factor);  // mild a* reduction
        
        // Convert back to RGB
        float3 c = lab2rgb(lab);
        c = clamp(c, 0.0, 1.0);
        
        // Preserve details
        float3 detail = base - c;
        c += detail * (0.5 * (1.0 - factor));
        
        // Subtle blue boost
        c.b *= (1.0 + 0.12 * factor);
        
        // Masked blend
        float3 blended = base + (c - base) * innerMask;
        return float4(blended, color.a);
    }*/
    
    // fallback: original color
    //return color;
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;

    // --- Teeth mask ---
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    // Base inner mask
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
    innerMask = smoothstep(0.05, 0.98, innerMask);

    // Dynamic feather smoothing
    float dynamicFeather = feather * (0.6 + 0.4 * innerMask);
    innerMask = 1.0 - smoothstep(-dynamicFeather, dynamicFeather, dInner);

    // Factor scaling
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);

    // --- Lab conversion ---
    float3 lab = rgb2lab(base);

    // Teeth detection (relaxed)
    bool isTeeth = (lab.x > 15.0) && (lab.y < 20.0) && (lab.z > -5.0);

    if (innerMask > 0.01 && factor > 0.001 && isTeeth) {

        // --- Adaptive yellow correction ---
        float yellowFactor = smoothstep(0.0, 50.0, lab.z);
        lab.z -= yellowFactor * (10.0 * factor);  // reduce yellow proportionally
        
       // float yellowFactor = clamp((lab.z - 5.0)/50.0, 0.0, 1.0);
       // lab.z -= yellowFactor * 10.0 * factor;

        // --- Whitening adjustments ---
        lab.x += 8.0 * factor;           // brighten L
        lab.y *= (1.0 - 0.5 * factor);  // mild a* reduction

        // Convert back to RGB
        float3 c = lab2rgb(lab);
        c = clamp(c, 0.0, 1.0);

        // --- Detail preservation (high-pass) ---
        float3 blur = base; // simple placeholder; replace with actual 3x3 blur if needed
        float3 detail = base - blur;
        c += detail * 0.8;

        // --- Subtle saturation control ---
        float3 hsl = rgb2hsl(c);
        hsl.y *= (1.0 - 0.3 * factor); // slight desaturation
        c = hsl2rgb(hsl);

        // --- Conditional blue boost ---
        if (lab.z > 5.0) {
            c.b *= (1.0 + 0.12 * factor);
        }

        // --- Masked blend ---
        float3 blended = base + (c - base) * innerMask;
        return float4(blended, color.a);
    }

    // fallback: original color
    return color;*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;

    // --- Teeth mask (polygon) ---
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    // Base mask
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
    innerMask = smoothstep(0.05, 0.98, innerMask);

    // Smooth mask edges
    float dynamicFeather = feather * (0.6 + 0.4 * innerMask);
    innerMask = 1.0 - smoothstep(-dynamicFeather, dynamicFeather, dInner);

    // --- Factor scaling ---
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);

    // --- Convert to Lab ---
    float3 lab = rgb2lab(base);

    // --- Teeth color heuristic inside mask ---
    bool isTeeth = (lab.x > 15.0) && (lab.y < 20.0) && (lab.z > -10.0 && lab.z < 40.0);

    // Apply factor only if inside mask AND detected as teeth
    float applyFactor = factor * innerMask * float(isTeeth);

    if (applyFactor > 0.001) {

        // --- Adaptive yellow correction ---
        float yellowFactor = smoothstep(0.0, 50.0, lab.z);
        lab.z -= yellowFactor * (10.0 * applyFactor);

        // --- Whitening adjustments ---
        lab.x += 8.0 * applyFactor;         // brighten L
        lab.y *= (1.0 - 0.5 * applyFactor); // mild a* reduction

        // --- Convert back to RGB ---
        float3 c = lab2rgb(lab);
        c = clamp(c, 0.0, 1.0);

        // --- Detail preservation ---
        float3 blur = base; // replace with small GPU blur for real texture preservation
        float3 detail = base - blur;
        c += detail * 0.8;

        // --- Subtle saturation control ---
        float3 hsl = rgb2hsl(c);
        hsl.y *= (1.0 - 0.5 * applyFactor);
        c = hsl2rgb(hsl);

        // --- Conditional blue boost for yellow teeth ---
        if (lab.z > 5.0) {
            c.b *= (1.0 + 0.12 * applyFactor);
        }

        // --- Masked blend ---
        float3 blended = base + (c - base) * applyFactor;
        return float4(blended, color.a);
    }

    // fallback: original color
    return color;*/
    
    /*constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.textureCoordinate;
    float4 color = tex.sample(s, uv);
    float3 base = color.rgb;

    // --- Teeth mask (polygon) ---
    float dInner = signedDistancePolygon(uv, innerPoints, innerCount);
    float minFeather = 0.003;
    float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
    float feather = max(0.012 * verticalFactor, minFeather);

    // Base mask
    float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
    innerMask = smoothstep(0.05, 0.98, innerMask);

    // Smooth mask edges & clamp
    float dynamicFeather = feather * (0.6 + 0.4 * innerMask);
    innerMask = 1.0 - smoothstep(-dynamicFeather, dynamicFeather, dInner);
    innerMask = clamp(innerMask, 0.0, 1.0);
    innerMask = smoothstep(0.1, 0.95, innerMask);

    // --- Factor scaling ---
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);

    // --- Convert to Lab ---
    float3 lab = rgb2lab(base);

    // --- Teeth color heuristic inside mask ---
    bool isTeeth = (lab.x > 15.0) && (lab.y < 20.0) && (lab.z > -15.0);

    // Apply factor only if inside mask AND detected as teeth
    float applyFactor = factor * innerMask * float(isTeeth);

    if (applyFactor > 0.001) {

        // --- Adaptive yellow + brightness correction ---
        float brightnessFactor = clamp((lab.x - 15.0)/30.0, 0.0, 1.0); // darker teeth get stronger whitening
        float yellowFactor = smoothstep(0.0, 50.0, lab.z) * brightnessFactor;
        lab.z -= yellowFactor * (15.0 * applyFactor);

        // --- Whitening adjustments ---
        float whitenFactor = (100.0 - lab.x) / 100.0; // darker teeth get stronger boost
        lab.x += 10.0 * applyFactor * whitenFactor;        // brighten L
        lab.y *= (1.0 - 0.5 * applyFactor); // mild a* reduction

        // --- Convert back to RGB ---
        float3 c = lab2rgb(lab);
        c = clamp(c, 0.0, 1.0);

        // --- Detail preservation ---
        // Replace this with a small GPU blur for real texture preservation
        float3 blur = base;
        float3 detail = base - blur;
        c += detail * 0.5;
        c = clamp(c, 0.0, 1.0);

        // --- Saturation control ---
        float3 hsl = rgb2hsl(c);
        hsl.y *= (1.0 - 0.2 * applyFactor); // slight desaturation for natural teeth
        c = hsl2rgb(hsl);
        c = clamp(c, 0.0, 1.0);

        // --- Conditional blue boost for yellow teeth ---
        if (lab.z > 5.0) {
            c.b *= (1.0 + 0.15 * applyFactor);
        }
        
        c = clamp(c, 0.0, 1.0);

        // --- Masked blend ---
        float3 blended = base + (c - base) * applyFactor;
        return float4(blended, color.a);
    }

    // fallback: original color
    return color;
}*/

/*
 constexpr sampler s(address::clamp_to_edge, filter::linear);
 float2 uv = in.textureCoordinate;
 float4 color = tex.sample(s, uv);
 float3 base = color.rgb;

 // --- Teeth mask (polygon) ---
 float dInner = signedDistancePolygon(uv, innerPoints, innerCount);
 float minFeather = 0.003;
 float verticalFactor = 1.0 - abs(uv.y - 0.5) * 2.0;
 float feather = max(0.012 * verticalFactor, minFeather);

 // Base mask
 float innerMask = 1.0 - smoothstep(-feather, feather, dInner);
 innerMask = smoothstep(0.05, 0.98, innerMask);

 // Smooth mask edges & clamp
 float dynamicFeather = feather * (0.6 + 0.4 * innerMask);
 innerMask = 1.0 - smoothstep(-dynamicFeather, dynamicFeather, dInner);
 innerMask = clamp(innerMask, 0.0, 1.0);
 innerMask = smoothstep(0.1, 0.95, innerMask);

 // --- Factor scaling ---
 float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);

 // --- Convert to Lab ---
 float3 lab = rgb2lab(base);

 // --- Teeth color heuristic inside mask ---
 bool isTeeth = (lab.x > 15.0) && (lab.y < 20.0) && (lab.z > -10.0 && lab.z < 40.0);

 // Apply factor only if inside mask AND detected as teeth
 //float applyFactor = factor * innerMask * float(isTeeth);
 
 float scoreL = smoothstep(10.0, 90.0, lab.x);       // Teeth should be mid-to-bright
 float scoreA = 1.0 - smoothstep(10.0, 35.0, abs(lab.y)); // Suppress very red/green
 float scoreB = 1.0 - smoothstep(15.0, 70.0, lab.z);      // Suppress deep yellows

 float teethLikelihood = scoreL * scoreA * scoreB;
 float applyFactor = factor * innerMask * teethLikelihood;

 if (applyFactor > 0.001) {

     // --- Adaptive yellow + brightness correction ---
     float brightnessFactor = clamp((lab.x - 15.0)/40.0, 0.0, 1.0); // darker teeth get stronger whitening
     float yellowFactor = smoothstep(0.0, 50.0, lab.z) * brightnessFactor;
     lab.z -= yellowFactor * (10.0 * applyFactor);

     // --- Whitening adjustments ---
     lab.x += 8.0 * applyFactor;         // brighten L
     lab.y *= (1.0 - 0.5 * applyFactor); // mild a* reduction

     // --- Convert back to RGB ---
     float3 c = lab2rgb(lab);
     c = clamp(c, 0.0, 1.0);

     // --- Detail preservation ---
     // Replace this with a small GPU blur for real texture preservation
     float3 blur = base;
     float3 detail = base - blur;
     c += detail * 0.7;

     // --- Saturation control ---
     float3 hsl = rgb2hsl(c);
     hsl.y *= (1.0 - 0.3 * applyFactor); // slight desaturation for natural teeth
     c = hsl2rgb(hsl);

     // --- Conditional blue boost for yellow teeth ---
     if (lab.z > 5.0) {
         c.b *= (1.0 + 0.12 * applyFactor);
     }

     // --- Masked blend ---
     float3 blended = base + (c - base) * applyFactor;
     return float4(blended, color.a);
 }

 // fallback: original color
 return color;
 
 
 
 
 */
