//
//  EyelashEffectV2.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 17/9/25.
//

#include <metal_stdlib>
#include "MTIShaderLib.h"
using namespace metalpetal;


// --- Helpers ---

// Inflate a point from the center by a small amount
inline float2 inflatedPoint(float2 p, float2 center, float inflateAmount) {
    float2 dir = p - center;
    float len = length(dir);
    if (len > 0.0) {
        return p + (dir / len) * inflateAmount;
    }
    return p;
}

// Point-in-polygon test with inflated points
inline bool pointInPolygonInflated(float2 uv, device const float2 *points, uint count, float2 center, float inflateAmount) {
    bool inside = false;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 pi = inflatedPoint(points[i], center, inflateAmount);
        float2 pj = inflatedPoint(points[j], center, inflateAmount);
        if (((pi.y > uv.y) != (pj.y > uv.y)) &&
            (uv.x < (pj.x - pi.x) * (uv.y - pi.y) / (pj.y - pi.y + 1e-6) + pi.x)) {
            inside = !inside;
        }
    }
    return inside;
}

// Distance to polygon edges with inflated points
inline float distanceToPolygonInflated(float2 uv, device const float2 *points, uint count, float2 center, float inflateAmount) {
    float minDist = 1e6;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 p1 = inflatedPoint(points[j], center, inflateAmount);
        float2 p2 = inflatedPoint(points[i], center, inflateAmount);
        float2 edge = p2 - p1;
        float2 toPoint = uv - p1;
        float t = clamp(dot(toPoint, edge) / (dot(edge, edge) + 1e-6), 0.0, 1.0);
        float2 proj = p1 + t * edge;
        minDist = min(minDist, distance(uv, proj));
    }
    return minDist;
}

float2 quadraticBezier(float2 p0, float2 p1, float2 p2, float t) {
    float u = 1.0 - t;
    return u*u*p0 + 2.0*u*t*p1 + t*t*p2;
}


bool pointInPolygon(float2 point, device const float2 *vertices, uint vertexCount) {
    bool inside = false;
    
    for (uint i = 0, j = vertexCount - 1; i < vertexCount; j = i, i++) {
        float2 vi = vertices[i];
        float2 vj = vertices[j];
        
        // Check if the point is between the y-coordinates of the edge
        if ((vi.y > point.y) != (vj.y > point.y)) {
            // Calculate the x-intersection of the edge with the horizontal line through the point
            float intersectX = (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x;
            
            // If the point is to the left of the intersection, toggle inside flag
            if (point.x < intersectX) {
                inside = !inside;
            }
        }
    }
    
    return inside;
}

float closestPointOnQuadraticBezier(float2 point, float2 p0, float2 p1, float2 p2) {
    // Convert quadratic Bezier to polynomial form: B(t) = (1-t)²P0 + 2(1-t)tP1 + t²P2
    // Then find t that minimizes distance to point
    float2 A = p0 - 2.0 * p1 + p2;
    float2 B = 2.0 * (p1 - p0);
    float2 C = p0 - point;
    
    // Coefficients for derivative: at² + bt + c = 0
    float a = dot(A, A);
    float b = 3.0 * dot(A, B);
    float c = 2.0 * dot(B, B) + dot(A, C);
    float d = dot(B, C);
    
    // Solve cubic equation (simplified)
    float t = 0.5; // Default to middle
    const int iterations = 4;
    for (int i = 0; i < iterations; i++) {
        float ft = a*t*t*t + b*t*t + c*t + d;
        float ft_deriv = 3.0*a*t*t + 2.0*b*t + c;
        if (abs(ft_deriv) > 1e-6) {
            t -= ft / ft_deriv;
        }
        t = clamp(t, 0.0, 1.0);
    }
    
    return t;
}

inline float softDistanceToPolygon(float2 uv,
                                   device const float2 *points,
                                   uint count,
                                   float2 center,
                                   float inflateAmount,
                                   float curve = 0.005) // controls smoothness of corners
{
    float minDist = 1e6;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 p1 = inflatedPoint(points[j], center, inflateAmount);
        float2 p2 = inflatedPoint(points[i], center, inflateAmount);
        float2 edge = p2 - p1;
        float2 toPoint = uv - p1;
        float t = clamp(dot(toPoint, edge) / (dot(edge, edge) + 1e-6), 0.0, 1.0);
        float2 proj = p1 + t * edge;
        float d = distance(uv, proj);

        // smooth corners by blending neighboring edges
        minDist = min(minDist, d - curve);
    }
    return max(minDist, 0.0); // ensure non-negative distance
}

