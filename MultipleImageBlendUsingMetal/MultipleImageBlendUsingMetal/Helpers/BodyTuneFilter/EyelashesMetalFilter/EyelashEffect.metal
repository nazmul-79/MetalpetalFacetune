//
//  Eyelashes.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 26/8/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

/*float eyelashMask(float2 uv, float2 eyeCenter, float2 eyeRadius) {
    float2 diff = (uv - eyeCenter) / eyeRadius;
    float dist = length(diff);
    return 1.0 - smoothstep(0.3, 1.0, dist); // 1.0=center, 0.0=edge
}

fragment float4 EyelashEffect(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              sampler textureSampler [[sampler(0)]],
                              constant float &effectFactor [[buffer(0)]],
                              constant float2 &leftEyeCenter [[buffer(1)]],
                              constant float2 &leftEyeRadius [[buffer(2)]],
                              constant float2 &rightEyeCenter [[buffer(3)]],
                              constant float2 &rightEyeRadius [[buffer(4)]]) {
    
    float2 uv = vert.textureCoordinate;
    float maskL = eyelashMask(uv, leftEyeCenter, leftEyeRadius);
    float maskR = eyelashMask(uv, rightEyeCenter, rightEyeRadius);
    float mask = max(maskL, maskR);

    float4 color = inputTexture.sample(textureSampler, uv);

    float factor = clamp(effectFactor / 100.0, -1.0, 1.0);
    if (factor > 0.0) {
        color.rgb = mix(color.rgb, color.rgb * 0.6, mask * factor); // darker
    } else {
        color.rgb = mix(color.rgb, color.rgb + (1.0 - color.rgb) * -factor, mask); // lighter
    }
    return color;
}
*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

float eyelashMask(float2 uv, float2 eyeCenter, float2 eyeRadius) {
    float2 diff = (uv - eyeCenter) / eyeRadius;
    float dist = length(diff);
    // soft gradient for subtle feel
    return smoothstep(1.0, 0.2, dist); // center=1, edge=0
}

fragment float4 EyelashEffect(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              sampler textureSampler [[sampler(0)]],
                              constant float &effectFactor [[buffer(0)]],
                              constant float2 &leftEyeCenter [[buffer(1)]],
                              constant float2 &leftEyeRadius [[buffer(2)]],
                              constant float2 &rightEyeCenter [[buffer(3)]],
                              constant float2 &rightEyeRadius [[buffer(4)]]) {
    
    float2 uv = vert.textureCoordinate;
    float maskL = eyelashMask(uv, leftEyeCenter, leftEyeRadius);
    float maskR = eyelashMask(uv, rightEyeCenter, rightEyeRadius);
    float mask = max(maskL, maskR);

    float4 color = inputTexture.sample(textureSampler, uv);

    // normalize factor -1..1
    float factor = clamp(effectFactor / 100.0, -1.0, 1.0);

    // scale mask to be softer (gradient feel)
    float smoothMask = mask * 0.8; // max 60% effect

    if (factor > 0.0) {
        // darker lashes
        color.rgb = mix(color.rgb, color.rgb * 0.8, smoothMask * factor);
    } else if (factor < 0.0) {
        // lighter lashes, clamp to avoid >1
        float3 lighten = (1.0 - color.rgb) * smoothMask * (-factor);
        color.rgb = min(color.rgb + lighten, float3(1.0));
    }

    return color;
}

*/

/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

float eyelashBorder(float2 uv, float2 eyeCenter, float2 eyeRadius, float borderWidth) {
    float2 diff = (uv - eyeCenter) / eyeRadius;
    float dist = length(diff);
    
    // Create a ring/border effect around the eye
    float innerRadius = 0.8;  // Inner edge of the border
    float outerRadius = innerRadius + borderWidth;  // Outer edge of the border
    
    // Smooth step for the border
    float border = smoothstep(innerRadius, innerRadius + 0.05, dist) *
                   (1.0 - smoothstep(outerRadius - 0.05, outerRadius, dist));
    
    return border;
}

