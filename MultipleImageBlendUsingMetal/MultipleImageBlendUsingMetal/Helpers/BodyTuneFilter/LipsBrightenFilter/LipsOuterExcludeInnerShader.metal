//
//  LipsOuterExcludeInnerShader.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 1/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;

/*// Point-in-polygon
bool pointInPolygon(float2 uv, device const float2* points, constant uint &count) {
    bool inside = false;
    uint j = count - 1;
    for (uint i = 0; i < count; i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        if (((pi.y > uv.y) != (pj.y > uv.y)) &&
            (uv.x < (pj.x - pi.x) * (uv.y - pi.y) / (pj.y - pi.y + 0.00001) + pi.x)) {
            inside = !inside;
        }
        j = i;
    }
    return inside;
}

fragment float4 LipsOuterExcludeInnerShader(VertexOut vert [[stage_in]],
                                            texture2d<float> inputTexture [[texture(0)]],
                                            sampler textureSampler [[sampler(0)]],
                                            device const float2* outerPoints [[buffer(0)]],
                                            constant uint &outerCount [[buffer(1)]],
                                            device const float2* innerPoints [[buffer(2)]],
                                            constant uint &innerCount [[buffer(3)]],
                                            constant float &outerBrightness [[buffer(4)]]) {
    
    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(textureSampler, uv);

    // Polygon check
       if(pointInPolygon(uv, outerPoints, outerCount) &&
          !pointInPolygon(uv, innerPoints, innerCount)) {

           // 1️⃣ Subtle additive brightness
           float additive = outerBrightness * 0.0005; // 100 → +0.05
           color.rgb = clamp(color.rgb + additive, 0.0, 1.0);

           // 2️⃣ Slight contrast boost
           float contrast = 1.05;
           color.rgb = (color.rgb - 0.5) * contrast + 0.5;

           // 3️⃣ Optional pink tint
           float3 lipsTint = float3(1.0, 0.6, 0.6);
           color.rgb = mix(color.rgb, lipsTint, 0.03);

           // 4️⃣ Saturation boost
           float3 hsl = rgb2hsl(color.rgb);
           hsl.y *= 1.05;
           color.rgb = hsl2rgb(hsl);
       }


       return color;
}
*/


// Compute distance from uv to polygon edges (approx)
float distanceToPolygonEdges(float2 uv, device const float2* points, constant uint &count) {
    float minDist = 1.0; // max normalized distance
    uint j = count - 1;
    for (uint i = 0; i < count; i++) {
        float2 a = points[i];
        float2 b = points[j];
        float2 pa = uv - a;
        float2 ba = b - a;
        float h = clamp(dot(pa, ba)/dot(ba,ba), 0.0, 1.0);
        float2 proj = a + h * ba;
        float dist = distance(uv, proj);
        minDist = min(minDist, dist);
        j = i;
    }
    return minDist;
}

// Smooth step for feathering
float feather(float distance, float radius) {
    return smoothstep(radius, 0.0, distance);
}

// Compute polygon center
float2 computePolygonCenter(device const float2* points, constant uint &count) {
    float2 center = float2(0.0,0.0);
    for(uint i=0;i<count;i++) {
        center += points[i];
    }
    return center / float(count);
}

// Point-in-polygon test (CPU-friendly for small polygon arrays)
bool pointInPolygon(float2 uv, device const float2* points, constant uint &count) {
    bool inside = false;
    uint j = count - 1;
    for(uint i = 0; i < count; i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        if (((pi.y > uv.y) != (pj.y > uv.y)) &&
            (uv.x < (pj.x - pi.x) * (uv.y - pi.y) / (pj.y - pi.y + 0.00001) + pi.x)) {
            inside = !inside;
        }
        j = i;
    }
    return inside;
}

fragment float4 LipsOuterSmoothShader(VertexOut vert [[stage_in]],
                                      texture2d<float> inputTexture [[texture(0)]],
                                      sampler textureSampler [[sampler(0)]],
                                      device const float2* outerPoints [[buffer(0)]],
                                      constant uint &outerCount [[buffer(1)]],
                                      device const float2* innerPoints [[buffer(2)]],
                                      constant uint &innerCount [[buffer(3)]],
                                      constant float &outerBrightness [[buffer(4)]]) {
    
    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(textureSampler, uv);
    
    // 1️⃣ Compute distances to polygons
    float distOuter = distanceToPolygonEdges(uv, outerPoints, outerCount);
    float distInner = distanceToPolygonEdges(uv, innerPoints, innerCount);
    
    // 2️⃣ Feathering radius
    float outerRadius = 0.012; // smooth fade edge
    float innerRadius = 0.004;
    
    bool insideOuter = pointInPolygon(uv, outerPoints, outerCount);
    bool insideInner = pointInPolygon(uv, innerPoints, innerCount);
    
    float featherOuter = smoothstep(outerRadius, 0.0, distOuter);
    float featherInner = smoothstep(innerRadius, 0.0, distInner);
    
    // Ensure mask is only inside outer polygon but not inside inner polygon
    float mask = 0.0;
    
    mask = clamp(featherOuter * (1.0 - featherInner), 0.0, 1.0);
    
    if(mask > 0.0){
        // 3️⃣ Subtle additive brightness
        float additive = -outerBrightness * 0.0005;
        color.rgb += additive * mask;
        
        // 4️⃣ Slight contrast boost
        float contrast = 1.08;
        color.rgb = (color.rgb - 0.5) * contrast * mask + 0.5 * mask + color.rgb*(1.0-mask);
        
        // 5️⃣ Pink tint
        //float3 lipsTint = float3(1.0,0.55,0.55);
        //color.rgb = mix(color.rgb, lipsTint, 0.04*mask);
        
        // 6️⃣ Saturation boost
        float3 hsl = rgb2hsl(color.rgb);
        hsl.y *= 1.05*mask + (1.0-mask);
        color.rgb = hsl2rgb(hsl);
    }
    
    return color;
}



