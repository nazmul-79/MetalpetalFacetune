//
//  TeethWhiteningMetalFilter.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 28/8/25.
//


#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;


// center + radius for inner lips area


/*fragment float4 TeethWhiteningInnerLipsShader(VertexOut vert [[stage_in]],
                                              texture2d<float> inputTexture [[texture(0)]],
                                              sampler textureSampler [[sampler(0)]],
                                              texture2d<float> maskTexture [[texture(1)]],
                                              constant float &effectFactor [[buffer(0)]],
                                              constant float2 &innerLipsCenter [[buffer(1)]],
                                              constant float2 &innerLipsRadius [[buffer(2)]]) {
    
    float2 uv = vert.textureCoordinate;
        float4 color = inputTexture.sample(textureSampler, uv);
        float mask = maskTexture.sample(textureSampler, uv).r; // mask in [0,1]

        if(mask <= 0.001) return color; // outside mask → keep original

        // Simple brightness increase
        float3 brightColor = color.rgb + effectFactor * mask;
        // clamp to avoid exceeding 1.0
        brightColor = clamp(brightColor, 0.0, 1.0);

        return float4(brightColor, color.a);
}
*/

// Helper function for RGB to HSL conversion (if not already defined)
float3 rgb2hsl1(float3 rgb) {
    float cmax = max(rgb.r, max(rgb.g, rgb.b));
    float cmin = min(rgb.r, min(rgb.g, rgb.b));
    float delta = cmax - cmin;
    
    float h = 0.0;
    float s = 0.0;
    float l = (cmax + cmin) / 2.0;
    
    if (delta != 0.0) {
        s = l > 0.5 ? delta / (2.0 - cmax - cmin) : delta / (cmax + cmin);
        
        if (cmax == rgb.r) {
            h = (rgb.g - rgb.b) / delta + (rgb.g < rgb.b ? 6.0 : 0.0);
        } else if (cmax == rgb.g) {
            h = (rgb.b - rgb.r) / delta + 2.0;
        } else {
            h = (rgb.r - rgb.g) / delta + 4.0;
        }
        h /= 6.0;
    }
    
    return float3(h, s, l);
}



// Helper function for HSL to RGB conversion (if not already defined)
float3 hsl2rgb1(float3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;
    
    float3 rgb = float3(l, l, l);
    
    if (s > 0.0) {
        float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
        float p = 2.0 * l - q;
        
        rgb.r = hue2rgb(p, q, h + 1.0/3.0);
        rgb.g = hue2rgb(p, q, h);
        rgb.b = hue2rgb(p, q, h - 1.0/3.0);
    }
    
    return rgb;
}

float hue2rgb(float p, float q, float t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0/6.0) return p + (q - p) * 6.0 * t;
    if (t < 1.0/2.0) return q;
    if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
    return p;
}

// Grainy effect function (if not already defined)
float4 grainyColor(float4 baseColor, float strength, float2 uv, float width, float height) {
    // Simple noise implementation - you might want to use a proper noise function
    float2 resolution = float2(width, height);
    float2 uvScaled = uv * resolution;
    float noise = fract(sin(dot(uvScaled, float2(12.9898, 78.233))) * 43758.5453);
    
    float grain = (noise - 0.5) * strength;
    return baseColor + float4(grain, grain, grain, 0.0);
}

