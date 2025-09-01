//
//  Eye.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 28/8/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 EyeContrastEffect(VertexOut vert [[stage_in]],
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

    // --- LEFT EYE OFFSET ---
    float2 offsetL = float2(0.01, 0.0);
    float2 diffL = (uv - leftEyeCenter + offsetL) / leftEyeRadius;
    diffL.y *= 1.3; // vertical stretch for eyelid
    float distL = length(diffL);
    float leftMask = pow(1.0 - smoothstep(0.4, 1.5, distL), 2.0); // stronger center, soft edges

    // --- RIGHT EYE OFFSET ---
    float2 offsetR = float2(-0.01, 0.0);
    float2 diffR = (uv - rightEyeCenter + offsetR) / rightEyeRadius;
    diffR.y *= 1.3;
    float distR = length(diffR);
    float rightMask = pow(1.0 - smoothstep(0.4, 1.5, distR), 2.0);

    // Combine masks
    float eyeMask = max(leftMask, rightMask) * abs(factor);

    if (eyeMask > 0.0) {
        if (factor > 0.0) {
            float brightnessBoost = 0.08; // subtle, absolute
            color.rgb += eyeMask * brightnessBoost; // small incremental brighten
        } else {
            float darkenAmount = 0.1;
            color.rgb -= eyeMask * darkenAmount;
        }
    }

    return color;
}


/*#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

fragment float4 TeethWhiteningShader(VertexOut vert [[stage_in]],
                                     texture2d<float> inputTexture [[texture(0)]],
                                     sampler textureSampler [[sampler(0)]],
                                     texture2d<float> maskTexture [[texture(1)]],
                                     constant float &effectFactor [[buffer(0)]],
                                     constant float2 &teethCenter [[buffer(1)]],
                                     constant float2 &teethRadius [[buffer(2)]]) {

    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(textureSampler, uv);

    // Sample mask
    float mask = maskTexture.sample(textureSampler, uv).r;
    if(mask <= 0.01) return color;

    // Clamp effect factor
    float factor = clamp(effectFactor / 100.0, 0.0, 1.0);
    if(factor <= 0.001) return color;

    // Distance from teeth center
    float2 diff = (uv - teethCenter) / teethRadius;
    diff.y *= 1.3; // vertical stretch for teeth
    float dist = length(diff);

    // Center-strong, edge-soft falloff
    float distanceMask = pow(1.0 - smoothstep(0.0, 1.0, dist), 2.0);
    float finalMask = mask * distanceMask;
    if(finalMask <= 0.001) return color;

    // Luminance and rough saturation
    float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
    float sat  = max(color.r, max(color.g, color.b)) - min(color.r, min(color.g, color.b));

    // Teeth-like pixel detection
    if(luma < 0.5 || luma > 0.85 || sat > 0.4) return color;

    // Convert to HSL
    float3 hsl = rgb2hsl(color.rgb);

    // Increase lightness naturally
    hsl.z += factor * finalMask * (1.0 - hsl.z) * 0.5; // tweak multiplier for subtle effect
    hsl.z = clamp(hsl.z, 0.0, 1.0);

    // Convert back to RGB
    float3 brightened = hsl2rgb(hsl);

    return float4(brightened, color.a);
}
*/

