//
//  EyeBrowMetalFitler.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 21/8/25.
//

import UIKit
import MetalPetal

import UIKit
import MetalPetal

class EyeBrowZoomFilter: NSObject, MTIFilter {

    var inputImage: MTIImage?
    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm

    var leftBrowCenter: SIMD2<Float> = SIMD2(0.35, 0.4)
    var rightBrowCenter: SIMD2<Float> = SIMD2(0.65, 0.4)

    var leftBrowRadius: SIMD2<Float> = SIMD2(0.08, 0.02)
    var rightBrowRadius: SIMD2<Float> = SIMD2(0.08, 0.02)

    var leftScaleFactor: Float = 1.0
    var rightScaleFactor: Float = 1.0

    static let kernel: MTIRenderPipelineKernel = {
        let vertex = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragment = MTIFunctionDescriptor(name: "eyebrowScaleShader",
                                             libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main))
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertex,
                                       fragmentFunctionDescriptor: fragment)
    }()

    var outputImage: MTIImage? {
        guard let inputImage else { return nil }

        let params: [String: Any] = [
            "leftScaleFactor": leftScaleFactor,
            "rightScaleFactor": leftScaleFactor,
            "leftCenter": leftBrowCenter,
            "rightCenter": rightBrowCenter,
            "leftRadius": leftBrowRadius,
            "rightRadius": rightBrowRadius
        ]
        
        return Self.kernel.apply(to: inputImage, parameters: params)
    }
}