// Advanced tooth detection function based on MDPI paper methodology
float detectTeeth(float3 rgb, float2 uv, texture2d<float> texture, sampler sampler, float width, float height) {
    float3 hsl = rgb2hsl(rgb);
    
    // 1. Color-based detection (teeth are typically light with low saturation)
    float colorScore = smoothstep(0.5, 0.8, hsl.z) * (1.0 - smoothstep(0.1, 0.4, hsl.y));
    
    // 2. Edge detection for tooth boundaries (simplified)
    float2 pixelSize = 1.0 / float2(width, height);
    float4 neighbors = float4(
        texture.sample(sampler, uv + float2(pixelSize.x, 0)).r,
        texture.sample(sampler, uv + float2(-pixelSize.x, 0)).r,
        texture.sample(sampler, uv + float2(0, pixelSize.y)).r,
        texture.sample(sampler, uv + float2(0, -pixelSize.y)).r
    );
    
    float edgeIntensity = length(float2(neighbors.x - neighbors.y, neighbors.z - neighbors.w));
    float edgeScore = 1.0 - smoothstep(0.05, 0.2, edgeIntensity);
    
    // 3. Brightness consistency check (teeth have relatively uniform brightness)
    float brightnessVariance = 0.0;
    const int sampleCount = 4;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            if (i == 0 && j == 0) continue;
            float2 sampleUV = uv + float2(i, j) * pixelSize * 2.0;
            float3 sampleRGB = texture.sample(sampler, sampleUV).rgb;
            brightnessVariance += abs(sampleRGB.r - rgb.r);
        }
    }
    brightnessVariance /= 8.0;
    float consistencyScore = 1.0 - smoothstep(0.1, 0.3, brightnessVariance);
    
    // 4. Combined probability
    float toothProbability = colorScore * edgeScore * consistencyScore;
    
    return clamp(toothProbability, 0.0, 1.0);
}


/*fragment float4 TeethWhiteningInnerLipsShader(VertexOut vert [[stage_in]],
                                              texture2d<float> inputTexture [[texture(0)]],
                                              sampler textureSampler [[sampler(0)]],
                                              texture2d<float> maskTexture [[texture(1)]],
                                              constant float &effectFactor [[buffer(0)]],
                                              constant float2 &innerLipsCenter [[buffer(1)]],
                                              constant float2 &innerLipsRadius [[buffer(2)]]) {

    float2 uv = vert.textureCoordinate;
    float4 inColor = inputTexture.sample(textureSampler, uv);

    // Sample mask alpha
    float maskVal = maskTexture.sample(textureSampler, uv).a;

    // Convert effectFactor to 0..1
    float intensity = clamp(effectFactor / 100.0, 0.0, 1.0);

    if (maskVal > 0.01) {
        // Compute distance from inner lips center for smooth edge fade
        float2 centerUV = innerLipsCenter;
        float2 radiusUV = innerLipsRadius; // x = horizontal, y = vertical
        float2 delta = (uv - centerUV) / radiusUV;
        float dist = length(delta);
        float edgeFade = smoothstep(1.0, 0.8, dist); // fades from 1.0 to 0.0 near edge

        // Combine mask alpha with edge fade
        float finalMask = maskVal * edgeFade;

        // Apply subtle grain
        float4 grainyC = grainyColor(inColor, 0.02, uv, inputTexture.get_width(), inputTexture.get_height());

        // Convert to HSL
        float3 hsl = rgb2hsl1(grainyC.rgb);

        // Stronger lightness boost
        float whiteningStrength = 0.8 + 0.5 * intensity;
        hsl.z = clamp(hsl.z * whiteningStrength, 0.0, 1.0);

        // Slightly reduce saturation for natural white
        hsl.y = mix(hsl.y, 0.05, intensity);

        // Optional blue tint (fully transparent by default)
        float3 blueTint = float3(1.0, 1.0, 1.0);
        float blueIntensity = 0.0;
        float3 whitenedRGB = mix(hsl2rgb1(hsl), blueTint, blueIntensity);

        // Convert back to float4
        float4 outC = float4(whitenedRGB, grainyC.a);

        // Blend with original using final mask
        return mix(inColor, outC, finalMask * intensity);
    } else {
        return inColor;
    }
}*/

