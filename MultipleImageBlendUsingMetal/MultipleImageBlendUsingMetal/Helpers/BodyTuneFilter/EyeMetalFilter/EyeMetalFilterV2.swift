//
//  EyeMetalFilterV2.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 9/9/25.
//


import UIKit
import MetalPetal

class EyeMetalFilterV2: NSObject, MTIFilter {

    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?

    // Left eye
    var leftEyeCenter: SIMD2<Float> = SIMD2<Float>(0.35, 0.5)
    var leftEyeRadiusXY: SIMD2<Float> = SIMD2<Float>(0.1, 0.1)

    // Right eye
    var rightEyeCenter: SIMD2<Float> = SIMD2<Float>(0.65, 0.5)
    var rightEyeRadiusXY: SIMD2<Float> = SIMD2<Float>(0.1, 0.1)
    
    var scaleFactor: Float = 0.0

    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "eyeScaleShaderV2",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()

    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }

        let parameters: [String: Any] = [
            "leftEyeCenter": leftEyeCenter,
            "leftEyeRadii": leftEyeRadiusXY,
            "rightEyeCenter": rightEyeCenter,
            "rightEyeRadii": rightEyeRadiusXY,
            "scaleFactor": scaleFactor,
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
