//
//  eyebrowScaleShader.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 21/8/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;


/*float2 scaleUVForBrow(float2 uv, float2 center, float2 radiusXY, float scaleFactor) {
    float2 diff = uv - center;
    float2 normDiff = diff / radiusXY;
    float dist = length(normDiff);

    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    float inner = 0.3;
    float outer = 1.5;
    float t = smoothstep(inner, outer, dist);

    float maxScale = 0.15;
    float zoom = 1.0 - normalizedScale * (1.0 - t) * maxScale;

    float2 newNorm = normDiff * zoom;
    return center + newNorm * radiusXY;
}*/

/*float2 scaleUVForBrow(float2 uv, float2 center, float2 radiusXY, float scaleFactor) {
    float2 diff = uv - center;
    float2 normDiff = diff / radiusXY;
    float dist = length(normDiff);

    // normalize input scale (-1..1)
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    // Gaussian falloff (center strong, edges fade out)
    float falloff = exp(-dist * dist * 4.0);

    // apply airbrush style vertical scaling
    // center e beshi effect, edge e smooth fade
    float verticalScale = 1.0 - normalizedScale * falloff;

    // X unchanged, Y adjusted with falloff
    float2 newNorm = float2(normDiff.x,
                            normDiff.y * verticalScale);

    return center + newNorm * radiusXY;
}




fragment float4 eyebrowScaleShader(VertexOut vert [[stage_in]],
                                   texture2d<float> inputTexture [[texture(0)]],
                                   constant float &leftScaleFactor [[buffer(0)]],
                                   constant float &rightScaleFactor [[buffer(1)]],
                                   constant float2 &leftCenter [[buffer(2)]],
                                   constant float2 &rightCenter [[buffer(3)]],
                                   constant float2 &leftRadius [[buffer(4)]],
                                   constant float2 &rightRadius [[buffer(5)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float2 uv = vert.textureCoordinate;

    float2 uvLeft = scaleUVForBrow(uv, leftCenter, leftRadius, leftScaleFactor);
    float2 uvRight = scaleUVForBrow(uv, rightCenter, rightRadius, rightScaleFactor);

    float distLeft = length((uv - leftCenter) / leftRadius);
    float distRight = length((uv - rightCenter) / rightRadius);

    float falloff = 1.5;
    float weightLeft = exp(-pow(distLeft / falloff, 2.0));
    float weightRight = exp(-pow(distRight / falloff, 2.0));

    float totalWeight = weightLeft + weightRight;
    if (totalWeight > 0.0) {
        weightLeft /= totalWeight;
        weightRight /= totalWeight;
    }

    float2 finalUV = uvLeft * weightLeft + uvRight * weightRight + uv * (1.0 - weightLeft - weightRight);
    return inputTexture.sample(s, finalUV);
}
*/

/*float2 scaleUVForBrow(float2 uv, float2 center, float2 radiusXY, float scaleFactor) {
    float2 diff = uv - center;
    float2 normDiff = diff / radiusXY;
    float dist = length(normDiff);
    
    // Normalize and smooth the scale factor
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    
    // Use smoother sigmoid-like curve for more natural scaling
    float smoothScale = normalizedScale / (1.0 + abs(normalizedScale));
    
    // Softer Gaussian falloff with adjustable curvature
    float falloff = exp(-dist * dist * 3.0); // Reduced from 4.0 for smoother transition
    
    // Apply vertical scaling with natural easing
    // When scaling down (negative), create more pronounced center effect
    // When scaling up (positive), create gentle elevation
    float verticalScale;
    
    if (normalizedScale < 0.0) {
        // Shrinking - stronger center effect with smooth fade
        verticalScale = 1.0 - smoothScale * falloff * (1.0 + 0.3 * dist);
    } else {
        // Expanding - gentler, more distributed effect
        verticalScale = 1.0 - smoothScale * falloff * (0.8 + 0.2 * dist);
    }
    
    // Apply the scaling with smooth interpolation
    float2 newNorm = float2(normDiff.x, normDiff.y * verticalScale);
    
    return center + newNorm * radiusXY;
}

fragment float4 eyebrowScaleShader(VertexOut vert [[stage_in]],
                                   texture2d<float> inputTexture [[texture(0)]],
                                   constant float &leftScaleFactor [[buffer(0)]],
                                   constant float &rightScaleFactor [[buffer(1)]],
                                   constant float2 &leftCenter [[buffer(2)]],
                                   constant float2 &rightCenter [[buffer(3)]],
                                   constant float2 &leftRadius [[buffer(4)]],
                                   constant float2 &rightRadius [[buffer(5)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float2 uv = vert.textureCoordinate;
    
    // Calculate distance-based weights for blending
    float distLeft = length((uv - leftCenter) / leftRadius);
    float distRight = length((uv - rightCenter) / rightRadius);
    
    // Softer falloff for more natural blending
    float falloff = 2.0;
    float weightLeft = exp(-pow(distLeft / falloff, 2.5));
    float weightRight = exp(-pow(distRight / falloff, 2.5));
    
    // Ensure smooth transition between eyebrows
    float totalWeight = weightLeft + weightRight;
    float blendFactor = min(totalWeight, 1.0);
    
    float2 scaledUV;
    
    if (totalWeight > 0.001) {
        // Scale each eyebrow region separately
        float2 uvLeft = scaleUVForBrow(uv, leftCenter, leftRadius, leftScaleFactor);
        float2 uvRight = scaleUVForBrow(uv, rightCenter, rightRadius, rightScaleFactor);
        
        // Blend the scaled coordinates
        scaledUV = (uvLeft * weightLeft + uvRight * weightRight) / totalWeight;
        
        // Smoothly blend between scaled and original UV
        scaledUV = mix(uv, scaledUV, blendFactor);
    } else {
        scaledUV = uv;
    }
    
    return inputTexture.sample(s, scaledUV);
}
*/