/*fragment float4 TeethWhiteningInnerLipsShader(VertexOut vert [[stage_in]],
                                              texture2d<float> inputTexture [[texture(0)]],
                                              sampler textureSampler [[sampler(0)]],
                                              texture2d<float> maskTexture [[texture(1)]],
                                              constant float &effectFactor [[buffer(0)]],
                                              constant float2 &innerLipsCenter [[buffer(1)]],
                                              constant float2 &innerLipsRadius [[buffer(2)]]) {

    float2 uv = vert.textureCoordinate;
    float4 inColor = inputTexture.sample(textureSampler, uv);

    // Sample mask alpha
    float maskVal = maskTexture.sample(textureSampler, uv).a;

    // Convert effectFactor to 0..1
    float intensity = clamp(effectFactor / 100.0, 0.0, 1.0);

    if (maskVal > 0.01) {
        // Smooth fade near edges using distance from inner lips center
        float2 centerUV = innerLipsCenter;
        float2 radiusUV = innerLipsRadius; // x = horizontal, y = vertical
        float2 delta = (uv - centerUV) / radiusUV;
        float dist = length(delta);
        float edgeFade = smoothstep(1.0, 0.8, dist); // fades effect near edges

        // Final mask combining alpha and edge fade
        float finalMask = maskVal * edgeFade;

        // Apply subtle grain for natural texture
        float4 grainyC = grainyColor(inColor, 0.015, uv, inputTexture.get_width(), inputTexture.get_height());

        // Convert to HSL
        float3 hsl = rgb2hsl1(grainyC.rgb);

        // Only boost lightness for whitening
        float whiteningStrength = 0.8 + 0.5 * intensity; // stronger effect
        hsl.z = clamp(hsl.z * whiteningStrength, 0.0, 1.0);

        // Convert back to RGB
        float3 whitenedRGB = clamp(hsl2rgb1(hsl), 0.0, 1.0);

        // Compose final color
        float4 outC = float4(whitenedRGB, grainyC.a);

        // Blend with original using mask and intensity
        return mix(inColor, outC, finalMask * intensity);
    } else {
        return inColor;
    }
}

*/
/*fragment float4 TeethWhiteningInnerLipsShader(VertexOut vert [[stage_in]],
                                              texture2d<float> inputTexture [[texture(0)]],
                                              sampler textureSampler [[sampler(0)]],
                                              texture2d<float> maskTexture [[texture(1)]],
                                              constant float &effectFactor [[buffer(0)]],
                                              constant float2 &innerLipsCenter [[buffer(1)]],
                                              constant float2 &innerLipsRadius [[buffer(2)]]) {

    float2 uv = vert.textureCoordinate;
    float4 inColor = inputTexture.sample(textureSampler, uv);

    // Sample mask alpha
    float maskVal = maskTexture.sample(textureSampler, uv).a;

    // Convert effectFactor to 0..1
    float intensity = clamp(effectFactor / 100.0, 0.0, 1.0);

    if (maskVal > 0.01) {
        float2 delta = (uv - innerLipsCenter) / innerLipsRadius;
        float dist = length(delta);

        float edgeFade = smoothstep(1.0, 0.98, dist);
        float finalMask = maskVal * edgeFade;

        if (finalMask > 0.01) {
            float4 grainyC = grainyColor(inColor, 0.015, uv, inputTexture.get_width(), inputTexture.get_height());

            float3 hsl = rgb2hsl1(grainyC.rgb);

            // Boost lightness
            float whiteningStrength = 0.8 + 0.5 * intensity;
            hsl.z = clamp(hsl.z * whiteningStrength, 0.0, 1.0);

            // Skip whitening if already too bright
            if (hsl.z < 0.6) {
                return inColor; // keep original color, prevent over-whitening
            }

            hsl.y = mix(hsl.y, 0.05, intensity);

            float3 whitenedRGB = clamp(hsl2rgb1(hsl), 0.0, 1.0);

            float4 outC = float4(whitenedRGB, grainyC.a);

            return mix(inColor, outC, finalMask * intensity);
        }
    }

    return inColor;
}
*/

