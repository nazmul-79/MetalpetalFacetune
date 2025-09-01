//
//  chinScaleShader.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 20/8/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;


/*float2 closestJawPoint(float2 uv, device const float2 *points, uint count) {
    float minDist = 1e20;
    float2 closest = points[0];
    for(uint i = 0; i < count-1; i++) {
        float2 a = points[i];
        float2 b = points[i+1];
        float2 pa = uv - a;
        float2 ba = b - a;
        float h = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0);
        float2 p = a + ba*h;
        float d = distance(uv, p);
        if(d < minDist) {
            minDist = d;
            closest = p;
        }
    }
    return closest;
}

fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                device const float2 *centers [[buffer(0)]],
                                constant uint &count [[buffer(1)]],
                                constant float &lineWidth [[buffer(2)]],
                                constant float &chinScaleFactor [[buffer(3)]]) {
    
    constexpr sampler s (mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;
    
    // --- compute jaw center ---
    float2 center = float2(0.0, 0.0);
    for(uint i = 0; i < count; i++) {
        center += centers[i];
    }
    center /= float(count);
    
    // --- closest point on jaw curve ---
    float2 closest = closestJawPoint(uv, centers, count);
    float2 diff = uv - closest;
    
    // --- distance-based falloff ---
    float dist = length(diff);
    float falloff = 0.02; // adjust for smoothness
    float weight = exp(-pow(dist / falloff, 2.0));
    
    // --- zoom factor ---
    float normalizedScale = clamp(chinScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);
    float zoom = 1.0 - normalizedScale * weight * 0.15; // intensity
    
    float2 finalUV = center + (uv - center) * zoom;
    
    return inputTexture.sample(s, finalUV);
    
}*/



/*fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                device const float2 *centers [[buffer(0)]],
                                constant uint &count [[buffer(1)]],
                                constant float &lineWidth [[buffer(2)]],
                                constant float &chinScaleFactor [[buffer(3)]]) {

    constexpr sampler s (mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- compute jaw center ---
    float2 center = float2(0.0, 0.0);
    for(uint i = 0; i < count; i++) {
        center += centers[i];
    }
    center /= float(count);

    // --- closest point on jaw curve ---
    float2 closest = closestJawPoint(uv, centers, count);
    float2 diff = uv - closest;

    // --- distance-based falloff ---
    float dist = length(diff);
    float falloff = 0.01;
    float weight = exp(-pow(dist / falloff, 2.0));

    // --- normalized scale factor ---
    float normalizedScale = clamp(chinScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    // --- non-uniform zoom ---
    float zoomY = 1.0 - normalizedScale * weight * 0.15; // vertical
    float zoomX = 1.0 - normalizedScale * weight * 0.05; // horizontal

    float2 finalUV = center + float2((uv.x - center.x) * zoomX,
                                     (uv.y - center.y) * zoomY);

    return inputTexture.sample(s, finalUV);
}
*/

/*fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                device const float2 *centers [[buffer(0)]],
                                constant uint &count [[buffer(1)]],
                                constant float &lineWidth [[buffer(2)]],
                                constant float &chinScaleFactor [[buffer(3)]]) {

    constexpr sampler s (mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- closest point on jaw curve ---
    float2 closest = closestJawPoint(uv, centers, count);
    float2 diff = uv - closest;

    // --- distance-based falloff ---
    float dist = length(diff);
    float falloff = 0.008; // smaller = tighter effect
    float weight = exp(-pow(dist / falloff, 2.0));
    weight = clamp(weight, 0.0, 1.0); // ensure no overshoot

    // --- normalized scale factor ---
    float normalizedScale = clamp(chinScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.5);

    // --- non-uniform zoom anchored to jaw curve ---
    float zoomY = 1.0 - normalizedScale * weight * 0.15; // vertical stronger
    float zoomX = 1.0 - normalizedScale * weight * 0.05; // horizontal weaker

    float2 finalUV = closest + float2(diff.x * zoomX, diff.y * zoomY);

    return inputTexture.sample(s, finalUV);
}
*/