// --- Fragment Shader ---
/*fragment float4 eyelashShader(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              constant float &scaleFactor [[buffer(0)]],   // কতটা dark হবে
                              device const float2 *points [[buffer(1)]],
                              constant uint &count [[buffer(2)]])
{
    /*constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
       float2 uv = vert.textureCoordinate;
       float4 color = inputTexture.sample(textureSampler, uv);

       // --- Polygon bounds & center ---
       float2 minPoint = points[0];
       float2 maxPoint = points[0];
       for (uint i = 1; i < count; i++) {
           minPoint = min(minPoint, points[i]);
           maxPoint = max(maxPoint, points[i]);
       }
       float2 center = (minPoint + maxPoint) * 0.5;

       // --- Texel size & inflation ---
       float2 texelSize = float2(1.0 / float(inputTexture.get_width()),
                                 1.0 / float(inputTexture.get_height()));
       float inflateAmount = max(texelSize.x, texelSize.y) * 5.5;

       // --- Polygon inclusion ---
       bool inside = pointInPolygonInflated(uv, points, count, center, inflateAmount);
       if (!inside) return color;

       // --- Distance to polygon edges ---
       float dist = distanceToPolygonInflated(uv, points, count, center, inflateAmount);

       // --- Smooth anti-aliased edge mask ---
       float edgeWidth = max(texelSize.x, texelSize.y) * 1.0; // ~1 pixel
       float edgeMask = exp(-pow(dist / edgeWidth, 2.0));     // Gaussian smoothing
       if (edgeMask <= 0.001) return color;                  // skip deep inside

       // --- Effect intensity ---
       float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
       float intensityMultiplier = (factor > 0.0) ? 0.8 : 0.9;
       float finalMask = edgeMask * abs(factor) * intensityMultiplier;

       // --- Eyelash color ---
       float3 lashColor = float3(1.0, 1.0, 1.0);
       color.rgb = mix(color.rgb, lashColor, finalMask);

       return color;*/
    
    /*constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
       float2 uv = vert.textureCoordinate;
       float4 color = inputTexture.sample(textureSampler, uv);

       // --- Simple polygon check ---
       bool inside = pointInPolygon(uv, points, count);
       
       if (inside) {
           // Just return a solid color for the polygon area
           return float4(1.0, 0.0, 0.0, 1.0); // Red color for visibility
       } else {
           return color; // Outside polygon → original texture
       }*/
    
   /* constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
       float2 uv = vert.textureCoordinate;
       float4 color = inputTexture.sample(textureSampler, uv);

       // --- Calculate distance to polygon edges ---
       float minDist = 100000.0;
       
       for (uint i = 0, j = count - 1; i < count; j = i, i++) {
           float2 p1 = points[i];
           float2 p2 = points[j];
           
           // Distance to line segment
           float2 lineDir = p2 - p1;
           float lineLength = length(lineDir);
           float2 lineUnit = lineDir / lineLength;
           
           float2 pointDir = uv - p1;
           float projection = dot(pointDir, lineUnit);
           projection = clamp(projection, 0.0, lineLength);
           
           float2 closestPoint = p1 + lineUnit * projection;
           float dist = distance(uv, closestPoint);
           minDist = min(minDist, dist);
       }

       // --- Create shadow effect only on edges ---
       float shadowWidth = 0.02; // Shadow width - adjust as needed
       float shadowIntensity = 0.7; // How dark the shadow is
       
       // Smooth shadow falloff from edge
       float shadow = smoothstep(0.0, shadowWidth, minDist);
       shadow = 1.0 - shadow; // Invert so shadow is near edges
       
       // Apply shadow effect
       float3 shadowColor = color.rgb * (1.0 - shadow * shadowIntensity);
       
       return float4(shadowColor, color.a);*/
    
    /*constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
        float2 uv = vert.textureCoordinate;
        float4 color = inputTexture.sample(textureSampler, uv);

        // --- Calculate distance to polygon edges ---
        float minDist = 100000.0;
        
        for (uint i = 0, j = count - 1; i < count; j = i, i++) {
            float2 p1 = points[i];
            float2 p2 = points[j];
            
            float2 lineDir = p2 - p1;
            float lineLength = length(lineDir);
            float2 lineUnit = lineDir / lineLength;
            
            float2 pointDir = uv - p1;
            float projection = dot(pointDir, lineUnit);
            projection = clamp(projection, 0.0, lineLength);
            
            float2 closestPoint = p1 + lineUnit * projection;
            float dist = distance(uv, closestPoint);
            minDist = min(minDist, dist);
        }

        // --- Softer shadow effect ---
        float normalizedFactor = (scaleFactor + 100.0) / 200.0;
        
        // Softer values for more subtle effect
        float shadowWidth = mix(0.008, 0.01, normalizedFactor); // Narrower range
        float shadowIntensity = mix(0.2, 0.6, normalizedFactor); // Lighter intensity

        // Gaussian-like smooth falloff
        float shadow = exp(-pow(minDist / shadowWidth, 2.0));
        
        // Apply very subtle shadow
        float3 shadowColor = color.rgb * (1.0 - shadow * shadowIntensity * 0.5);
        
        return float4(shadowColor, color.a);*/
    
    /*constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(textureSampler, uv);

    // --- Calculate distance to polygon edges ---
    float minDist = 100000.0;

    // small Y-offset to lower the top curve (~0.001 UV units)
    float yOffset = 0.001;

    for (uint i = 0, j = count - 1; i < count; j = i, i++) {
        float2 p1 = points[i];
        float2 p2 = points[j];

        // lower top points
        p1.y += yOffset;
        p2.y += yOffset;

        float2 lineDir = p2 - p1;
        float lineLength = length(lineDir);
        float2 lineUnit = lineDir / lineLength;

        float2 pointDir = uv - p1;
        float projection = dot(pointDir, lineUnit);
        projection = clamp(projection, 0.0, lineLength);

        float2 closestPoint = p1 + lineUnit * projection;
        float dist = distance(uv, closestPoint);
        minDist = min(minDist, dist);
    }

    // --- Softer shadow effect ---
    float normalizedFactor = (scaleFactor + 100.0) / 200.0;

    // shadow width same, intensity smaller for lighter effect
    float shadowWidth = mix(0.004, 0.006, normalizedFactor);
    float shadowIntensity = mix(0.05, 0.15, normalizedFactor); // lighter than before

    // Gaussian-like smooth falloff
    float shadow = exp(-pow(minDist / shadowWidth, 2.0));

    // Apply very subtle shadow
    float3 shadowColor = color.rgb * (1.0 - shadow * shadowIntensity);

    return float4(shadowColor, color.a);*/
    
    /*constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(textureSampler, uv);

    // --- Polygon bounds & center ---
    float2 minPoint = points[0];
    float2 maxPoint = points[0];
    for (uint i = 1; i < count; i++) {
        minPoint = min(minPoint, points[i]);
        maxPoint = max(maxPoint, points[i]);
    }
    float2 center = (minPoint + maxPoint) * 0.5;

    // --- Texel size & inflation ---
    float2 texelSize = float2(1.0 / float(inputTexture.get_width()),
                              1.0 / float(inputTexture.get_height()));
    float inflateAmount = max(texelSize.x, texelSize.y) * 4.0;

    // --- Soft distance field ---
    float dist = softDistanceToPolygon(uv, points, count, center, inflateAmount, 0.002);

    // --- Edge mask for smooth border ---
    float edgeWidth = max(texelSize.x, texelSize.y) * 2.0;
    float edgeMask = smoothstep(edgeWidth, 0.0, dist);
    if (edgeMask <= 0.01) return color;

    // --- Effect intensity ---
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
    float intensity = abs(factor) * edgeMask;

    // --- Eyelash color ---
    float3 lashColor = float3(0.1, 0.05, 0.02);

    if (factor > 0.0) {
        color.rgb = mix(color.rgb, lashColor, intensity * 0.8);
    } else {
        float3 lightened = color.rgb * 1.3;
        color.rgb = mix(color.rgb, lightened, intensity * 0.6);
    }

    return color;*/
    /*constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 color = baseColor.rgb;
    float alpha = baseColor.a;
    if (alpha < 0.01) return baseColor;

    // --- Find top of curve for vertical falloff ---
    float topY = points[0].y;
    for (uint i = 1; i < count; i++) topY = min(topY, points[i].y);

    // --- Minimal distance to quadratic curve ---
    float minDist = 1e6;
    for (uint i = 0; i + 2 < count; i += 2) {
        float2 p0 = points[i];
        float2 p1 = points[i + 1];
        float2 p2 = points[(i + 2) % count];

        const int steps = 32;
        for (int s = 0; s <= steps; s++) {
            float t = float(s) / float(steps);
            float2 curvePt = quadraticBezier(p0, p1, p2, t);
            float d = distance(uv, curvePt);
            minDist = min(minDist, d);
        }
    }

    // --- Shadow parameters ---
    float shadowWidth = 0.004;          // horizontal softness
    float baseShadowStrength = 0.3;     // max shadow
    float shadowHeight = 0.05;          // vertical fade

    // --- Scale shadow with scaleFactor ---
    float normalizedFactor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    float shadowStrength = baseShadowStrength * normalizedFactor;

    // --- Shadow mask with vertical fade ---
    float verticalFalloff = clamp((uv.y - topY)/shadowHeight, 0.0, 1.0);
    float shadowMask = smoothstep(shadowWidth, 0.0, minDist) * shadowStrength * (1.0 - verticalFalloff);

    // --- Apply shadow only ---
    float3 shadowColor = float3(0.0, 0.0, 0.0);
    color = mix(color, shadowColor, shadowMask);

    return float4(color, alpha);
    
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 color = baseColor.rgb;
    float alpha = baseColor.a;
    if (alpha < 0.01) return baseColor;

    // --- Find top of curve ---
    float topY = points[0].y;
    for (uint i = 1; i < count; i++) topY = min(topY, points[i].y);

    // --- Better distance calculation ---
    float minDist = 1e6;
    for (uint i = 0; i + 2 < count; i += 2) {
        float2 p0 = points[i];
        float2 p1 = points[i + 1];
        float2 p2 = points[i + 2];

        const int steps = 32;
        for (int s = 0; s <= steps; s++) {
            float t = float(s) / float(steps);
            float2 curvePt = quadraticBezier(p0, p1, p2, t);
            float d = distance(uv, curvePt);
            minDist = min(minDist, d);
        }
    }

    // --- Realistic shadow parameters ---
    float shadowWidth = 0.01;           // Softer, wider shadow
    float baseShadowStrength = 1.2;      // More subtle
    float shadowHeight = 0.1;           // Taller falloff
    float softness = 0.008;              // Additional softness parameter

    float normalizedFactor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    float shadowStrength = baseShadowStrength * normalizedFactor;

    // --- Improved shadow mask ---
    float verticalFalloff = 1.0 - smoothstep(0.0, shadowHeight, uv.y - topY);
    float distanceFalloff = smoothstep(0.0, shadowWidth + softness, minDist);
    float shadowMask = (1.0 - distanceFalloff) * shadowStrength * verticalFalloff;

    // --- Realistic shadow color (not pure black) ---
    float3 shadowColor = color * 0.7; // Darken existing color instead of pure black

    // --- Apply shadow with better blending ---
    color = mix(color, shadowColor, shadowMask * 0.8); // Additional subtlety

    // --- Add subtle color temperature shift ---
    if (shadowMask > 0.01) {
        float3 coolShadow = color * float3(0.9, 0.95, 1.0); // Slightly bluish tint
        color = mix(color, coolShadow, shadowMask * 0.3);
    }

    return float4(color, alpha);

}*/

