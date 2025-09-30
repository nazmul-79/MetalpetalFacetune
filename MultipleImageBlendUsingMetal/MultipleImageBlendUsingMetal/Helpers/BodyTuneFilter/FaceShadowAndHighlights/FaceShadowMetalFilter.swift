//
//  FaceShadowMetalFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 29/9/25.
//

import UIKit
import MetalPetal

class FaceShadowMetalFilter: NSObject, MTIFilter {

    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?

    // Lips parameters
    var faceRectCenter: SIMD2<Float> = SIMD2<Float>(0.5, 0.65)
    var faceRectRadius: SIMD2<Float> = SIMD2<Float>(0.15, 0.08)
    var point: [SIMD2<Float>] = []
    var faceScaleFactor: Float = 0.0
    var rotation: Float = 0.0
    

    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "FaceShadowMetalShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()

    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }
        
        guard let pointBuffer = MTIDataBuffer(bytes: &point, length: UInt(MemoryLayout<SIMD2<Float>>.size * point.count)) else {return nil}

        let parameters: [String: Any] = [
            "faceScaleFactor": faceScaleFactor,
            "faceRectCenter": faceRectCenter,
            "faceRectRadius": faceRectRadius,
            "points": pointBuffer,
            "count": UInt(point.count),
            
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