fragment float4 EyelashEffect(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              sampler textureSampler [[sampler(0)]],
                              constant float &effectFactor [[buffer(0)]],
                              constant float2 &leftEyeCenter [[buffer(1)]],
                              constant float2 &leftEyeRadius [[buffer(2)]],
                              constant float2 &rightEyeCenter [[buffer(3)]],
                              constant float2 &rightEyeRadius [[buffer(4)]]) {
    
    float2 uv = vert.textureCoordinate;
    
    // Border width relative to eye size
    float borderWidth = 0.15;
    
    float maskL = eyelashBorder(uv, leftEyeCenter, leftEyeRadius, borderWidth);
    float maskR = eyelashBorder(uv, rightEyeCenter, rightEyeRadius, borderWidth);
    float mask = max(maskL, maskR);

    float4 color = inputTexture.sample(textureSampler, uv);

    // Normalize factor -1..1
    float factor = clamp(effectFactor / 100.0, -1.0, 1.0);

    if (factor > 0.0) {
        // Darker border (eyelash effect)
        color.rgb = mix(color.rgb, color.rgb * 0.5, mask * factor);
    } else if (factor < 0.0) {
        // Lighter border (for testing or alternative looks)
        float3 lighten = (1.0 - color.rgb) * mask * (-factor);
        color.rgb = min(color.rgb + lighten, float3(1.0));
    }

    return color;
}
*/

/*#include <metal_stdlib>
using namespace metalpetal;

fragment float4 EyelashEffect(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              sampler textureSampler [[sampler(0)]],
                              constant float &effectFactor [[buffer(0)]],
                              constant float2 &leftEyeCenter [[buffer(1)]],
                              constant float2 &leftEyeRadius [[buffer(2)]],
                              constant float2 &rightEyeCenter [[buffer(3)]],
                              constant float2 &rightEyeRadius [[buffer(4)]]) {

    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(textureSampler, uv);
    
    float factor = clamp(effectFactor / 100.0, -1.0, 1.0);

    // --- LEFT EYE OFFSET (10px approx using eyeRadius) ---
    float2 offsetL = float2(0.01, 0.0); // 0.05 = 10px approx assuming normalized coords
    float2 diffL = (uv - leftEyeCenter + offsetL) / leftEyeRadius;
    diffL.y *= 0.8; // slim vertically
    float distL = length(diffL);
    float ellipseMaskL = smoothstep(1.15, 0.7, distL);
    ellipseMaskL = pow(ellipseMaskL, 0.8);

    float upperMaskL = smoothstep(0.0, 1.0, diffL.y) * ellipseMaskL;
    float lowerMaskL = smoothstep(0.0, 1.0, -diffL.y) * ellipseMaskL;

    // --- RIGHT EYE OFFSET (10px approx using eyeRadius) ---
    float2 offsetR = float2(-0.01, 0.0); // 0.05 = 10px approx
    float2 diffR = (uv - rightEyeCenter + offsetR) / rightEyeRadius;
    diffR.y *= 0.8;
    float distR = length(diffR);
    float ellipseMaskR = smoothstep(1.15, 0.7, distR);
    ellipseMaskR = pow(ellipseMaskR, 0.8);

    float upperMaskR = smoothstep(0.0, 0.75, diffR.y) * ellipseMaskR;
    float lowerMaskR = smoothstep(0.0, 1.0, -diffR.y) * ellipseMaskR;

    // Combine masks
    float upperMask = max(upperMaskL, upperMaskR) * factor;
    float lowerMask = max(lowerMaskL, lowerMaskR) * factor;

    // Colors
    float3 upperColor = float3(0.05, 0.01, 0.06);
    float3 lowerColor = float3(0.05, 0.02, 0.06);

    // Apply overlay
    if (factor >= 0.0) {
        color.rgb = mix(color.rgb, upperColor, upperMask);
        color.rgb = mix(color.rgb, lowerColor, lowerMask);
    } else {
        color.rgb = mix(color.rgb, color.rgb + (1.0 - color.rgb) * (-upperMask), upperMask);
        color.rgb = mix(color.rgb, color.rgb + (1.0 - color.rgb) * (-lowerMask), lowerMask);
    }

    return color;
}
*/

////Final Effect

