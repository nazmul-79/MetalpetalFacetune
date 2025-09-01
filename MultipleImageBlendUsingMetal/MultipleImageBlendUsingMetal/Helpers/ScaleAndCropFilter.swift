//
//  ScaleAndCropFilter.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 7/8/25.
//


import MetalPetal
import Foundation
import simd

final class ScaleAndCropFilter: MTIFilter {
    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    
    var inputImage: MTIImage?
    var targetSize: CGSize = .zero        // Final render size (e.g., canvas size)
    var inputImageSize: CGSize = .zero    // Original image size

    static let kernel: MTIRenderPipelineKernel = {
        return MTIRenderPipelineKernel(
            vertexFunctionDescriptor: MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName),
            fragmentFunctionDescriptor: MTIFunctionDescriptor(
                name: "scaleAndCropShader",
                libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main)
            )
        )
    }()
    
    var outputImage: MTIImage? {
        guard let inputImage = inputImage else { return nil }
        guard targetSize.width > 0, targetSize.height > 0 else { return inputImage }

        // Calculate scale (aspect fill)
        let scaleX = targetSize.width / inputImageSize.width
        let scaleY = targetSize.height / inputImageSize.height
        let scale = max(scaleX, scaleY)

        // Calculate scaled image size
        let scaledWidth = inputImageSize.width * scale
        let scaledHeight = inputImageSize.height * scale

        // Center crop offset
        let offsetX = (scaledWidth - targetSize.width) / 2
        let offsetY = (scaledHeight - targetSize.height) / 2

        // Inverse scaled image size for texture coordinate mapping
        let invScaledInputSize = SIMD2<Float>(
            1.0 / Float(scaledWidth),
            1.0 / Float(scaledHeight)
        )
        
        return Self.kernel.apply(
            to: [inputImage],
            parameters: [
                "invScaledInputSize": SIMD2<Float>(Float(1.0 / (inputImageSize.width * scale)),
                                                  Float(1.0 / (inputImageSize.height * scale))),
                "offset": SIMD2<Float>(Float(offsetX), Float(offsetY)),
                "targetSize": SIMD2<Float>(Float(targetSize.width), Float(targetSize.height))
            ],
            outputDimensions: MTITextureDimensions(cgSize: targetSize),
            outputPixelFormat: outputPixelFormat
        )
    }
}


import MetalPetal
import simd

final class StickerOverlayFilter: MTIFilter {

    var outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    
    var backgroundImage: MTIImage?
    var stickerImage: MTIImage?

    /// Position of sticker in background image coordinates (top-left origin)
    var stickerPosition: SIMD2<Float> = .zero
    /// Size of sticker (width, height) in background image coordinates
    var stickerSize: SIMD2<Float> = SIMD2<Float>(1,1)
    /// Rotation in radians
    var stickerRotation: Float = 0

    static let kernel: MTIRenderPipelineKernel = {
        MTIRenderPipelineKernel(
            vertexFunctionDescriptor: MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName),
            fragmentFunctionDescriptor: MTIFunctionDescriptor(name: "stickerOverlayShader", libraryURL: MTIDefaultLibraryURLForBundle(Bundle.main))
        )
    }()
    
    var outputImage: MTIImage? {
        guard let bg = backgroundImage, let sticker = stickerImage else {
            return backgroundImage
        }

        return Self.kernel.apply(
            to: [bg, sticker],
            parameters: [
                "stickerPos": stickerPosition,
                "stickerSize": stickerSize,
                "stickerRotation": stickerRotation
            ],
            outputDimensions: MTITextureDimensions(cgSize: bg.size),
            outputPixelFormat: outputPixelFormat
        )
    }
}

