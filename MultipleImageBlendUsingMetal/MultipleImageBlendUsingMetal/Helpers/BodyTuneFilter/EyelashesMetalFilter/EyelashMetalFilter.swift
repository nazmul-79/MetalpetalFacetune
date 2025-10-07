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
    var rightUpPoints: [SIMD2<Float>] = []
    var rightDownPoints: [SIMD2<Float>] = []
    var leftUpPoints: [SIMD2<Float>] = []
    var leftDownPoints: [SIMD2<Float>] = []
    
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
        
        guard let rUppointBuffer = MTIDataBuffer(bytes: &rightUpPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * rightUpPoints.count)) else {return nil}
        
        guard let rDownpointBuffer = MTIDataBuffer(bytes: &rightDownPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * rightDownPoints.count)) else {return nil}
        
        guard let lUppointBuffer = MTIDataBuffer(bytes: &leftUpPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * leftUpPoints.count)) else {return nil}
        
        guard let lDownpointBuffer = MTIDataBuffer(bytes: &leftDownPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * leftDownPoints.count)) else {return nil}

        let parameters: [String: Any] = [
            "scaleFactor": scaleFactor,
            "rightUpPoints": rUppointBuffer,
            "rightDownPoints": rDownpointBuffer,
            "leftUpPoints": lUppointBuffer,
            "leftDownPoints": lDownpointBuffer,
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