// Quad curve evaluation
/*float2 quadCurvePoint(float2 p0, float2 p1, float2 p2, float t) {
    float u = 1.0 - t;
    return u*u*p0 + 2.0*u*t*p1 + t*t*p2;
}


// Compute jaw center along smooth curve
float2 computeJawCenterAlongCurve(device const float2* jawPoints, uint count, uint samplesPerSegment) {
    float2 center = float2(0.0, 0.0);
    uint totalSamples = 0;

    for (uint i = 0; i < count-1; i++) {
        float2 p0 = jawPoints[i];
        float2 p2 = jawPoints[i+1];
        float2 p1 = (p0 + p2) * 0.5;

        for (uint s = 0; s < samplesPerSegment; s++) {
            float t = float(s) / float(samplesPerSegment);
            float2 pt = quadCurvePoint(p0, p1, p2, t);
            center += pt;
            totalSamples++;
        }
    }
    return center / float(totalSamples);
}

// Compute weight based on distance to curve
float pointWeightFromCurve(float2 uv, device const float2* jawPoints, uint count, uint samplesPerSegment, float radius) {
    float minDist = radius * 2.0;
    for (uint i = 0; i < count-1; i++) {
        float2 p0 = jawPoints[i];
        float2 p2 = jawPoints[i+1];
        float2 p1 = (p0 + p2) * 0.5;
        for (uint s = 0; s <= samplesPerSegment; s++) {
            float t = float(s)/float(samplesPerSegment);
            float2 pt = quadCurvePoint(p0,p1,p2,t);
            minDist = min(minDist, distance(uv, pt));
        }
    }
    return clamp(1.0 - minDist/radius, 0.0, 1.0);
}



/*fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                device const float2 *jawPoints [[buffer(0)]],
                                constant uint &count [[buffer(1)]],
                                constant float &lineWidth [[buffer(2)]],
                                constant float &chinScaleFactor [[buffer(3)]])
{
    constexpr sampler s (mag_filter::linear, min_filter::linear);
    
    float2 uv = vert.textureCoordinate;
    // --- compute jaw center along curve ---
    float2 jawCenter = computeJawCenterAlongCurve(jawPoints, count, 16);
    
    // --- compute weight from proximity to curve ---
    float weight = pointWeightFromCurve(uv, jawPoints, count, 16, 0.08); // radius adjust
    
    float scale = clamp(chinScaleFactor/100.0, -1.0, 1.0);
    float2 offset = uv - jawCenter;
    uv = jawCenter + offset * (1.0 - scale * weight);
    
    uv = clamp(uv, float2(0.0), float2(1.0));
    return inputTexture.sample(s, uv);
}
//

fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                device const float2 *jawPoints [[buffer(0)]],
                                constant uint &count [[buffer(1)]],
                                constant float &lineWidth [[buffer(2)]],
                                constant float &chinScaleFactor [[buffer(3)]])
{
    constexpr sampler s (mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- compute jaw center along curve ---
    float2 jawCenter = computeJawCenterAlongCurve(jawPoints, count, 16);

    // --- compute weight from proximity to curve ---
    float rawWeight = pointWeightFromCurve(uv, jawPoints, count, 16, 0.05); // smaller radius
    float weight = pow(rawWeight, 2.0); // reduce effect for inner points

    // --- normalize scale ---
    float scale = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.15;

    // --- optional horizontal / vertical emphasis ---
    float horizFactor = 0.7;
    float vertFactor = 1.3;

    float2 offset = uv - jawCenter;
    uv = jawCenter + float2(
        offset.x * (1.0 - scale * weight * horizFactor),
        offset.y * (1.0 - scale * weight * vertFactor)
    );

    uv = clamp(uv, float2(0.0), float2(1.0));
    return inputTexture.sample(s, uv);
}

*/


// আগের quadCurvePoint ফাংশনের আর প্রয়োজন নেই যদি লাইন সেগমেন্ট ব্যবহার করেন

