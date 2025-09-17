//
//  FacePFilterV2.metal
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 11/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;


/*inline float2 polygonEllipticalScalingSmoothFinal(float2 uv,
                                                  device const float2 *points,
                                                  uint count,
                                                  float scaleFactor) {
    // 1) Polygon bounds & center
    float2 minPoint = points[0];
    float2 maxPoint = points[0];
    for (uint i = 1; i < count; i++) {
        minPoint = min(minPoint, points[i]);
        maxPoint = max(maxPoint, points[i]);
    }
    float2 center = (minPoint + maxPoint) * 0.5;
    float2 size = maxPoint - minPoint;

    // 2) Extended bounds for smooth fade (15% extra)
    float2 extend = size * 0.15;
    float2 extendedMin = minPoint - extend;
    float2 extendedMax = maxPoint + extend;

    // 3) Early exit: UV completely outside polygon + extended bounds
    bool inExtended = all(uv >= extendedMin) && all(uv <= extendedMax);
    // Point-in-polygon test
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        if (((pi.y > uv.y) != (pj.y > uv.y)) &&
            (uv.x < (pj.x - pi.x) * (uv.y - pi.y) / (pj.y - pi.y + 1e-6) + pi.x)) {
            inside = !inside;
        }
    }
    if (!inside && !inExtended) {
        return uv; // skip pixels fully outside
    }

    // 4) Distance to polygon edges for smooth fade
    float minDist = 1e6;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 p1 = points[j];
        float2 p2 = points[i];
        float2 edge = p2 - p1;
        float2 toPoint = uv - p1;
        float t = clamp(dot(toPoint, edge) / (dot(edge, edge) + 1e-6), 0.0, 1.0);
        float2 proj = p1 + t * edge;
        minDist = min(minDist, distance(uv, proj));
    }
    float edgeFade = smoothstep(length(size) * 0.15, 0.0, minDist); // 1 inside, 0 at extended edge

    // 5) Elliptical Gaussian center weighting
    float2 diff = uv - center;
    float2 normDiff = diff / (size * 0.5 + 1e-6);
    float topSens = 1.75;
    float bottomSens = 1.25;
    float verticalBlend = smoothstep(-1.0, 1.0, normDiff.y);
    float anisotropicDist = length(float2(
        normDiff.x,
        normDiff.y / mix(topSens, bottomSens, verticalBlend)
    ));
    float centerFade = exp(-pow(anisotropicDist, 2.0)); // 1 at center, decays to 0

    // 6) Combined smooth mask
    float mask = edgeFade * centerFade;
    if (mask < 0.001) return uv; // early exit for negligible influence

    // 7) Adaptive scale
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.3) / 1.3;
    float maxScale = 0.15;
    float scale = 1.0 - normalizedScale * maxScale;

    // 8) Apply displacement along radial direction
    /*float dist = length(diff) ;//+ 1e-3; // add tiny epsilon to avoid zero at center
    //if (dist < 1e-5) return uv;
    float2 dir = diff / dist;
    float displacement = (scale - 1.0) * mask * dist;
    float2 displacedUV = uv + dir * displacement;
    
    float2 dir = diff;
    float dist = length(dir);
    if (dist < 1e-5) {
        // assign arbitrary direction to allow center to scale
        dir = float2(0.0, 1.0);
        dist = 1.0; // use normalized scale for center
    } else {
        dir /= dist; // normalize normally
    }

    // Apply displacement proportional to mask
    float2 displacement = (uv - center) * ((scale - 1.0) * mask);
    float2 displacedUV = uv + displacement;

    return displacedUV;
}*/

inline float2 polygonEllipticalScalingSmoothFinal(float2 uv,
                                                  device const float2 *points,
                                                  uint count,
                                                  float scaleFactor) {
    // 1) Polygon bounds & center
    float2 minPoint = points[0];
    float2 maxPoint = points[0];
    for (uint i = 1; i < count; i++) {
        minPoint = min(minPoint, points[i]);
        maxPoint = max(maxPoint, points[i]);
    }
    float2 center = (minPoint + maxPoint) * 0.5;
    float2 size = maxPoint - minPoint;

    // 2) Extended bounds for smooth fade (15% extra)
    float2 extend = size * 0.25;
    float2 extendedMin = minPoint - extend;
    float2 extendedMax = maxPoint + extend;

    // 3) Early exit: UV completely outside extended polygon
    bool inExtended = all(uv >= extendedMin) && all(uv <= extendedMax);

    // Point-in-polygon test
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = points[i];
        float2 pj = points[j];
        if (((pi.y > uv.y) != (pj.y > uv.y)) &&
            (uv.x < (pj.x - pi.x) * (uv.y - pi.y) / (pj.y - pi.y + 1e-6) + pi.x)) {
            inside = !inside;
        }
    }

    if (!inside && !inExtended) {
        return uv; // skip pixels fully outside
    }

    // 4) Distance to polygon edges for smooth fade in extended area
    float minDist = 1e6;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 p1 = points[j];
        float2 p2 = points[i];
        float2 edge = p2 - p1;
        float2 toPoint = uv - p1;
        float t = clamp(dot(toPoint, edge) / (dot(edge, edge) + 1e-6), 0.0, 1.0);
        float2 proj = p1 + t * edge;
        minDist = min(minDist, distance(uv, proj));
    }
    //float edgeFade = smoothstep(length(size) * 0.1, 0.0, minDist); // 1 inside, 0 at extended edge
    float fadeStart = length(size) * 0.1;
    float fadeEnd = 0.0;
    float edgeFadeLinear = clamp((fadeStart - minDist) / (fadeStart - fadeEnd), 0.0, 1.0);
    float edgeFade = smoothstep(0.0, 1.0, edgeFadeLinear);
    // 5) Adaptive scale
    float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
    normalizedScale = tanh(normalizedScale * 1.3) / 1.3;
    float maxScale = 0.1;
    float scale = 1.0 - normalizedScale * maxScale;

    // 6) Apply scaling relative to polygon center
    float2 diff = uv - center;
    float2 scaledUV = center + diff * scale;

    // 7) Blend scaled UV with original only in extended region
    float2 displacedUV;
    if (inside) {
        displacedUV = scaledUV; // full zoom inside polygon
    } else {
        displacedUV = mix(uv, scaledUV, edgeFade); // smooth fade in extended area
    }

    return displacedUV;
}

fragment float4 FacePFilterV2(VertexOut vert [[stage_in]],
                            texture2d<float, access::sample> inputTexture [[texture(0)]],
                            sampler textureSampler [[sampler(0)]],
                            constant float &faceScaleFactor [[buffer(0)]],
                            constant float2 &faceRectCenter [[buffer(1)]],
                            constant float2 &faceRectRadius [[buffer(2)]],
                            device const float2 *points [[buffer(3)]],
                            constant uint &count [[buffer(4)]])
{
    float2 uv = vert.textureCoordinate;
    
    float2 uvFace = polygonEllipticalScalingSmoothFinal(uv, points, count, faceScaleFactor);

    
    return inputTexture.sample(textureSampler, uvFace);
}
