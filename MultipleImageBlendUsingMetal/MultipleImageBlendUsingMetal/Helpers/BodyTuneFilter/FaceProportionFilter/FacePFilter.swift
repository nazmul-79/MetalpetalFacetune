//
//  FacePFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 25/8/25.
//


import UIKit
import MetalPetal

class FacePFilter: NSObject, MTIFilter {

    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?

    // Lips parameters
    var faceRectCenter: SIMD2<Float> = SIMD2<Float>(0.5, 0.65)
    var faceRectRadius: SIMD2<Float> = SIMD2<Float>(0.15, 0.08)
    var faceScaleFactor: Float = 0.0
    

    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "FacePFilter",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()

    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }

        let parameters: [String: Any] = [
            "faceScaleFactor": faceScaleFactor,
            "faceRectCenter": faceRectCenter,
            "faceRectRadius": faceRectRadius
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
