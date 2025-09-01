//
//  LipsMetalFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 13/8/25.
//

/*import UIKit
import MetalPetal

class EyeMetalFilter: NSObject, MTIFilter {
    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?
    var scaleFactor: Float = 0.0
    var eyeCenter: SIMD2<Float> = SIMD2<Float>(0.5, 0.5)
    var eyeRadius: Float = 0.1
    
    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "eyeScaleShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                           fragmentFunctionDescriptor: fragmentDescriptor)
    }()
    
    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }
        
        // শেডার প্যারামিটারসেট করা
        let parameters: [String: Any] = [
            "scaleFactor": scaleFactor,
            "eyeCenter": eyeCenter,
            "eyeRadiusXY": eyeRadius
        ]
        
        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
*/

/*import UIKit
import MetalPetal

class EyeMetalFilter: NSObject, MTIFilter {
    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?
    var scaleFactor: Float = 0.0
    var eyeCenter: SIMD2<Float> = SIMD2<Float>(0.5, 0.5)
    var eyeRadiusXY: SIMD2<Float> = SIMD2<Float>(0.1, 0.1)
    
    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "eyeScaleShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()
    
    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }
        
        let parameters: [String: Any] = [
            "scaleFactor": scaleFactor,
            "eyeCenter": eyeCenter,
            "eyeRadiusXY": eyeRadiusXY
        ]
        
        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
*/

import UIKit
import MetalPetal

class EyeMetalFilter: NSObject, MTIFilter {

    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?

    // Left eye
    var leftEyeCenter: SIMD2<Float> = SIMD2<Float>(0.35, 0.5)
    var leftEyeRadiusXY: SIMD2<Float> = SIMD2<Float>(0.1, 0.1)
    var leftScaleFactor: Float = 0.0

    // Right eye
    var rightEyeCenter: SIMD2<Float> = SIMD2<Float>(0.65, 0.5)
    var rightEyeRadiusXY: SIMD2<Float> = SIMD2<Float>(0.1, 0.1)
    var rightScaleFactor: Float = 0.0

    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "eyeScaleShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()

    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }

        let parameters: [String: Any] = [
            "leftScaleFactor": leftScaleFactor,
            "rightScaleFactor": rightScaleFactor,
            "leftEyeCenter": leftEyeCenter,
            "rightEyeCenter": rightEyeCenter,
            "leftEyeRadiusXY": leftEyeRadiusXY,
            "rightEyeRadiusXY": rightEyeRadiusXY
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}


/*
 #include <metal_stdlib>
 #include "MTIShaderLib.h"
 using namespace metalpetal;

 // --- Helper for smooth, visible eye scaling ---
 float2 scaledUVForEye(float2 uv, float2 center, float2 radiusXY, float scaleFactor) {
     float2 diff = uv - center;

     // elliptical normalized distance
     float dx = diff.x / radiusXY.x;
     float dy = diff.y / radiusXY.y;
     float dist = sqrt(dx*dx + dy*dy);

     // normalize slider: -100..100 → -1..1
     float normalizedScale = clamp(scaleFactor / 100.0, -1.0, 1.0);
     normalizedScale = tanh(normalizedScale * 1.5); // stronger mapping

     // Gaussian-like falloff
     float outerFalloff = 2.0; // larger radius for outer influence
     float weight = exp(-pow(dist / outerFalloff, 2.0) * 2.0); // slower falloff

     // separate X/Y scaling
     float2 xyMultiplier = float2(1.0, 0.85);
     float maxScaleFactor = 0.4; // increase scaling for more visible effect
     float2 s = 1.0 + normalizedScale * maxScaleFactor * weight * xyMultiplier;

     float2 newUV = center + float2(diff.x / s.x, diff.y / s.y);

     // blend with original UV for smooth edges
     float2 safeUV = mix(uv, newUV, weight);

     return clamp(safeUV, 0.001, 0.999);
 }

 fragment float4 eyeScaleShader(VertexOut vert [[stage_in]],
                                texture2d<float> inputTexture [[texture(0)]],
                                constant float &leftScaleFactor [[buffer(0)]],
                                constant float &rightScaleFactor [[buffer(1)]],
                                constant float2 &leftEyeCenter [[buffer(2)]],
                                constant float2 &rightEyeCenter [[buffer(3)]],
                                constant float2 &leftEyeRadiusXY [[buffer(4)]],
                                constant float2 &rightEyeRadiusXY [[buffer(5)]],
                                sampler textureSampler [[sampler(0)]]) {

     float2 uv = vert.textureCoordinate;

     // compute scaled UVs for both eyes
     float2 uvLeft = scaledUVForEye(uv, leftEyeCenter, leftEyeRadiusXY, leftScaleFactor);
     float2 uvRight = scaledUVForEye(uv, rightEyeCenter, rightEyeRadiusXY, rightScaleFactor);

     // blending weights based on elliptical distance
     float distLeft = length(float2((uv - leftEyeCenter) / leftEyeRadiusXY));
     float distRight = length(float2((uv - rightEyeCenter) / rightEyeRadiusXY));

     float weightLeft = exp(-pow(distLeft / 3.0, 2.0) * 2.0);  // match outerFalloff
     float weightRight = exp(-pow(distRight / 3.0, 2.0) * 2.0);

     float totalWeight = weightLeft + weightRight;
     if (totalWeight > 0.0) {
         weightLeft /= totalWeight;
         weightRight /= totalWeight;
     }

     // final blended UV
     float2 finalUV = uvLeft * weightLeft + uvRight * weightRight + uv * (1.0 - weightLeft - weightRight);

     return inputTexture.sample(textureSampler, finalUV);
 }

 
 
 
 
 
 */
