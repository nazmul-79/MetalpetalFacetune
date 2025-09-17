//
//  NoseMetalFilterV2.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 16/9/25.
//


import Foundation
import UIKit
import MetalPetal

class NoseMetalFilterV2: NSObject, MTIFilter {

    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?

    // Nose parameters
    var noseCenter: SIMD2<Float> = SIMD2<Float>(0.5, 0.65)
    var noseRadiusXY: SIMD2<Float> = SIMD2<Float>(0.15, 0.08)
    var noseScaleFactor: Float = 0.0
    var point: [SIMD2<Float>] = []
    
    //let dataBuffer = MTIDataBuffer(bytes: <#T##UnsafeRawPointer#>, length: <#T##UInt#>)

    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "noseScaleShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()

    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }
        
        guard let pointBuffer = MTIDataBuffer(bytes: &point, length: UInt(MemoryLayout<SIMD2<Float>>.size * point.count)) else {return nil}

        let parameters: [String: Any] = [
            "lipScaleFactor": noseScaleFactor,
            "lipCenter": noseCenter,
            "lipRadiusXY": noseRadiusXY,
            "nosePoints": pointBuffer,
            "noseCount": UInt(point.count)
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
