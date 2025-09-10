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


// Helper function for HSL to RGB conversion (if not already defined)
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

float3 rgb2hsl1(float3 color) {
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

float3 hsl2rgb1(float3 hsl) {
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


fragment float4 TeethWhiteningInnerLipsShader(
    VertexOut vert [[stage_in]],
    texture2d<float> inputTexture [[texture(0)]],
    sampler textureSampler [[sampler(0)]],
    texture2d<float> maskTexture [[texture(1)]],
    constant float &effectFactor [[buffer(0)]],
    constant float2 &innerLipsCenter [[buffer(1)]], // still needed if you want center-based adjustments
    constant float2 &innerLipsRadius [[buffer(2)]]
) {
    /*float2 uv = vert.textureCoordinate;
       float4 inColor = inputTexture.sample(textureSampler, uv);

    // Mask alpha for inner lips
       float maskVal = maskTexture.sample(textureSampler, uv).a;

       if (maskVal > 0.0) {
           float intensity = clamp(effectFactor / 100.0, 0.0, 1.0);

           // soften edges
           float smoothMask = smoothstep(0.0, 1.0, maskVal);

           // Convert to HSL
           float3 hsl = rgb2hsl1(inColor.rgb);

           // Boost lightness only
           hsl.z = clamp(hsl.z + 0.05 * intensity * smoothMask, 0.0, 1.0);

           // Slightly reduce saturation for natural look
           hsl.y = mix(hsl.y, 0.05, intensity * smoothMask);

           float3 whitenedRGB = hsl2rgb1(hsl);

           return float4(whitenedRGB, inColor.a);
       }

       return inColor;*/
    
    // sample input and mask
    /*float2 uv = vert.textureCoordinate;
       float4 color = inputTexture.sample(textureSampler, uv);
       float mask = maskTexture.sample(textureSampler, uv).a;

       float factor = clamp(effectFactor / 100.0, 0.0, 1.0);
       if (factor <= 0.001 || mask <= 0.001) return color;

       // --- Compute luma and saturation
       float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
       float maxC = max(color.r, max(color.g, color.b));
       float minC = min(color.r, min(color.g, color.b));
       float sat = maxC - minC;

       // filter out gums/tongue (too dark or too saturated)
       if (luma < 0.35 || sat > 0.55) return color;

       // --- Whitening effect ---
       // 1. Boost brightness but keep contrast
       float3 brightened = color.rgb * (1.0 + 0.25 * factor * mask);

       // 2. Slightly compress saturation instead of greying out
       float grey = dot(brightened, float3(0.333, 0.333, 0.333));
       float3 desaturated = mix(brightened, float3(grey), 0.15 * factor * mask);

       // 3. Gentle push toward neutral-white (not pure white)
       float3 neutralWhite = float3(0.95, 0.95, 0.97);
       float3 finalRGB = mix(desaturated, neutralWhite, 0.05 * factor * mask);

       // Preserve highlights by clamping softly
       finalRGB = clamp(finalRGB, 0.0, 1.0);

       return float4(finalRGB, color.a);*/
    
    /*float2 uv = vert.textureCoordinate;
        float4 color = inputTexture.sample(textureSampler, uv);
        float mask = maskTexture.sample(textureSampler, uv).a;

        float factor = clamp(effectFactor / 100.0, 0.0, 1.0);
        if (factor <= 0.001 || mask <= 0.001) return color;

        // Luma & saturation
        float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
        float maxC = max(color.r, max(color.g, color.b));
        float minC = min(color.r, min(color.g, color.b));
        float sat = maxC - minC;

        if (luma < 0.35 || sat > 0.55) return color;

        // --- Preserve contrast ---
        float strength = 0.25 * factor * mask;

        // Screen blend with off-white
        float3 white = float3(0.96, 0.96, 0.99);
        float3 screened = 1.0 - (1.0 - color.rgb) * (1.0 - white);

        // Blend toward screen but weight more in midtones
        float midBoost = smoothstep(0.3, 0.7, luma);  // only midtones get push
        float3 blended = mix(color.rgb, screened, strength * midBoost);

        // Contrast restore: push slightly away from grey
        float grey = dot(blended, float3(0.333,0.333,0.333));
        blended = mix(blended, blended * 1.05 - 0.025, 0.5); // tiny contrast bump

        return float4(clamp(blended, 0.0, 1.0), color.a);*/
    
    /*float2 uv = vert.textureCoordinate;
        float4 color = inputTexture.sample(textureSampler, uv);
        float mask = maskTexture.sample(textureSampler, uv).a;

        float factor = clamp(effectFactor / 100.0, 0.0, 1.0);
        if (factor <= 0.001 || mask <= 0.001) return color;

        // Luma & saturation
        float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
        float maxC = max(color.r, max(color.g, color.b));
        float minC = min(color.r, min(color.g, color.b));
        float sat = maxC - minC;

        if (luma < 0.35 || sat > 0.55) return color;

        // whitening target (off-white instead of pure white)
        float3 white = float3(0.96, 0.96, 0.99);

        // soft-light blend instead of hard mix
        float3 softBlend = softLightBlend(color.rgb, white);

        // softly interpolate (low strength)
        float strength = 0.3 * factor * mask;
        float3 blended = mix(color.rgb, softBlend, strength);

        return float4(clamp(blended, 0.0, 1.0), color.a);*/
    
    /*float2 uv = vert.textureCoordinate;
       float4 color = inputTexture.sample(textureSampler, uv);
       float mask = maskTexture.sample(textureSampler, uv).a;

       float factor = clamp(effectFactor / 100.0, 0.0, 1.0);
       if (factor <= 0.001 || mask <= 0.001) return color;

       // Luma + sat checks
       float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
       float maxC = max(color.r, max(color.g, color.b));
       float minC = min(color.r, min(color.g, color.b));
       float sat = maxC - minC;
       if (luma < 0.35 || sat > 0.55) return color;

       // Convert to HSL
       /*float3 hsl = rgb2hsl(color.rgb);

       // Lightness boost (soft, controlled)
       float boost = 0.08 * factor * mask;       // max +8%
       hsl.z = clamp(hsl.z + boost, 0.0, 1.0);

       // Slight desat for stains
       hsl.y = mix(hsl.y, hsl.y * 0.7, factor * mask * 0.5);

       // Back to RGB
       float3 whitened = hsl2rgb(hsl);

       return float4(whitened, color.a);*/
    
    /*float3 hsl = rgb2hsl(color.rgb);

    // Reject pink/red hues (gum/tongue)
    //if (hsl.x < 0.05 || hsl.x > 0.95) return color;   // hue ~ red
    //if (hsl.x > 0.9 && hsl.z < 0.6) return color;     // deep pink shades

    // Lightness boost (soft, controlled)
    float boost = 0.15 * factor * mask;
    hsl.z = clamp(hsl.z + boost, 0.0, 1.0);

    // Slight desat
    hsl.y = mix(hsl.y, hsl.y * 0.7, factor * mask * 0.5);

    // Back to RGB
    float3 whitened = hsl2rgb(hsl);
    float3 blended = mix(color.rgb, whitened, 0.3 * factor);
    return float4(clamp(blended, 0.0, 1.0), color.a);*/
    
    /*float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(textureSampler, uv);
    //float mask = maskTexture.sample(textureSampler, uv).a;
    constexpr sampler maskSampler = sampler(address::clamp_to_zero, coord::normalized);
    float mask = clamp(maskTexture.sample(maskSampler, uv).a, 0.0, 1.0);
    // প্রথমে hard cutoff
    float hardMask = step(0.5, mask);

    // তারপর soft edge চাইলে
    mask = smoothstep(0.45, 0.55, mask) * hardMask;

    float factor = clamp(effectFactor / 100.0, 0.0, 1.0);
    if (factor <= 0.001 || mask <= 0.001) return color;

    // Compute luma and saturation
    float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
    float maxC = max(color.r, max(color.g, color.b));
    float minC = min(color.r, min(color.g, color.b));
    float sat = maxC - minC;

    // Only process teeth-like colors: mid-bright, not highly saturated
    float3 hsl = rgb2hsl(color.rgb);
    
    if (luma < 0.35 || sat > 0.55) return color;
    
    if (hsl.x < 0.95 && hsl.x > 0.05) {

        
        // Only process teeth-like colors

        // --- Teeth whitening ---
        float3 teethColor = color.rgb;
        
        

        // Detect yellow/brown tones more aggressively
        float yellowMask = smoothstep(0.0, 0.3, teethColor.r - teethColor.b) *
                           smoothstep(0.0, 0.2, teethColor.g - teethColor.b);

        // PROPER YELLOW NEUTRALIZATION:
        // Reduce yellow by lowering red and green relative to blue
        float yellowReduction = 0.4 * factor * yellowMask;
        teethColor.r *= (1.0 - yellowReduction * 0.8);  // Reduce red the most
        teethColor.g *= (1.0 - yellowReduction * 0.9);  // Reduce green moderately
        teethColor.b *= (1.0 + yellowReduction * 0.1);  // Slightly boost blue

        // WHITENING (not just brightness):
        // Move all channels toward white balance
        float whiteTarget = 0.9; // Target whitening level
        float safeMask = smoothstep(0.1, 1.0, mask);
        // Whitening target
        float contrast = 1.0 + 0.1 * factor;
              teethColor = ((teethColor - 0.5) * contrast) + 0.5;
        float3 whiteTargetColor = float3(0.95, 0.95, 0.92);
        teethColor = mix(teethColor, whiteTargetColor, factor * 0.35);

        // --- Gamma-correct blending for smooth edges ---
               float3 baseLinear = pow(color.rgb, float3(2.2));
               float3 teethLinear = pow(teethColor, float3(2.2));

               // Use screen blend or linear blend (choose one)
               float3 blendedLinear = mix(baseLinear, teethLinear, mask * factor);
               // OR for stronger brightening: float3 blendedLinear = mix(baseLinear, screenBlend(baseLinear, teethLinear), mask * factor);

               float3 finalColor = pow(blendedLinear, float3(1.0/2.2));

               return float4(clamp(finalColor, 0.0, 1.0), mask);
    }
    return color;*/
    
    float2 uv = vert.textureCoordinate;
        float4 color = inputTexture.sample(textureSampler, uv);

        constexpr sampler maskSampler = sampler(address::clamp_to_zero, coord::normalized);
        float mask = maskTexture.sample(maskSampler, uv).a;

        float factor = clamp(effectFactor / 100.0, 0.0, 1.0);

        // শুধু দাঁতের mask এ কাজ করবে
        float3 hsl = rgb2hsl1(color.rgb);
        //if (hsl.x < 0.05 || hsl.x > 0.9) return color;
    if (mask > 0.97 && factor > 0.001) {
        float3 c = color.rgb;
        float3 hslC = rgb2hsl1(c);
        
        if (hsl.x < 0.05 || hsl.x > 0.75) {
            hslC.z *= (1.0 + 0.06 * factor);   // lightness slightly up
            
            // --- Contrast boost ---
            c = ((c - 0.5) * (1.0 + 0.02 * factor)) + 0.5;
            
            // --- Saturation reduce ---
            hslC.y *= (1.0 - (factor * 0.1));
            c = hsl2rgb(hslC);
            
            // --- Blue boost (subtle) ---
            c.b *= (1.0 + 0.04 * factor);   // subtle, avoid cyan shadow
            
            // clamp
            c = clamp(c, 0.0, 1.0);
        } else {
            hslC.z *= (1.0 + 0.15 * factor);   // lightness slightly up
            
            // --- Contrast boost ---
            c = ((c - 0.5) * (1.0 + 0.1 * factor)) + 0.5;
            
            // --- Saturation reduce ---
            hslC.y *= (1.0 - (factor * 0.3));
            c = hsl2rgb1(hslC);
            
            // --- Blue boost (subtle) ---
            c.b *= (1.0 + 0.06 * factor);   // subtle, avoid cyan shadow
            
            // clamp
            c = clamp(c, 0.0, 1.0);
        }
        return float4(c, color.a);
    }

        return color;
}

/*float2 uv = vert.textureCoordinate;
float4 color = inputTexture.sample(textureSampler, uv);
float mask = maskTexture.sample(textureSampler, uv).a;

float factor = clamp(effectFactor / 100.0, 0.0, 1.0);
if (factor <= 0.001 || mask <= 0.001) return color;

// Convert to HSL
float3 hsl = rgb2hsl(color.rgb);

// Reject non-teeth colors (red/pink hues for gums/tongue)
// Hue is normalized [0,1] where 0=red, 0.33=green, 0.66=blue, 1=red
if (hsl.x < 0.95 && hsl.x > 0.05) { // Only process colors in the yellow/white range
    // Lightness boost
    float boost = 0.2 * factor * mask; // Increased boost for better effect
    hsl.z = clamp(hsl.z + boost, 0.0, 1.0);
    
    // Desaturate slightly
    hsl.y = mix(hsl.y, hsl.y * 0.6, factor * mask * 0.7);
    
    // Convert back to RGB
    float3 whitened = hsl2rgb(hsl);
    
    float3 blended = mix(color.rgb, whitened, 0.2 * factor);

    return float4(clamp(blended, 0.0, 1.0), color.a);
}

return color;
*/

/*
 
 float2 uv = vert.textureCoordinate;
 float4 color = inputTexture.sample(textureSampler, uv);
 float mask = maskTexture.sample(textureSampler, uv).a;

 float factor = clamp(effectFactor / 100.0, 0.0, 1.0);
 if (factor <= 0.001 || mask <= 0.001) return color;

 // Compute luma and saturation
 float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
 float maxC = max(color.r, max(color.g, color.b));
 float minC = min(color.r, min(color.g, color.b));
 float sat = maxC - minC;

 // Only process teeth-like colors: mid-bright, not highly saturated
 if (luma < 0.35 || sat > 0.55) return color;
 
 float3 hsl = rgb2hsl(color.rgb);
 
 if (hsl.x < 0.95 && hsl.x > 0.05) {
     
     // Adaptive brightness boost: darker teeth get more lift
     /*float brightnessBoost = 0.15 + 0.25 * smoothstep(0.2, 0.5, 0.5 - luma);
     
     // Slight desaturation for natural look
     float satFactor = 0.8;  // reduce saturation slightly
     
     // Apply mask and factor
     float3 boosted = color.rgb + brightnessBoost * factor * mask;
     boosted = mix(boosted, float3(dot(boosted, float3(0.333))), 1.0 - satFactor);
     
     float3 blended = mix(color.rgb, boosted, 0.4 * factor);
     
     // Clamp and return
     return float4(clamp(blended, 0.0, 1.0), color.a);*/
     
     // Adaptive brightness boost: darker teeth get more lift
        /*float brightnessBoost = 0.3 + 0.25 * smoothstep(0.2, 0.5, 0.5 - luma);
        
        // Slight desaturation for natural look
        float satFactor = 1.5;
        
        // Apply mask and factor
        float3 boosted = color.rgb + brightnessBoost * factor * mask;
        boosted = mix(boosted, float3(dot(boosted, float3(0.333))), 1.0 - satFactor);
        
        // Blend with original using mask to restrict effect only to teeth region
        float3 blended = mix(color.rgb, boosted, 0.25 * factor * mask); // mask applied here
        
        return float4(clamp(blended, 0.0, 1.0), color.a);*/
     
     
     // Only process teeth-like colors
     /*if (luma < 0.35 || sat > 0.55) return color;

     // --- Teeth whitening ---
     float3 teethColor = color.rgb;

     // Detect yellow/brown tones more aggressively
     float yellowMask = smoothstep(0.0, 0.3, teethColor.r - teethColor.b) *
                        smoothstep(0.0, 0.2, teethColor.g - teethColor.b);

     // PROPER YELLOW NEUTRALIZATION:
     // Reduce yellow by lowering red and green relative to blue
     float yellowReduction = 0.4 * factor * mask * yellowMask;
     teethColor.r *= (1.0 - yellowReduction * 0.9);  // Reduce red the most
     teethColor.g *= (1.0 - yellowReduction * 0.7);  // Reduce green moderately
     teethColor.b *= (1.0 + yellowReduction * 0.4);  // Slightly boost blue

     // WHITENING (not just brightness):
     // Move all channels toward white balance
     float whiteTarget = 0.9; // Target whitening level
     float whitening = factor * mask;

     // Smart whitening that preserves texture
     teethColor = mix(teethColor, float3(whiteTarget), whitening * 0.2);
     teethColor = clamp(teethColor, 0.0, 1.0);

     // Contrast preservation - don't make everything flat
     float contrast = 1.0 + (0.1 * whitening);
     teethColor = ((teethColor - 0.5) * contrast) + 0.5;

     // --- Soft blend with original using mask ---
     float contraction = 0.1; // 5% contraction
     float safeMask = smoothstep(contraction, 1.0, mask);
     
     //float safeMask = smoothstep(0.5, 1.0, mask); // 0.5 এর নিচে effect শূন্য
     float blendStrength = 0.8 * factor * safeMask;
     float3 blended = mix(color.rgb, teethColor, blendStrength);
     //float3 blended = mix(color.rgb, teethColor, blendStrength);
     //float3 blended = mix(color.rgb, teethColor, blendStrength);

     return float4(clamp(blended, 0.0, 1.0), color.a);
 }*/
 
 
 

/*
 float2 uv = vert.textureCoordinate;
     float4 color = inputTexture.sample(textureSampler, uv);

     // Sample mask with normalized coordinates
     constexpr sampler maskSampler = sampler(address::clamp_to_zero, coord::normalized);
 float mask = 0.0;
     float2 texelSize = 1.0 / float2(maskTexture.get_width(), maskTexture.get_height());

     // 5x5 Gaussian kernel
     float k0 = 0.0625;
     float k1 = 0.25;
     float k2 = 0.375;
     float k3 = 0.25;
     float k4 = 0.0625;

     for (int x = -2; x <= 2; x++) {
         float kx = (x == -2) ? k0 : (x == -1) ? k1 : (x == 0) ? k2 : (x == 1) ? k3 : k4;
         for (int y = -2; y <= 2; y++) {
             float ky = (y == -2) ? k0 : (y == -1) ? k1 : (y == 0) ? k2 : (y == 1) ? k3 : k4;
             float2 offset = float2(x, y) * texelSize;
             mask += maskTexture.sample(maskSampler, uv + offset).a * kx * ky;
         }
     }

     mask = clamp(mask, 0.0, 1.0);

     float factor = clamp(effectFactor / 100.0, 0.0, 1.0);
     if (factor <= 0.001 || mask <= 0.001) return color;

     // Luma & saturation
     float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
     float maxC = max(color.r, max(color.g, color.b));
     float minC = min(color.r, min(color.g, color.b));
     float sat = maxC - minC;

     if (luma < 0.35 || sat > 0.55) return color;

     float3 hsl = rgb2hsl(color.rgb);
     if (hsl.x < 0.05 || hsl.x > 0.95) return color;

     // --- Apply grain ---
     float4 grainyC = grainyColor(color, 0.02, float2(uv.x * inputTexture.get_width(), uv.y * inputTexture.get_height()),
                                  inputTexture.get_width(), inputTexture.get_height());

     float3 teethColor = grainyC.rgb;

     // Yellow/brown neutralization
     float yellowMask = smoothstep(0.0, 0.3, teethColor.r - teethColor.b) *
                        smoothstep(0.0, 0.2, teethColor.g - teethColor.b);
     float yellowReduction = 0.4 * factor * yellowMask;
     teethColor.r *= (1.0 - yellowReduction * 0.8);
     teethColor.g *= (1.0 - yellowReduction * 0.9);
     teethColor.b *= (1.0 + yellowReduction * 0.1);

     // Whitening via HSL lightness
     float3 teethHSL = rgb2hsl(teethColor);
     teethHSL.z *= 1.0 + 0.15 * factor; // brighten
     teethHSL.z = clamp(teethHSL.z, 0.0, 1.0);
     teethColor = hsl2rgb(teethHSL);

     // Blend toward off-white for natural whitening
     float3 whiteTargetColor = float3(0.95, 0.95, 0.92);
     teethColor = mix(teethColor, whiteTargetColor, factor * 0.20);

     // Preserve contrast
     float contrast = 1.0 + 0.1 * factor;
     teethColor = ((teethColor - 0.5) * contrast) + 0.5;

     float3 baseLinear = pow(color.rgb, float3(2.2));
     float3 teethLinear = pow(teethColor.rgb, float3(2.2));
     float3 blendedLinear = mix(baseLinear, teethLinear, mask * factor);
     float3 finalColor = pow(blendedLinear, float3(1.0 / 2.2));

     return float4(clamp(finalColor, 0.0, 1.0), color.a);
 
 
 
 */
