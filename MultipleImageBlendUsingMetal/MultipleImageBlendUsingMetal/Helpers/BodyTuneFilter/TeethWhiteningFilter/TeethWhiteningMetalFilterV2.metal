//
//  TeethWhiteningMetalFilterV2.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 30/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

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
inline float3 rgb2lab(float3 rgb) {
    return xyz2lab(rgb2xyz(rgb));
}

inline float3 lab2rgb(float3 lab) {
    return xyz2rgb(lab2xyz(lab));
}

// --- Inner Lips Teeth Whitening Only ---
fragment float4 teethWhiteningShaderEffect(VertexOut in [[stage_in]],
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
}
