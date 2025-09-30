//
//  EyeConstrastMetalFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 23/9/25.
//

import MetalPetal
import Foundation

class EyeConstrastMetalFilterV2: NSObject, MTIFilter {

    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var inputImage: MTIImage?

    // Nose parameters
    var scaleFactor: Float = 0.0
    var leftEyeContourPoints: [SIMD2<Float>] = []
    var rightEyeContourPoints: [SIMD2<Float>] = []
   
    var leftEyeIrisPoints: [SIMD2<Float>] = []
    var rightEyeIrisPoints: [SIMD2<Float>] = []
    
    static let kernel: MTIRenderPipelineKernel = {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(
            name: "eyeContrastShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor,
                                       fragmentFunctionDescriptor: fragmentDescriptor)
    }()

    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }
        
        guard let leftEyeContourBuffer = MTIDataBuffer(bytes: &leftEyeContourPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * leftEyeContourPoints.count)) else {return nil}
        
        guard let rightEyeContourBuffer = MTIDataBuffer(bytes: &rightEyeContourPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * rightEyeContourPoints.count)) else {return nil}
        
        guard let leftIrisBuffer = MTIDataBuffer(bytes: &leftEyeIrisPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * leftEyeIrisPoints.count)) else {return nil}
        
        guard let rightIrisBuffer = MTIDataBuffer(bytes: &rightEyeIrisPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * rightEyeIrisPoints.count)) else {return nil}

        let parameters: [String: Any] = [
            "leftContourPoints": leftEyeContourBuffer,
            "leftContourCount": UInt(leftEyeContourPoints.count),
            "rightContourPoints": rightEyeContourBuffer,
            "rightContourCount": UInt(rightEyeContourPoints.count),
            "leftIrisPoints": leftIrisBuffer,
            "leftIrisCount": UInt(leftEyeIrisPoints.count),
            "rightIrisPoints": rightIrisBuffer,
            "rightIrisCount": UInt(rightEyeIrisPoints.count),
            "scaleFactor": scaleFactor
        ]

        return Self.kernel.apply(to: inputImage, parameters: parameters)
    }
}
