//
//  NeckShadowMetalFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 29/9/25.
//


import MetalPetal
import simd

class NeckShadowMetalFilter: NSObject, MTIFilter {
    
    var inputImage: MTIImage?
    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    
    // Polygons
    var jawPoints: [SIMD2<Float>] = []
    
    // Brightness
    var scaleFactor: Float = 0.0
    
    // Kernel
    static let kernel: MTIRenderPipelineKernel = {
        let vertex = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragment = MTIFunctionDescriptor(
            name: "neckShadowShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(
            vertexFunctionDescriptor: vertex,
            fragmentFunctionDescriptor: fragment
        )
    }()
    
    var outputImage: MTIImage? {
        guard let inputImage else { return nil }
        
        guard let outerPoints = MTIDataBuffer(bytes: &jawPoints, length: UInt(MemoryLayout<SIMD2<Float>>.size * jawPoints.count)) else {return nil}
        
        let params: [String: Any] = [
            "jawPoints": outerPoints,
            "outerCount": UInt(jawPoints.count),
            "scaleFactor": scaleFactor
        ]
        
        return Self.kernel.apply(to: inputImage, parameters: params)
    }
}
