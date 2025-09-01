//
//  TeethWhiteningMetalFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 28/8/25.
//


import MetalPetal

class TeethWhiteningMetalFilter: NSObject, MTIFilter {
    var inputImage: MTIImage?
    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    var maskImage: MTIImage?
    
    var effectFactor: Float = 0.0
    var innerLipsCenter: SIMD2<Float> = .zero
    var innerLipsRadius: SIMD2<Float> = .zero
    
    static let kernel: MTIRenderPipelineKernel = {
        let vertex = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragment = MTIFunctionDescriptor(
            name: "TeethWhiteningInnerLipsShader",
            libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
        )
        return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertex,
                                       fragmentFunctionDescriptor: fragment)
    }()
    
    var outputImage: MTIImage? {
        guard let inputImage = inputImage, let imageMask = self.maskImage else { return nil }
        let params: [String: Any] = [
            "effectFactor": effectFactor,
            "innerLipsCenter": innerLipsCenter,
            "innerLipsRadius": innerLipsRadius,
        ]
        return Self.kernel.apply(to: [inputImage,imageMask],
                                 parameters: params,
                                 outputDimensions:  MTITextureDimensions(cgSize: inputImage.size),
                                 outputPixelFormat: outputPixelFormat)
    }
}
/*
 
 if (brightColor.r > 0.3 && brightColor.g > 0.3 && brightColor.b > 0.3) {
     brightColor = color.rgb + intensity;
 }
 */
