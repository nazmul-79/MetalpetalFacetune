//
//  OuterLipsFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 14/8/25.
//

import UIKit
import MetalPetal

class LipsMetalFilter: NSObject, MTIFilter {

    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?

    // Lips parameters
    var lipCenter: SIMD2<Float> = SIMD2<Float>(0.5, 0.65)
    var lipRadiusXY: SIMD2<Float> = SIMD2<Float>(0.15, 0.08)
    var lipScaleFactor: Float = 0.0
    
    //let dataBuffer = MTIDataBuffer(bytes: <#T##UnsafeRawPointer#>, length: <#T##UInt#>)

    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "lipsScaleShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()

    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }

        let parameters: [String: Any] = [
            "lipScaleFactor": lipScaleFactor,
            "lipCenter": lipCenter,
            "lipRadiusXY": lipRadiusXY
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