// Helper for distance calculation from a point (p) to a line segment (v, w)




/*fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                 texture2d<float> inputTexture [[texture(0)]],
                                 device const float2 *jawPoints [[buffer(0)]],
                                 constant uint &count [[buffer(1)]],
                                 constant float &lineWidth [[buffer(2)]], // Not used, but kept for signature
                                 constant float &chinScaleFactor [[buffer(3)]],
                                 constant float2 &jawCenter [[buffer(4)]]) // Pre-calculated jawCenter
{
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- compute weight from proximity to line segments (Optimized) ---
    float radius = 0.08; // Radius can be adjusted
    float rawWeight = pointWeightFromLineSegments(uv, jawPoints, count, radius);
    float weight = pow(rawWeight, 2.0); // Make the effect stronger near the line

    // --- normalize scale ---
    // A smaller multiplier for a more subtle effect
    float scale = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.1;

    // --- Apply uniform scale to avoid stretching ---
    float2 offset = uv - jawCenter;
    uv = jawCenter + offset * (1.0 - scale * weight);

    uv = clamp(uv, float2(0.0), float2(1.0));
    return inputTexture.sample(s, uv);
}

*/

/*fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                 texture2d<float> inputTexture [[texture(0)]],
                                 device const float2 *jawPoints [[buffer(0)]],
                                 constant uint &count [[buffer(1)]],
                                 constant float &lineWidth [[buffer(2)]],
                                 constant float &chinScaleFactor [[buffer(3)]],
                                 constant float2 &jawCenter [[buffer(4)]])
{
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- optimized weight from jaw line segments ---
    float radius = 0.08;
    float rawWeight = pointWeightFromLineSegments(uv, jawPoints, count, radius);

    // --- smoother falloff ---
    float weight = rawWeight * rawWeight * (3.0 - 2.0 * rawWeight);

    // --- scale factor ---
    float scale = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.08;

    // --- axis weighting ---
    float horizFactor = 0.5;
    float vertFactor  = 1.0;

    float2 offset = uv - jawCenter;
    uv = jawCenter + float2(
        offset.x * (1.0 - scale * weight * horizFactor),
        offset.y * (1.0 - scale * weight * vertFactor)
    );

    uv = clamp(uv, float2(0.0), float2(1.0));
    return inputTexture.sample(s, uv);
}
*/

// Optimized weight calculation using line segments



/*fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                 texture2d<float> inputTexture [[texture(0)]],
                                 device const float2 *jawPoints [[buffer(0)]],
                                 constant uint &count [[buffer(1)]],
                                 constant float &lineWidth [[buffer(2)]],
                                 constant float &chinScaleFactor [[buffer(3)]],
                                 constant float2 &jawCenter [[buffer(4)]])
{
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- optimized weight from jaw line segments ---
    float radius = 0.08;
    float rawWeight = pointWeightFromLineSegments(uv, jawPoints, count, radius);

    // --- smoother falloff ---
    float weight = rawWeight * rawWeight * (3.0 - 2.0 * rawWeight);

    // --- scale factor ---
    float scale = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.1;

    // --- vertical only movement ---
    float2 offset = uv - jawCenter;
//    uv = float2(
//        uv.x, // horizontal unchanged
//        jawCenter.y + offset.y * (1.0 - scale * weight) // vertical only
//    );

        uv = float2(
            uv.x, // horizontal unchanged
            jawCenter.y + offset.y * (1.0 - scale * weight) // vertical only
        );
    uv = clamp(uv, float2(0.0), float2(1.0));
    return inputTexture.sample(s, uv);
}
*/

