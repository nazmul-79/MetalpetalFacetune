//
//  ViewController.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 4/8/25.
//

import UIKit
import MetalPetal
import PhotosUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins

enum ResolutionPreset {
    case sd        // 480p
    case hd        // 720p
    case fullHD    // 1080p
    case quadHD    // 1440p (2K)
    case uhd4k     // 2160p (4K)
    case dci4k     // 2160p (DCI 4096x2160)

    var height: CGFloat {
        switch self {
        case .sd: return 480
        case .hd: return 720
        case .fullHD: return 1080
        case .quadHD: return 1440
        case .uhd4k: return 2160
        case .dci4k: return 2160
        }
    }

    var widthFor16by9: CGFloat {
        switch self {
        case .sd: return 720
        case .hd: return 1280
        case .fullHD: return 1920
        case .quadHD: return 2560
        case .uhd4k: return 3840
        case .dci4k: return 4096
        }
    }

    /// Returns default size for 16:9 aspect ratio
    var defaultSize: CGSize {
        return CGSize(width: widthFor16by9, height: height)
    }
}


class ViewController: UIViewController {
    @IBOutlet weak var topContainerView: UIView!
    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var canvasViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var canvasViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView: MTIImageView!
    
    

    private var isBGImage: Bool = false
    private var bgImage: UIImage? = nil
    private var fgImage: UIImage? = nil
    private var isFirstTime: Bool = true
    private var transformableView: TransformableView? = nil
    let photoPicker = PhotoPicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.resizingMode = .aspectFill
        if let layer = imageView.layer as? CAMetalLayer {
            layer.framebufferOnly = false
            layer.pixelFormat = .bgra8Unorm
        }
        photoPicker.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstTime {
            self.isFirstTime = false
        }
    }
    
    @IBAction func tappedOnBGOrTopBtn(_ sender: UIButton) {
        debugPrint("Tapped On BG Or Top",sender.tag)
        switch sender.tag {
        case 3000:
            isBGImage = true
            debugPrint("Tapped On BG")
        case 3001:
            isBGImage = false
            debugPrint("Tapped On Forground")
        default:
            break
        }
        self.requestPhotoLibraryPermission()
    }
    
    @IBAction func tappedOnFaceTuneButton(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let faceTuneVC = storyboard.instantiateViewController(withIdentifier: "FaceTuneVC") as! FaceTuneVC
        faceTuneVC.modalPresentationStyle = .fullScreen
        self.present(faceTuneVC, animated: true, completion: nil)
    }
    
    @IBAction func tappedOnRatioButton(_ sender: UIButton) {
        debugPrint("tappedOnRatioButton",sender.tag)
        switch sender.tag {
        case 2000:
            debugPrint("Tapped On 1:1")
            setupCanvas(size: CGSize(width: 1, height: 1))
        case 2001:
            debugPrint("Tapped On 3:4")
            setupCanvas(size: CGSize(width: 3, height: 4))
        case 2002:
            debugPrint("Tapped On 4:3")
            setupCanvas(size: CGSize(width: 4, height: 3))
        case 2003:
            setupCanvas(size: CGSize(width: 9, height: 16))
            debugPrint("Tapped On 9:16")
        case 2004:
            setupCanvas(size: CGSize(width: 16, height: 9))
            debugPrint("Tapped On 16:9")
        default:
            break
        }
    }
    
    @IBAction func tappedOnExportButton(_ sender: UIButton) {
        self.exportPhoto()
    }
    
    
    private func setupCanvas(size: CGSize) {
        let fitSize = AVMakeRect(aspectRatio: size, insideRect: topContainerView.bounds)
        
        debugPrint("Fit eisze", fitSize)

        let roundedSize = CGSize(
            width: max(round(fitSize.width / 2) * 2, 2),
            height: max(round(fitSize.height / 2) * 2, 2)
        )

        canvasViewWidthConstraint.constant = roundedSize.width
        canvasViewHeightConstraint.constant = roundedSize.height

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func setGalleryImg(image: UIImage) {
        if isBGImage {
            self.bgImage = image
            self.imageView.image = MTIImage(cgImage: image.cgImage!,
                                            options: [.SRGB: false],
                                            isOpaque: false)
            setupCanvas(size: CGSize(width: 1, height: 1))
        } else {
            self.transformableView?.removeFromSuperview()
            self.fgImage = image
            let transformableView1 = TransformableView(frame: CGRect(origin: .zero,
                                                                    size: CGSize(width: image.size.width * 0.2,
                                                                                 height: image.size.height * 0.2)))
            transformableView1.center = canvasView.center
            transformableView1.imageView?.image = MTIImage(cgImage: image.cgImage!,
                                                          options: [.SRGB: false],
                                                          isOpaque: false)
            self.transformableView  = transformableView1
            if self.transformableView != nil {
                self.canvasView.addSubview(transformableView!)
            }
        }
    }
    
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
        filter.inputImage = MTIImage(cgImage: bgImage.cgImage!, options: [.SRGB: false], isOpaque: false).unpremultiplyingAlpha()
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
            overlayFilter.stickerImage = MTIImage(cgImage: fgImage!.cgImage!, options: [.SRGB: false], isOpaque: false).unpremultiplyingAlpha()
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


    
    func ciImage(from mtiImage: MTIImage) -> CIImage? {
        do {
            // Render MTIImage to CGImage
            let cgImage = try GPUContext.shared.makeCGImage(from: mtiImage)
            // Create CIImage from CGImage
            return CIImage(cgImage: cgImage)
        } catch {
            print("Failed to create CGImage from MTIImage: \(error)")
            return nil
        }
    }
    
    func aspectFillCropRect(contentSize: CGSize,
                            containerSize: CGSize) -> CGRect {
        let scale = max(containerSize.width / contentSize.width,
                        containerSize.height / contentSize.height)
        let size = CGSize(width: contentSize.width * scale,
                          height: contentSize.height * scale)
        let origin = CGPoint(x: (containerSize.width - size.width) / 2,
                             y: (containerSize.height - size.height) / 2)
        return CGRect(origin: origin, size: size)
    }
    
    func renderSize(for aspectRatio: CGSize,
                    preset: ResolutionPreset,
                    makeEven: Bool = true) -> CGSize {
        
        guard aspectRatio.width > 0, aspectRatio.height > 0 else {
            return .zero
        }

        let targetHeight = preset.height
        var width = (targetHeight * aspectRatio.width) / aspectRatio.height
        var height = targetHeight

        if makeEven {
            width = round(width / 2) * 2
            height = round(height / 2) * 2
        }
        return CGSize(width: width, height: height)
    }
    
}

