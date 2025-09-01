//
//  EyelashEffectFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 26/8/25.
//

import MetalPetal

class EyelashEffectFilter: NSObject, MTIFilter {
    var inputImage: MTIImage?
    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    
    var effectFactor: Float = 0.0
    var leftEyeCenter: SIMD2<Float> = .zero
    var leftEyeRadius: SIMD2<Float> = .zero
    var rightEyeCenter: SIMD2<Float> = .zero
    var rightEyeRadius: SIMD2<Float> = .zero
    
    static let kernel: MTIRenderPipelineKernel = {
        let vertex = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragment = MTIFunctionDescriptor(
            name: "EyelashEffect",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertex,
                                       fragmentFunctionDescriptor: fragment)
    }()
    
    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }
        let params: [String: Any] = [
            "effectFactor": effectFactor,
            "leftEyeCenter": leftEyeCenter,
            "leftEyeRadius": leftEyeRadius,
            "rightEyeCenter": rightEyeCenter,
            "rightEyeRadius": rightEyeRadius
        ]
        return Self.kernel.apply(to: inputImage, parameters: params)
    }
}