/*fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                device const float2 *jawPoints [[buffer(0)]],
                                constant uint &count [[buffer(1)]],
                                constant float &lineWidth [[buffer(2)]],
                                constant float &chinScaleFactor [[buffer(3)]],
                                constant float2 &jawCenter [[buffer(4)]])
{
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- weight from jaw line segments ---
    float radius = 0.06;
    float rawWeight = pointWeightFromLineSegments(uv, jawPoints, count, radius);

    // --- smooth falloff ---
    float weight = rawWeight * rawWeight * (3.0 - 2.0 * rawWeight);

    // --- reduced scale factors to avoid stretch ---
    float horizScale = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.02; // smaller horizontal
    float vertScale  = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.04; // much smaller vertical

    // --- compute offset from jaw center ---
    float2 offset = uv - jawCenter;

    // --- apply horizontal and vertical scaling ---
    uv.x = uv.x + offset.x * horizScale * weight;
    uv.y = jawCenter.y + offset.y * (1.0 - vertScale * weight);

    uv = clamp(uv, float2(0.0), float2(1.0));
    return inputTexture.sample(s, uv);
}
*/

/*fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                device const float2 *jawPoints [[buffer(0)]],
                                constant uint &count [[buffer(1)]],
                                constant float &lineWidth [[buffer(2)]],
                                constant float &chinScaleFactor [[buffer(3)]],
                                constant float2 &jawCenter [[buffer(4)]])
{
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- weight from jaw line segments ---
    float radius = 0.06;
    float rawWeight = pointWeightFromLineSegments(uv, jawPoints, count, radius);

    // --- smooth falloff ---
    float weight = rawWeight * rawWeight * (3.0 - 2.0 * rawWeight);

    // --- scale factors (reduced) ---
    float horizScale = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.20;
    float vertScale  = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.06;

    // --- compute offset from jaw center ---
    float2 offset = uv - jawCenter;

    // --- additional fade near jaw edges ---
    // project uv along jaw curve index ratio
    float minX = jawPoints[0].x;
    float maxX = jawPoints[count-1].x;
    float t = smoothstep(0.0, 1.0, (uv.x - minX) / (maxX - minX));
    
    // fade factor: 0 at edges, 1 at center
    float edgeFade = 1.0 - pow(abs(t - 0.5) * 2.0, 2.0);

    // --- apply horizontal and vertical scaling with fade ---
    uv.x = uv.x + offset.x * horizScale * weight * edgeFade;
    uv.y = jawCenter.y + offset.y * (1.0 - vertScale * weight);

    uv = clamp(uv, float2(0.0), float2(1.0));
    return inputTexture.sample(s, uv);
}
*/

float distanceToLineSegment(float2 p, float2 v, float2 w) {
    float l2 = distance_squared(v, w);
    if (l2 == 0.0) return distance(p, v);
    float t = max(0.0, min(1.0, dot(p - v, w - v) / l2));
    float2 projection = v + t * (w - v);
    return distance(p, projection);
}

float pointWeightFromLineSegments(float2 uv, device const float2* jawPoints, uint count, float radius) {
    float minDist = radius * 2.0; // Initialize with a large value
    for (uint i = 0; i < count - 1; i++) {
        minDist = min(minDist, distanceToLineSegment(uv, jawPoints[i], jawPoints[i+1]));
    }
    // Using smoothstep gives a nicer falloff than clamp(1.0 - minDist/radius, 0.0, 1.0)
    return 1.0 - smoothstep(0.0, radius, minDist);
}

/*fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                device const float2 *jawPoints [[buffer(0)]],
                                constant uint &count [[buffer(1)]],
                                constant float &lineWidth [[buffer(2)]],
                                constant float &chinScaleFactor [[buffer(3)]],
                                constant float2 &jawCenter [[buffer(4)]])
{
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- weight from jaw line segments ---
    float radius = 0.04;
    float rawWeight = pointWeightFromLineSegments(uv, jawPoints, count, radius);

    // --- smooth falloff ---
    float weight = rawWeight * rawWeight * (3.0 - 1.5 * rawWeight);

    // --- scale factors ---
    float horizScale = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.20;
    float vertScale  = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.04;

    // --- compute offset from jaw center ---
    float2 offset = uv - jawCenter;

    // --- additional fade near jaw edges ---
    float minX = jawPoints[0].x;
    float maxX = jawPoints[count-1].x;
    float t = smoothstep(0.0, 1.0, (uv.x - minX) / (maxX - minX));
    float edgeFade = 1.0 - pow(abs(t - 0.5) * 2.0, 2.0);

    // --- apply horizontal and vertical scaling with fade ---
    uv.x = uv.x - offset.x * horizScale * weight * edgeFade;     // <-- flip sign
    uv.y = jawCenter.y + offset.y * (1.0 + vertScale * weight);  // <-- use + instead of -

    uv = clamp(uv, float2(0.0), float2(1.0));
    return inputTexture.sample(s, uv);
}*/

