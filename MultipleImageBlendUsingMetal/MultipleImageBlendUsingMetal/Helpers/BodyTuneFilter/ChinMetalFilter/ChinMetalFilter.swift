//
//  ChinMetalFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 20/8/25.
//

import UIKit
import MetalPetal

class ChinMetalFilter: NSObject, MTIFilter {
    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?
    var scaleFactor: Float = 0.0
    var point: [SIMD2<Float>] = []
    var lineWidth: Float =  15.0
    var center: SIMD2<Float> = SIMD2<Float>(0.0, 0.0)
    
   
    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "chinScaleShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()
    
    var outputImage: MTIImage? {
        
        guard let inputImage = inputImage else { return nil }
        
        guard let pointBuffer = MTIDataBuffer(bytes: &point, length: UInt(MemoryLayout<SIMD2<Float>>.size * point.count)) else {return nil}
        
        var lineWidth1: Float =  20.0
        
        let parameters: [String: Any] = [
            "jawPoints": pointBuffer,
            "count": UInt(point.count),
            "lineWidth": lineWidth1,
            "chinScaleFactor": scaleFactor,
            "jawCenter": center
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
