//
//  EyelashMetalFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 17/9/25.
//


import Foundation
import UIKit
import MetalPetal

class EyelashMetalFilterV2: NSObject, MTIFilter {

    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?

    // Nose parameters
    var scaleFactor: Float = 0.0
    var point: [SIMD2<Float>] = []
    
    //let dataBuffer = MTIDataBuffer(bytes: <#T##UnsafeRawPointer#>, length: <#T##UInt#>)

    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "eyelashShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()

    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }
        
        guard let pointBuffer = MTIDataBuffer(bytes: &point, length: UInt(MemoryLayout<SIMD2<Float>>.size * point.count)) else {return nil}

        let parameters: [String: Any] = [
            "scaleFactor": scaleFactor,
            "points": pointBuffer,
            "count": UInt(point.count)
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