/*fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                device const float2 *jawPoints [[buffer(0)]],
                                constant uint &count [[buffer(1)]],
                                constant float &lineWidth [[buffer(2)]],
                                constant float &chinScaleFactor [[buffer(3)]],
                                constant float2 &jawCenter [[buffer(4)]])
{
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- normalized scale ---
    float normalizedScale = clamp(chinScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.0);

    float radius = 0.05; // radius around jaw line
    float rawWeight = pointWeightFromLineSegments(uv, jawPoints, count, radius);
    float weight = rawWeight * rawWeight * (3.0 - 2.0*rawWeight); // smooth falloff

    // --- max scale ---
    float maxScaleH = 0.1; // horizontal scale
    float maxScaleV = 0.05; // vertical scale

    // --- apply horizontal and vertical scaling ---
    float2 newUV;
    newUV.x = mix(uv.x, jawCenter.x, normalizedScale * maxScaleH * weight);
    newUV.y = mix(uv.y, jawCenter.y, normalizedScale * maxScaleV * weight);

    newUV = clamp(newUV, float2(0.0), float2(1.0));
    return inputTexture.sample(s, newUV);
}
*/

//Final Version
fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                device const float2 *jawPoints [[buffer(0)]],
                                constant uint &count [[buffer(1)]],
                                constant float &lineWidth [[buffer(2)]],
                                constant float &chinScaleFactor [[buffer(3)]],
                                constant float2 &jawCenter [[buffer(4)]])
{
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- normalized scale ---
    float normalizedScale = clamp(chinScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.0);

    // --- weight from jaw line segments ---
    float radius = 0.05; // radius around jaw line
    float rawWeight = pointWeightFromLineSegments(uv, jawPoints, count, radius);
    float weight = rawWeight * rawWeight * (3.0 - 2.0*rawWeight); // smooth falloff

    float minX = jawPoints[0].x;
    float maxX = jawPoints[count-1].x;
    float t = smoothstep(0.0, 1.0, (uv.x - minX) / (maxX - minX));
    float edgeFade = 1.0 - pow(abs(t - 0.5) * 2.0, 2.0);

    // --- max scale ---
    float maxScaleH = 0.3;  // horizontal scale
    float maxScaleV = 0.08; // vertical scale

    // --- apply horizontal and vertical scaling ---
    float2 newUV;
    newUV.x = mix(uv.x, jawCenter.x, normalizedScale * maxScaleH * weight * edgeFade);
    newUV.y = mix(uv.y, jawCenter.y, normalizedScale * maxScaleV * weight);

    newUV = clamp(newUV, float2(0.0), float2(1.0));
    return inputTexture.sample(s, newUV);
}