// --- Compute shadow mask for a set of points ---
float computeShadowMask(float2 uv,
                        device const float2 *pts,
                        uint cnt,
                        float scaleFactor)
{
    if (cnt < 3) return 0.0;

    // Find top Y
    float topY = pts[0].y;
    for (uint i = 1; i < cnt; i++) topY = min(topY, pts[i].y);

    // Minimal distance to quadratic curve
    float minDist = 1e6;
    for (uint i = 0; i + 2 < cnt; i += 2) {
        float2 p0 = pts[i];
        float2 p1 = pts[i + 1];
        float2 p2 = pts[i + 2];

        const int steps = 32;
        for (int s = 0; s <= steps; s++) {
            float t = float(s) / float(steps);
            float2 curvePt = quadraticBezier(p0, p1, p2, t);
            float d = distance(uv, curvePt);
            minDist = min(minDist, d);
        }
    }

    // Shadow parameters
    float shadowWidth = 0.01;
    float baseShadowStrength = 1.2;
    float shadowHeight = 0.1;
    float softness = 0.008;

    float normalizedFactor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    float shadowStrength = baseShadowStrength * normalizedFactor;

    float verticalFalloff = 1.0 - smoothstep(0.0, shadowHeight, uv.y - topY);
    float distanceFalloff = smoothstep(0.0, shadowWidth + softness, minDist);
    float mask = (1.0 - distanceFalloff) * shadowStrength * verticalFalloff;

    return mask;
}