float2 scaleUVForBrow(float2 uv, float2 center, float2 radiusXY, float scaleFactor) {
    float2 diff = uv - center;
    float2 normDiff = diff / radiusXY;
    float dist = length(normDiff);
    
    // Normalize scale factor with stronger range
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0); // Increased range to -2..2
    
    // Much stronger scaling effect
    float intenseScale = normalizedScale * 1.2; // Double the intensity
    
    // Stronger falloff but wider spread
    float falloff = exp(-dist * dist * 2.0); // Softer falloff for wider effect
    
    // Apply very strong vertical scaling
    float verticalScale;
    
    if (normalizedScale < 0.0) {
        // Strong shrinking - much more aggressive
        verticalScale = 1.0 - intenseScale * falloff * (0.5 + 0.6 * dist); // Increased multipliers
    } else {
        // Strong expanding - much more pronounced
        verticalScale = 1.0 - intenseScale * falloff * (0.4 + 0.3 * dist); // Reduced for stronger effect
    }
    
    // Clamp to prevent extreme values
    verticalScale = clamp(verticalScale, 0.3, 2.0);
    
    // Apply the intense scaling
    float2 newNorm = float2(normDiff.x, normDiff.y * verticalScale);
    
    return center + newNorm * radiusXY;
}

fragment float4 eyebrowScaleShader(VertexOut vert [[stage_in]],
                                   texture2d<float> inputTexture [[texture(0)]],
                                   constant float &leftScaleFactor [[buffer(0)]],
                                   constant float &rightScaleFactor [[buffer(1)]],
                                   constant float2 &leftCenter [[buffer(2)]],
                                   constant float2 &rightCenter [[buffer(3)]],
                                   constant float2 &leftRadius [[buffer(4)]],
                                   constant float2 &rightRadius [[buffer(5)]]) {

    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float2 uv = vert.textureCoordinate;
    
    // Calculate distance-based weights for blending
    float distLeft = length((uv - leftCenter) / leftRadius);
    float distRight = length((uv - rightCenter) / rightRadius);
    
    // Much stronger falloff for more intense effect
    float falloff = 1.8;
    float weightLeft = exp(-pow(distLeft / falloff, 1.5)); // Reduced exponent for stronger effect
    float weightRight = exp(-pow(distRight / falloff, 1.5));
    
    // Boost weights significantly
    weightLeft = pow(weightLeft, 0.7);
    weightRight = pow(weightRight, 0.7);
    
    // Ensure smooth transition between eyebrows
    float totalWeight = weightLeft + weightRight;
    float blendFactor = min(totalWeight, 1.0);
    
    float2 scaledUV;
    
    if (totalWeight > 0.001) {
        // Scale each eyebrow region separately
        float2 uvLeft = scaleUVForBrow(uv, leftCenter, leftRadius, leftScaleFactor);
        float2 uvRight = scaleUVForBrow(uv, rightCenter, rightRadius, rightScaleFactor);
        
        // Strong blending with emphasis on effect areas
        scaledUV = (uvLeft * weightLeft + uvRight * weightRight) / totalWeight;
        
        // Less preservation of original UV for stronger effect
        float outerBlend = max(smoothstep(0.8, 1.5, distLeft), smoothstep(0.8, 1.5, distRight));
        scaledUV = mix(scaledUV, uv, outerBlend * 0.2); // Reduced from 0.4 to 0.2
        
        // Apply strong blending
        scaledUV = mix(uv, scaledUV, blendFactor * 1.2); // Boosted blending strength
    } else {
        scaledUV = uv;
    }
    
    return inputTexture.sample(s, scaledUV);
}