/*
 private func exportPhoto() {
     guard let bgImage = bgImage else { return }
     
     let canvasSize = canvasView.bounds.size
     let renderSize = self.renderSize(for: canvasSize, preset: .uhd4k)
     
     
     // 1. Compute scale (aspect fill)
     let scale = max(renderSize.width / bgImage.size.width,
                     renderSize.height / bgImage.size.height)
     
     // 2. Build scale transform
     let transform = CGAffineTransform(scaleX: scale, y: scale)
     
     // 3. Create scaled image
     let coreImg = CIImage(cgImage: bgImage.cgImage!)
     let scaledImage = coreImg.transformed(by: transform)
     
     // 4. Compute crop origin (center-crop)
     let cropOrigin = CGPoint(
         x: (scaledImage.extent.width - renderSize.width) / 2,
         y: (scaledImage.extent.height - renderSize.height) / 2
     )
     
     let cropRect = CGRect(origin: cropOrigin, size: renderSize)
     
     // 5. Perform crop
     let finalImage = scaledImage.cropped(to: cropRect)
     
     debugPrint("🎯 Final Image Size:", finalImage.extent.size)
     
     // ⛳️ continue with rendering or export...
     
     let filter = ScaleAndCropFilter()
     filter.inputImage = MTIImage(cgImage: bgImage.cgImage!, options: [.SRGB: false], isOpaque: false)
     filter.inputImageSize = bgImage.size
     filter.targetSize = renderSize
     
     let finalImage1 = filter.outputImage
     
     let finalImag2 = ciImage(from: finalImage1!)
     
     /*guard let transform = transformableView?.currentTransformValues(),
           let fgImage = fgImage else {
         return
     }
     
     let originalStickerSize = fgImage.size
     let bgPixelSize = renderSize
     
     // Calculate scale factors from canvas to background
     let scaleX = bgPixelSize.width / canvasSize.width
     let scaleY = bgPixelSize.height / canvasSize.height
     
     let stickerX = transform.x * scaleX
     let stickerY = transform.y * scaleY

     let stickerWidthInPixels = transform.width * scaleX
     let stickerHeightInPixels = transform.height * scaleY

     let stickerCenterX = (stickerX)
     // Flip Y axis for Metal texture coords
     let stickerCenterY = (bgPixelSize.height) - (stickerY + stickerHeightInPixels)
     //let stickerCenter = SIMD2<Float>(stickerCenterX, stickerCenterY)

     let scaleXSticker = (stickerWidthInPixels / fgImage.size.width)
     let scaleYSticker = (stickerHeightInPixels / fgImage.size.height)
     
     let transformfg = CGAffineTransform(scaleX: scaleXSticker, y: scaleYSticker)
         .concatenating(CGAffineTransform(translationX: stickerCenterX, y: stickerCenterY))

     let translationImage = CIImage(cgImage: fgImage.cgImage!).transformed(by: transformfg)
     let rotateImage = translationImage.rotated(by: -transform.rotation)
     
     let filter1 = CIFilter.sourceOverCompositing()
     filter1.inputImage = rotateImage
     filter1.backgroundImage = finalImag2
     
     let actualImage = filter1.outputImage?.clampedToExtent().cropped(to: finalImag2!.extent)
     
     
     //let finalImag2 = ciImage(from: actualImage!)
     //let stickerScale = SIMD2<Float>(scaleXSticker, scaleYSticker)*/
     
     if let transform = self.transformableView?.currentTransformValues() {
         // transform.x, transform.y are origin in superview coordinates
         // transform.width, height are size
         // rotation is in degrees, convert to radians
         let rotationRadians = transform.rotation

         // Convert position and size to background image pixel coordinates
         // Assume you have the background size:
         let bgSize = CGSize(width: renderSize.width, height: renderSize.height)
         
         let scaleX = (renderSize.width / canvasSize.width)
         let scaleY = (renderSize.height / canvasSize.height)

         // Convert transform position from your view coordinate system to bg image coords
         // This depends on how your view is sized relative to bg image, but typically:
         // If transform.x/y are relative to some container that matches bg image size:
         let stickerPos = SIMD2<Float>(Float(transform.x * scaleX), Float(transform.y * scaleY))

         let stickerSize = SIMD2<Float>(Float(transform.width * scaleX), Float(transform.height * scaleY))

         let overlayFilter = StickerOverlayFilter()
         overlayFilter.backgroundImage = finalImage1 // output of ScaleAndCropFilter
         overlayFilter.stickerImage = MTIImage(cgImage: fgImage!.cgImage!, options: [.SRGB: false], isOpaque: false)
         overlayFilter.stickerPosition = stickerPos
         overlayFilter.stickerSize = stickerSize
         overlayFilter.stickerRotation = Float(rotationRadians)

         let finalImageWithSticker = overlayFilter.outputImage
         
         let storyboard = UIStoryboard(name: "Main", bundle: nil) // replace "Main" if your storyboard has a different name
         let demoVC = storyboard.instantiateViewController(withIdentifier: "DemoViewController") as! DemoViewController
         demoVC.image = finalImageWithSticker
        // demoVC.mtImageView.image = finalImageWithSticker

         // To present modally
         self.present(demoVC, animated: true, completion: nil)
         
        // let finalImageWithSticker1 = ciImage(from: finalImageWithSticker!)

         // Use finalImageWithSticker to display or export
         debugPrint("🎯 Final Image Size:", finalImage.extent.size)
     }
     debugPrint("🎯 Final Image Size:", finalImage.extent.size)
 }


 */