// --- Eyelash Shader ---
fragment float4 eyelashShader(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              constant float &scaleFactor [[buffer(0)]],
                              device const float2 *rightUpPoints [[buffer(1)]],
                              device const float2 *rightDownPoints [[buffer(2)]],
                              device const float2 *leftUpPoints [[buffer(3)]],
                              device const float2 *leftDownPoints [[buffer(4)]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;
    float4 baseColor = inputTexture.sample(textureSampler, uv);
    float3 color = baseColor.rgb;
    float alpha = baseColor.a;

    if (alpha < 0.01) return baseColor;

    // --- Compute shadow mask for all 4 sets ---
    float maskRightUp   = computeShadowMask(uv, rightUpPoints, 7, scaleFactor);
    float maskRightDown = computeShadowMask(uv, rightDownPoints, 8, scaleFactor);
    float maskLeftUp    = computeShadowMask(uv, leftUpPoints, 7, scaleFactor);
    float maskLeftDown  = computeShadowMask(uv, leftDownPoints, 7, scaleFactor);

    float shadowMask = max(max(maskRightUp, maskRightDown), max(maskLeftUp, maskLeftDown));

    // --- Apply shadow color ---
    float3 shadowColor = color * 0.7; // darken existing color
    color = mix(color, shadowColor, shadowMask * 0.8);

    // --- Optional subtle color tint for shadow ---
    if (shadowMask > 0.01) {
        float3 coolShadow = color * float3(0.9, 0.95, 1.0);
        color = mix(color, coolShadow, shadowMask * 0.3);
    }

    return float4(color, alpha);
}


/*// --- Inflate a point from the center ---
inline float2 inflatedPoint(float2 p, float2 center, float inflateAmount) {
    float2 dir = p - center;
    float len = length(dir);
    if (len > 0.0) return p + (dir / len) * inflateAmount;
    return p;
}

// --- Soft distance to polygon edges with smooth corners ---
inline float softDistanceToPolygon(float2 uv,
                                   device const float2 *points,
                                   uint count,
                                   float2 center,
                                   float inflateAmount,
                                   float curve = 0.005) // controls smoothness of corners
{
    float minDist = 1e6;
    for (uint i = 0, j = count - 1; i < count; j = i++) {
        float2 p1 = inflatedPoint(points[j], center, inflateAmount);
        float2 p2 = inflatedPoint(points[i], center, inflateAmount);
        float2 edge = p2 - p1;
        float2 toPoint = uv - p1;
        float t = clamp(dot(toPoint, edge) / (dot(edge, edge) + 1e-6), 0.0, 1.0);
        float2 proj = p1 + t * edge;
        float d = distance(uv, proj);

        // smooth corners by blending neighboring edges
        minDist = min(minDist, d - curve);
    }
    return max(minDist, 0.0); // ensure non-negative distance
}

// --- Fragment shader ---
fragment float4 eyelashShader(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              constant float &scaleFactor [[buffer(0)]],
                              device const float2 *points [[buffer(1)]],
                              constant uint &count [[buffer(2)]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(textureSampler, uv);

    // --- Polygon bounds & center ---
    float2 minPoint = points[0];
    float2 maxPoint = points[0];
    for (uint i = 1; i < count; i++) {
        minPoint = min(minPoint, points[i]);
        maxPoint = max(maxPoint, points[i]);
    }
    float2 center = (minPoint + maxPoint) * 0.5;

    // --- Texel size & inflation ---
    float2 texelSize = float2(1.0 / float(inputTexture.get_width()),
                              1.0 / float(inputTexture.get_height()));
    float inflateAmount = max(texelSize.x, texelSize.y) * 4.0;

    // --- Soft distance field ---
    float dist = softDistanceToPolygon(uv, points, count, center, inflateAmount, 0.002);

    // --- Edge mask for smooth border ---
    float edgeWidth = max(texelSize.x, texelSize.y) * 2.0;
    float edgeMask = smoothstep(edgeWidth, 0.0, dist);
    if (edgeMask <= 0.01) return color;

    // --- Effect intensity ---
    float factor = clamp(scaleFactor / 100.0, -1.0, 1.0);
    float intensity = abs(factor) * edgeMask;

    // --- Eyelash color ---
    float3 lashColor = float3(0.1, 0.05, 0.02);

    if (factor > 0.0) {
        color.rgb = mix(color.rgb, lashColor, intensity * 0.8);
    } else {
        float3 lightened = color.rgb * 1.3;
        color.rgb = mix(color.rgb, lightened, intensity * 0.6);
    }

    return color;
}
*/

/*// --- Quadratic Bezier interpolation ---
inline float2 quadBezier(float2 p0, float2 p1, float2 p2, float t) {
    float u = 1.0 - t;
    return u*u*p0 + 2.0*u*t*p1 + t*t*p2;
}

// --- Tangent of a quad segment ---
inline float2 quadTangent(float2 p0, float2 p1, float2 p2, float t) {
    float u = 1.0 - t;
    return normalize(2.0*u*(p1 - p0) + 2.0*t*(p2 - p1));
}

// --- Distance + fade along normal ---
inline float distanceAndFadeAlongCurve(float2 uv,
                                       float2 p0, float2 p1, float2 p2,
                                       int steps, float inflate, float2 texelSize,
                                       float fadeLength,
                                       thread float &fadeMask) {
    float minDist = 1e6;
    float bestFade = 0.0;

    for (int i = 0; i <= steps; i++) {
        float t = float(i) / float(steps);
        float2 pos = quadBezier(p0, p1, p2, t);

        // tangent & normal
        float2 tangent = quadTangent(p0, p1, p2, t);
        float2 normal = normalize(float2(-tangent.y, tangent.x));

        // inflated position outward
        float2 inflatedPos = pos + normal * inflate * max(texelSize.x, texelSize.y);

        // distance
        float distUV = distance(uv, inflatedPos) / max(texelSize.x, texelSize.y);

        if (distUV < minDist) {
            minDist = distUV;

            // how far UV is *outside* along the normal
            float proj = dot(uv - pos, normal);
            bestFade = clamp(1.0 - proj / fadeLength, 0.0, 1.0);
        }
    }

    fadeMask = bestFade;
    return minDist;
}

fragment float4 eyelashShader(VertexOut vert [[stage_in]],
                              texture2d<float> inputTexture [[texture(0)]],
                              constant float &scaleFactor [[buffer(0)]],
                              device const float2 *points [[buffer(1)]],
                              constant uint &count [[buffer(2)]])
{
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    float2 uv = vert.textureCoordinate;
    float4 color = inputTexture.sample(s, uv);

    float2 texelSize = float2(1.0 / float(inputTexture.get_width()),
                              1.0 / float(inputTexture.get_height()));

    float inflateAmount = 5.0; // lash thickness
    int steps = 16;
    float fadeLength = 0.05;   // fade length along normal (tweak this)

    float minDist = 1e6;
    float fadeMask = 0.0;

    // --- Iterate over curve segments ---
    for (uint i = 0; i < count - 2; i += 2) {
        float2 p0 = points[i];
        float2 p1 = points[i+1];
        float2 p2 = points[i+2];

        float segFade = 0.0;
        float d = distanceAndFadeAlongCurve(uv, p0, p1, p2,
                                            steps, inflateAmount, texelSize,
                                            fadeLength, segFade);
        if (d < minDist) {
            minDist = d;
            fadeMask = segFade;
        }
    }

    // --- Edge mask ---
    float edgeMask = smoothstep(inflateAmount + 1.0, 0.0, minDist);
    if (edgeMask <= 0.01) return color;

    // --- Combine edge with fade along normal ---
    float finalMask = edgeMask * fadeMask;

    // --- Apply eyelash color ---
    float3 lashColor = float3(0.06, 0.03, 0.01);
    float factor = clamp(scaleFactor / 100.0, 0.0, 1.0);
    color.rgb = mix(color.rgb, lashColor, factor * finalMask);

    return color;
}
*/
