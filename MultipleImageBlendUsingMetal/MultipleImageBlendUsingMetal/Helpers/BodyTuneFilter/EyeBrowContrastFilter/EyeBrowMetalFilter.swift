//
//  EyeBrowMetalFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 28/9/25.
//

import Foundation
import UIKit
import MetalPetal

class EyeBrowMetalFilter: NSObject, MTIFilter {

    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?

    var scaleFactor: Float = 0.0
    var leftbrowPoints: [SIMD2<Float>] = []
    var rightbrowPoints: [SIMD2<Float>] = []
    
    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "eyeBrowBrighterShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()

    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }
        
        guard let leftBrowPointsBuffer = MTIDataBuffer(bytes: &leftbrowPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * leftbrowPoints.count)) else {return nil}
        
        guard let rightBrowPointsBuffer = MTIDataBuffer(bytes: &rightbrowPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * rightbrowPoints.count)) else {return nil}
        
        let parameters: [String: Any] = [
            "leftbrowPoints": leftBrowPointsBuffer,
            "leftbrowCount": UInt(leftbrowPoints.count),
            "rightbrowPoints": rightBrowPointsBuffer,
            "rightbrowCount": UInt(rightbrowPoints.count),
            "scaleFactor": scaleFactor
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