fragment float4 EyelashEffect(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              sampler textureSampler [[sampler(0)]],
                              constant float &effectFactor [[buffer(0)]],
                              constant float2 &leftEyeCenter [[buffer(1)]],
                              constant float2 &leftEyeRadius [[buffer(2)]],
                              constant float2 &rightEyeCenter [[buffer(3)]],
                              constant float2 &rightEyeRadius [[buffer(4)]]) {

    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(textureSampler, uv);
    
    float factor = clamp(effectFactor / 100.0, -1.0, 1.0);
    
    float positiveIntensity = 0.25;
    float negativeIntensity = 0.4;

    // --- LEFT EYE OFFSET ---
    float2 offsetL = float2(0.01, 0.0); // slight left shift
    float2 diffL = (uv - leftEyeCenter + offsetL) / leftEyeRadius;
    diffL.y *= 0.6; // slim vertically
    float distL = length(diffL);
    float ellipseMaskL = smoothstep(1.15, 0.6, distL);
    ellipseMaskL = pow(ellipseMaskL, 1.5); // stronger mask for positive effect

    float upperMaskL = smoothstep(0.1, 0.7, diffL.y) * ellipseMaskL;
    float lowerMaskL = smoothstep(0.1, 0.7, -diffL.y) * ellipseMaskL;

    // --- RIGHT EYE OFFSET ---
    float2 offsetR = float2(-0.01, 0.0); // slight right shift
    float2 diffR = (uv - rightEyeCenter + offsetR) / rightEyeRadius;
    diffR.y *= 0.6;
    float distR = length(diffR);
    float ellipseMaskR = smoothstep(1.15, 0.6, distR);
    ellipseMaskR = pow(ellipseMaskR, 1.5);

    float upperMaskR = smoothstep(0.0, 0.6, diffR.y) * ellipseMaskR;
    float lowerMaskR = smoothstep(0.0, 0.65, -diffR.y) * ellipseMaskR;

    // Combine masks with different intensity based on effect direction
       float intensityMultiplier = (factor > 0.0) ? positiveIntensity : negativeIntensity;
       float upperMask = max(upperMaskL, upperMaskR) * abs(factor) * intensityMultiplier;
       float lowerMask = max(lowerMaskL, lowerMaskR) * abs(factor) * intensityMultiplier * 0.8; // Lower lashes even more subtle

    // Natural lash colors (slightly varied for more realism)
    float3 upperColor = float3(0.07, 0.035, 0.012);
    float3 lowerColor = float3(0.06, 0.03, 0.01);

    // Apply overlay
    if (factor >= 0.0) {
        color.rgb = mix(color.rgb, upperColor, upperMask);
        color.rgb = mix(color.rgb, lowerColor, lowerMask);
    } else {
        color.rgb = mix(color.rgb, color.rgb + (1.0 - color.rgb) * (-upperMask), upperMask);
        color.rgb = mix(color.rgb, color.rgb + (1.0 - color.rgb) * (-lowerMask), lowerMask);
    }

    return color;
}

/*#include <metal_stdlib>
using namespace metalpetal;

fragment float4 EyelashEffect(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              sampler textureSampler [[sampler(0)]],
                              constant float &effectFactor [[buffer(0)]],
                              constant float2 &leftEyeCenter [[buffer(1)]],
                              constant float2 &leftEyeRadius [[buffer(2)]],
                              constant float2 &rightEyeCenter [[buffer(3)]],
                              constant float2 &rightEyeRadius [[buffer(4)]]) {

    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(textureSampler, uv);
    
    float factor = clamp(effectFactor / 100.0, -1.0, 1.0);
    if (factor == 0.0) return color;

    // Create eye masks
    float leftEyeMask = 0.0;
    float rightEyeMask = 0.0;
    float2 offsetL = float2(0.01, 0.0); // slight left shift
    float2 offsetR = float2(-0.01, 0.0); // slight left shift
    // Left eye area
    float2 diffL = (uv - leftEyeCenter + offsetL) / leftEyeRadius;
    float distL = length(diffL);
    leftEyeMask = 1.0 - smoothstep(0.7, 1.1, distL);
    
    // Right eye area
    float2 diffR = (uv - rightEyeCenter + offsetR) / rightEyeRadius;
    float distR = length(diffR);
    rightEyeMask = 1.0 - smoothstep(0.7, 1.1, distR);
    
    // Combine masks
    float eyeMask = max(leftEyeMask, rightEyeMask) * abs(factor);
    
    if (eyeMask > 0.0) {
        // Calculate luminance
        float luminance = dot(color.rgb, float3(0.07, 0.035, 0.012));
        
        if (factor > 0.0) {
            // Positive factor: Increase contrast and saturation
            float contrast = 1.0 + (factor); // Increase contrast up to 1.8x
            float3 contrasted = ((color.rgb - luminance) * contrast + luminance);
            
            // Increase saturation
            float3 saturated = mix(float3(luminance), contrasted, 1.0 + factor * 0.3);
            
            // Blend with original based on mask
            color.rgb = mix(color.rgb, saturated, eyeMask);
            
//            // Iris-specific enhancement
//            float irisMask = eyeMask * (1.0 - smoothstep(0.3, 0.7, distL + distR));
//            if (irisMask > 0.0) {
//                float3 irisEnhanced = color.rgb * float3(1.05, 1.05, 1.0);
//                color.rgb = mix(color.rgb, irisEnhanced, irisMask * 0.5);
//            }
        } else {
            // Negative factor: Decrease contrast and saturation
            float contrast = 1.0 - (abs(factor) * 0.5); // Decrease contrast down to 0.5x
            float3 contrasted = ((color.rgb - luminance) * contrast + luminance);
            
            // Decrease saturation
            float3 desaturated = mix(float3(luminance), contrasted, 1.0 - abs(factor) * 0.4);
            
            // Blend with original based on mask
            color.rgb = mix(color.rgb, desaturated, eyeMask);
        }
    }
    
    return color;
}*/



