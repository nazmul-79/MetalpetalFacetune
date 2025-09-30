//
//  TeethWhiteningMetalFilterV2.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 30/9/25.
//

import Foundation
import UIKit
import MetalPetal

class TeethBrighterFilterV2: NSObject, MTIFilter  {

    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?

    // Nose parameters
    var scaleFactor: Float = 0.0
    var outerLipsPoint: [SIMD2<Float>] = []
    var innerLipsPoint: [SIMD2<Float>] = []
    
    //let dataBuffer = MTIDataBuffer(bytes: <#T##UnsafeRawPointer#>, length: <#T##UInt#>)

    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "teethWhiteningShaderEffect",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()

    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }
        
        guard let outerBuffer = MTIDataBuffer(bytes: &outerLipsPoint, length: UInt(MemoryLayout<SIMD2<Float>>.size * outerLipsPoint.count)) else {return nil}
        
        guard let innerBuffer = MTIDataBuffer(bytes: &innerLipsPoint, length: UInt(MemoryLayout<SIMD2<Float>>.size * innerLipsPoint.count)) else {return nil}

        let parameters: [String: Any] = [
            "outerPoints": outerBuffer,
            "outerCount": UInt(outerLipsPoint.count),
            "innerPoints": innerBuffer,
            "innerCount": UInt(innerLipsPoint.count),
            "scaleFactor": scaleFactor
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
