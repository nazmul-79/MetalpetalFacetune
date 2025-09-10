//
//  LipsBrightenFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 1/9/25.
//

import MetalPetal
import simd

class LipsBrightenFilter: NSObject, MTIFilter {
    
    var inputImage: MTIImage?
    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    
    // Polygons
    var outerLipsPoints: [SIMD2<Float>] = []
    var innerLipsPoints: [SIMD2<Float>] = []
    
    // Brightness
    var outerBrightness: Float = 0.1
    
    // Kernel
    static let kernel: MTIRenderPipelineKernel = {
        let vertex = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragment = MTIFunctionDescriptor(
            name: "LipsOuterSmoothShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(
            vertexFunctionDescriptor: vertex,
            fragmentFunctionDescriptor: fragment
        )
    }()
    
    var outputImage: MTIImage? {
        guard let inputImage else { return nil }
        
        guard let outerPoints = MTIDataBuffer(bytes: &outerLipsPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * outerLipsPoints.count)) else {return nil}
        guard let innerPoints = MTIDataBuffer(bytes: &innerLipsPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * innerLipsPoints.count)) else {return nil}
        
        let params: [String: Any] = [
            "outerPoints": outerPoints,
            "outerCount": UInt(outerLipsPoints.count),
            "innerPoints": innerPoints,
            "innerCount": UInt(innerLipsPoints.count),
            "outerBrightness": outerBrightness
        ]
        
        return Self.kernel.apply(to: inputImage, parameters: params)
    }
}