/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

// Eye orientation (approximation)
float calculateEyeAngle(float2 eyeRadius) {
    return (eyeRadius.x > eyeRadius.y) ? 0.0 : M_PI_F / 2.0;
}

// Directional eyelash pattern (noise-based)
float eyelashPattern(float2 uv, float2 eyeCenter, float2 eyeRadius) {
    float angle = calculateEyeAngle(eyeRadius);
    float2 dir = normalize(uv - eyeCenter);
    float2 rotatedUV;
    float cosA = cos(angle);
    float sinA = sin(angle);
    
    rotatedUV.x = dir.x * cosA - dir.y * sinA;
    rotatedUV.y = dir.x * sinA + dir.y * cosA;
    
    float2 patternUV = rotatedUV * float2(20.0, 50.0);
    float noise = fract(sin(dot(patternUV, float2(12.9898,78.233))) * 43758.5453);
    
    // Smooth pattern for lashes
    return smoothstep(0.45, 0.75, noise);
}

// Hollow ring mask for eyelash border
float eyelashEdgeMask(float2 uv, float2 eyeCenter, float2 eyeRadius) {
    float2 diff = (uv - eyeCenter) / eyeRadius;
    float dist = length(diff);

    float innerRadius = 0.88; // inside clean
    float outerRadius = 1.0;  // edge

    // Hollow ring mask
    float mask = smoothstep(innerRadius, outerRadius, dist) *
                 (1.0 - smoothstep(innerRadius, outerRadius, dist));

    // soft gradient
    return pow(mask, 0.6);
}

fragment float4 EyelashEffect(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              sampler textureSampler [[sampler(0)]],
                              constant float &effectFactor [[buffer(0)]],
                              constant float2 &leftEyeCenter [[buffer(1)]],
                              constant float2 &leftEyeRadius [[buffer(2)]],
                              constant float2 &rightEyeCenter [[buffer(3)]],
                              constant float2 &rightEyeRadius [[buffer(4)]]) {
    
    float2 uv = vert.textureCoordinate;

    // Edge mask for each eye
    float maskL = eyelashEdgeMask(uv, leftEyeCenter, leftEyeRadius) * eyelashPattern(uv, leftEyeCenter, leftEyeRadius);
    float maskR = eyelashEdgeMask(uv, rightEyeCenter, rightEyeRadius) * eyelashPattern(uv, rightEyeCenter, rightEyeRadius);
    float mask = max(maskL, maskR);

    // smooth mask for soft blending
    mask = smoothstep(0.0, 1.0, mask);

    float4 color = inputTexture.sample(textureSampler, uv);

    float factor = clamp(effectFactor / 100.0, -1.0, 1.0);

    if (abs(factor) > 0.01) {
        if (factor > 0.0) {
            // Darken lashes at edges
            float3 darkColor = color.rgb * 0.6;
            color.rgb = mix(color.rgb, darkColor, mask * factor);
        } else {
            // Lighten lashes edges
            float3 lightColor = min(color.rgb * 1.2, float3(1.0));
            color.rgb = mix(color.rgb, lightColor, mask * (-factor));
        }
    }

    return color;
}

*/