/*
float distanceToLineSegment(float2 p, float2 v, float2 w) {
    float l2 = distance_squared(v, w);
    if (l2 == 0.0) return distance(p, v);
    float t = max(0.0, min(1.0, dot(p - v, w - v) / l2));
    float2 projection = v + t * (w - v);
    return distance(p, projection);
}

float pointWeightFromLineSegments(float2 uv, device const float2* jawPoints, uint count, float radius) {
    float minDist = radius * 2.0; // Initialize with large value
    for (uint i = 0; i < count - 1; i++) {
        minDist = min(minDist, distanceToLineSegment(uv, jawPoints[i], jawPoints[i+1]));
    }
    return 1.0 - smoothstep(0.0, radius, minDist); // smooth falloff
}

fragment float4 chinScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                device const float2 *jawPoints [[buffer(0)]],
                                constant uint &count [[buffer(1)]],
                                constant float &lineWidth [[buffer(2)]],
                                constant float &chinScaleFactor [[buffer(3)]],
                                constant float2 &jawCenter [[buffer(4)]])
{
    constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
    float2 uv = vert.textureCoordinate;

    // --- compute local weight for jaw area ---
    float radius = 0.03;
    float rawWeight = pointWeightFromLineSegments(uv, jawPoints, count, radius);
    float weight = pow(rawWeight, 0.5); // stronger central effect

    // --- scale factors (clamped to avoid distortion) ---
    float horizScale = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.8;
    float vertScale  = clamp(chinScaleFactor / 100.0, -1.0, 1.0) * 0.5;

    // --- compute offset from jaw center ---
    float2 offset = uv - jawCenter;

    // --- edge fade along jaw line ---
    float minX = jawPoints[0].x;
    float maxX = jawPoints[count-1].x;
    float t = smoothstep(0.0, 1.0, (uv.x - minX) / (maxX - minX));
    float edgeFade = 1.0 - abs(t - 0.5) * 2.0; // linear fade from center

    // --- apply scaling with clamps to prevent over-stretching ---
    float maxHorizOffset = 0.01; // max horizontal UV displacement
    float maxVertScale   = 0.01; // max vertical scaling
    uv.x = uv.x - clamp(offset.x * horizScale * weight * edgeFade, -maxHorizOffset, maxHorizOffset);
    uv.y = jawCenter.y + offset.y * (1.0 + clamp(vertScale * weight, -maxVertScale, maxVertScale));

    uv = clamp(uv, float2(0.0), float2(1.0));
    return inputTexture.sample(s, uv);
}

*/


/*float2 scaleUVForJaw(float2 uv,
                     float2 jawCenter,
                     float2 jawRadiusXY,
                     float jawScaleFactor,
                     float sideBias,       // -1: left, 0: both, 1: right
                     float verticalTaper)  // 0..1
{
    float2 diff = uv - jawCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(jawScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2);

    // Gaussian-like falloff
    float2 normDiff = diff / jawRadiusXY;
    float dist = length(normDiff);
    float weight = exp(-pow(dist, 2.0));

    // vertical taper: 1.0 at bottom (chin), fades upward
    float vWeight = mix(1.0, saturate((diff.y + jawRadiusXY.y)/(2.0*jawRadiusXY.y)), verticalTaper);

    // side bias: emphasize left/right
    float sideFactor = smoothstep(-1.0, 1.0, diff.x / jawRadiusXY.x);
    sideFactor = mix(1.0 - sideFactor, sideFactor, (sideBias + 1.0) * 0.5);

    float maxScale = 0.25; // max jaw enlarge/pinch
    float scale = 1.0 + normalizedScale * maxScale * weight * vWeight * sideFactor;

    float2 newUV = jawCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}
*/

/*float2 scaleUVForJaw(float2 uv,
                     float2 jawCenter,
                     float2 jawRadiusXY,
                     float jawScaleFactor,
                     float sideBias,       // -1: left, 0: both, 1: right
                     float verticalTaper)  // 0..1
{
    float2 diff = uv - jawCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(jawScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2);

    // horizontal Gaussian falloff
    float xDist = diff.x / jawRadiusXY.x;
    float weightX = exp(-pow(xDist*1.1, 2.0)); // slightly stronger side effect

    // vertical Gaussian taper: restrict top, allow bottom
    float yDist = diff.y / jawRadiusXY.y;
    float weightY = exp(-pow(yDist / (1.0 - verticalTaper), 2.0));

    // combine horizontal & vertical
    float weight = weightX * weightY;

    // side bias
    float sideFactor = smoothstep(-1.0, 1.0, diff.x / jawRadiusXY.x);
    sideFactor = mix(1.0 - sideFactor, sideFactor, (sideBias + 1.0) * 0.5);

    float maxScale = 0.25;
    float scale = 1.0 + normalizedScale * maxScale * weight * sideFactor;

    float2 newUV = jawCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}*/