//MARK: - requestPhotoLibraryPermission
extension ViewController {
    func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                // Proceed to show the photo picker
                DispatchQueue.main.async {
                    self.showPhotoPicker()
                }
            case .denied, .restricted:
                // Handle cases where access is denied or restricted
                DispatchQueue.main.async {
                    self.showPermissionAlert()
                }
            case .notDetermined:
                // You can request permission in this case too
                break
            case .limited:
                debugPrint("Limit Access")
            @unknown default:
                break
            }
        }
    }
    
    func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Permission Denied",
            message: "Please grant access to the photo library in Settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showPhotoPicker() {
        photoPicker.showPhotoPicker(controller: self)
    }
}

//MARK: - PhtonPickerDelegate
extension ViewController: PhotoPickerDelegate {
    func didSelectPhoto(_ photo: UIImage) {
        self.setGalleryImg(image: photo)
    }
}

//MARK: - PHPickerViewControllerDelegate
extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        let itemProvider = result.itemProvider
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        // ekhane image ke use korte paro (e.g. imageView.image = image)
                        print("Loaded image: \(image)")
                        self.setGalleryImg(image: image.fixedOrientation())
                    }
                } else if let error = error {
                    print("Failed to load image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func applyStickerTransform() {
      
    }
}

extension UIImage {
    func fixedOrientation() -> UIImage {
        autoreleasepool {
            // If orientation is already correct, return self
            if imageOrientation == .up {
                return self
            }
            
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            draw(in: CGRect(origin: .zero, size: size))
            let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return normalizedImage ?? self
        }
    }
}


import MetalPetal

import Foundation
import Metal
import MetalPetal

final class GPUContext: NSObject{
    
    private static var _shared: MTIContext?
    
    private override init () {
        super.init()
    }
    
    public static var shared: MTIContext {
        if let context = _shared {
            return context
        }
        _shared = createNewContext()
        return _shared!
    }

    static func resetContext() {
        _shared = nil
    }

    private static func createNewContext() -> MTIContext {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("❌ Metal not supported")
        }

        let options = MTIContextOptions()
        options.workingPixelFormat = .bgra8Unorm
        options.automaticallyReclaimsResources = true

        do {
            let context = try MTIContext(device: device, options: options)
            print("✅ New MTIContext created with device: \(device.name)")
            return context
        } catch {
            fatalError("❌ Failed to create MTIContext: \(error.localizedDescription)")
        }
    }
    
}

extension CIImage {
    func rotated(by angleInRadians: CGFloat) -> CIImage {
        let transform = CGAffineTransform(translationX: extent.midX, y: extent.midY)
            .rotated(by: angleInRadians)
            .translatedBy(x: -extent.midX, y: -extent.midY)
        
        return self.transformed(by: transform)
    }
}