/*fragment float4 TeethWhiteningInnerLipsShader(
    VertexOut vert [[stage_in]],
    texture2d<float> inputTexture [[texture(0)]],
    sampler textureSampler [[sampler(0)]],
    texture2d<float> maskTexture [[texture(1)]],
    constant float &effectFactor [[buffer(0)]],
    constant float2 &innerLipsCenter [[buffer(1)]],
    constant float2 &innerLipsRadius [[buffer(2)]]
) {
    float2 uv = vert.textureCoordinate;
    float4 inColor = inputTexture.sample(textureSampler, uv);
    float maskVal = maskTexture.sample(textureSampler, uv).a;
    float intensity = clamp(effectFactor / 100.0, 0.0, 1.0);

    if (maskVal > 0.01) {
        float2 delta = (uv - innerLipsCenter) / innerLipsRadius;
        float dist = length(delta);
        float edgeFade = smoothstep(1.0, 0.95, dist);
        float finalMask = maskVal * edgeFade;

        if (finalMask > 0.01) {
            float4 grainyC = grainyColor(inColor, 0.015, uv, inputTexture.get_width(), inputTexture.get_height());
            float3 hsl = rgb2hsl1(grainyC.rgb);

            // Non-linear lightness boost
            hsl.z = clamp(pow(hsl.z, 1.0 - 0.3 * intensity), 0.0, 1.0);

            // Distance-dependent saturation reduction
            float satFade = smoothstep(0.0, 1.0, dist);
            hsl.y = mix(hsl.y, 0.05, intensity * (1.0 - satFade));

            // Slight soft blue tint
            float3 whitenedRGB = hsl2rgb1(hsl) * mix(float3(1.0), float3(1.0, 1.0, 1.02), 0.05 * intensity);

            float4 outC = float4(whitenedRGB, grainyC.a);

            // Softer blend for natural effect
            float blendFactor = finalMask * (0.4 + 0.6 * intensity);
            return mix(inColor, outC, blendFactor);
        }
    }

    return inColor;
}
*/

fragment float4 TeethWhiteningInnerLipsShader(
    VertexOut vert [[stage_in]],
    texture2d<float> inputTexture [[texture(0)]],
    sampler textureSampler [[sampler(0)]],
    texture2d<float> maskTexture [[texture(1)]],
    constant float &effectFactor [[buffer(0)]],
    constant float2 &innerLipsCenter [[buffer(1)]], // still needed if you want center-based adjustments
    constant float2 &innerLipsRadius [[buffer(2)]]
) {
    float2 uv = vert.textureCoordinate;
    float4 inColor = inputTexture.sample(textureSampler, uv);

    // Use mask alpha directly
    float maskVal = maskTexture.sample(textureSampler, uv).a;

    // Convert effectFactor to 0..1
    float intensity = clamp(effectFactor / 100.0, 0.0, 1.0);

    if (maskVal > 0.01) {
        // Apply subtle grain for natural texture
        float4 grainyC = grainyColor(inColor, 0.015, uv, inputTexture.get_width(), inputTexture.get_height());

        // Convert to HSL
        float3 hsl = rgb2hsl1(grainyC.rgb);

        // Only boost lightness if below threshold to prevent over-whitening
        if (hsl.z >= 0.6) {
            // Already bright, skip
            return inColor;
        }

        // Boost lightness and slightly desaturate for natural white
        float whiteningStrength = 0.8 + 0.5 * intensity;
        hsl.z = clamp(hsl.z * whiteningStrength, 0.0, 1.0);
        hsl.y = mix(hsl.y, 0.05, intensity);

        float3 whitenedRGB = clamp(hsl2rgb1(hsl), 0.0, 1.0);
        float4 outC = float4(whitenedRGB, grainyC.a);

        // Blend with original using mask alpha
        return mix(inColor, outC, maskVal * intensity);
    }

    return inColor;
}