/*float2 scaleUVForJaw(float2 uv,
                     float2 jawCenter,
                     float2 jawRadiusXY,
                     float jawScaleFactor,
                     float sideBias,       // -1: left, 0: both, 1: right
                     float verticalTaper)  // 0..1
{
    float2 diff = uv - jawCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(jawScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2);

    // horizontal Gaussian falloff for sides
    float xDist = diff.x / jawRadiusXY.x;
    float weightX = exp(-pow(xDist*1.2, 2.0));

    // vertical mask: only affect lower jaw (y > 0)
    float yNorm = diff.y / jawRadiusXY.y; // -1 top, 0 center, 1 bottom
    float weightY = smoothstep(0.0, 1.0, yNorm*(1.0 - verticalTaper));

    float weight = weightX * weightY;

    // side bias for left/right emphasis
    float sideFactor = smoothstep(-1.0, 1.0, diff.x / jawRadiusXY.x);
    sideFactor = mix(1.0 - sideFactor, sideFactor, (sideBias + 1.0) * 0.5);

    float maxScale = 0.25;
    float scale = 1.0 + normalizedScale * maxScale * weight * sideFactor;

    // scale only the lower jaw region
    float2 newUV = jawCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}

*/

/*float2 scaleUVForJaw(float2 uv,
                     float2 jawCenter,
                     float2 jawRadiusXY,
                     float jawScaleFactor,
                     float sideBias,
                     float verticalTaper)
{
    float2 diff = uv - jawCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(jawScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2);

    // horizontal Gaussian for sides (flatter so corners move)
    float xDist = diff.x / jawRadiusXY.x;
    float weightX = exp(-pow(xDist*0.9, 2.0)); // wider horizontal falloff

    // vertical Gaussian: control bottom taper
    float yDist = diff.y / jawRadiusXY.y; // -1 top, 0 center, 1 bottom
    float weightY = exp(-pow((yDist - 0.2) / (1.0 - verticalTaper), 2.0));
    // note: shifted 0.2 upward to reduce excessive lower effect

    float weight = weightX * weightY;

    // side bias for left/right
    float sideFactor = smoothstep(-1.0, 1.0, diff.x / jawRadiusXY.x);
    sideFactor = mix(1.0 - sideFactor, sideFactor, (sideBias + 1.0) * 0.5);

    float maxScale = 0.25;
    float scale = 1.0 + normalizedScale * maxScale * weight * sideFactor;

    float2 newUV = jawCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}
*/

/*float2 scaleUVForJaw(float2 uv,
                     float2 jawCenter,
                     float2 jawRadiusXY,
                     float jawScaleFactor,
                     float sideBias,
                     float verticalTaper)
{
    float2 diff = uv - jawCenter;

    // normalize slider -100..100 → -1..1
    float normalizedScale = clamp(jawScaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.2);

    // horizontal weight: flatter for corners
    float xDist = diff.x / jawRadiusXY.x;
    float weightX = exp(-pow(xDist*0.7, 2.0)); // 0.7 instead of 0.9 → flatter

    // vertical Gaussian: smoother top/bottom
    float yDist = diff.y / jawRadiusXY.y;
    float weightY = exp(-pow(yDist / (1.0 - verticalTaper*0.8), 2.0)); // softer taper

    float weight = weightX * weightY;

    // side bias
    float sideFactor = smoothstep(-1.0, 1.0, diff.x / jawRadiusXY.x);
    sideFactor = mix(1.0 - sideFactor, sideFactor, (sideBias + 1.0) * 0.5);

    float maxScale = 0.25;
    float scale = 1.0 + normalizedScale * maxScale * weight * sideFactor;

    float2 newUV = jawCenter + diff / scale;

    return clamp(newUV, 0.0, 1.0);
}
*/
