//
//  PhotoPicker.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 11/8/25.
//

import PhotosUI
import Photos
import UIKit
import Foundation

protocol PhotoPickerDelegate: AnyObject {
    func didSelectPhoto(_ photo: UIImage)
}

class PhotoPicker: NSObject, PHPickerViewControllerDelegate {

    weak var delegate: PhotoPickerDelegate?
    private let backgroundQueue = DispatchQueue(label: "com.google.mediapipe.cameraController.backgroundQueue")
  
    func showPhotoPicker(controller: UIViewController) {
        let photoLibrary = PHPhotoLibrary.shared()
        var config = PHPickerConfiguration(photoLibrary: photoLibrary)
        config.selectionLimit = 1  // Change the limit based on your needs
        config.filter = .images    // You can also filter by .videos or other media types
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        controller.present(picker, animated: true)
    }
    
   /* func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        
        let itemProvider = result.itemProvider
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    autoreleasepool {
                        // Background thread এ heavy processing
                        self?.backgroundQueue.async {
                            autoreleasepool {
                                let fixed = image.fixedOrientation()
                                guard let jpegData = fixed.jpegData(compressionQuality: 1.0) else { return }
                                guard let resized = fixed.downsample(imageData: jpegData, to: 4048) else { return }
                                
                                self?.delegate?.didSelectPhoto(resized)
                            }
                        }
                    }
                } else if let error = error {
                    print("Failed to load image: \(error.localizedDescription)")
                }
            }
        }
    }*/
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let firstResult = results.first,
              let assetId = firstResult.assetIdentifier else {
            print("No asset selected")
            return
        }
        
        // Fetch the PHAsset using the assetIdentifier
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        
        guard let asset = fetchResult.firstObject else {
            print("Asset not found")
            return
        }
        
        // Load the image using PHImageManager
        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: 3048, height: 3048) // Adjust as needed
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true // iCloud image access
        
        imageManager.requestImageDataAndOrientation(for: asset, options: options) { [weak self] data, uti, orientation, info in
            guard let self = self else { return }
            if let data = data {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self else { return }
                    autoreleasepool {
                        let downsample = self.downsample(imageData: data, to: 1500)!
                        DispatchQueue.main.async { [weak self] in
                            self?.delegate?.didSelectPhoto(downsample)
                        }
                        print("Original image loaded successfully",downsample.size)
                    }
                }
            } else {
                 print("Failed to load original image")
            }
        }
    }
    
    func downsample(imageData: Data, to maxDimension: CGFloat) -> UIImage? {
        autoreleasepool {
            let options = [kCGImageSourceShouldCache: false] as CFDictionary
            guard let src = CGImageSourceCreateWithData(imageData as CFData, options) else { return nil }

            let downOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: Int(maxDimension)
            ] as CFDictionary

            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(src, 0, downOptions) else { return nil }
            return UIImage(cgImage: cgImage)
        }
    }
}

extension UIImage {
    
    
    // Resize to specific dimensions (may distort aspect ratio)
    func resized(to size: CGSize) -> UIImage {
        autoreleasepool {
            return UIGraphicsImageRenderer(size: size).image { _ in
                self.draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
    
    // Resize while maintaining aspect ratio
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        autoreleasepool {
            let scale: CGFloat
            if self.size.width > self.size.height {
                scale = maxDimension / self.size.width
            } else {
                scale = maxDimension / self.size.height
            }
            
            let newSize = CGSize(
                width: self.size.width * scale,
                height: self.size.height * scale
            )
            
            return UIGraphicsImageRenderer(size: newSize).image { _ in
                self.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }
    }
    
    // Resize to specific width while maintaining aspect ratio
    func resized(toWidth width: CGFloat) -> UIImage {
        autoreleasepool {
            let scale = width / self.size.width
            let newHeight = self.size.height * scale
            let newSize = CGSize(width: width, height: newHeight)
            
            return UIGraphicsImageRenderer(size: newSize).image { _ in
                self.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }
    }
    
    // Resize to specific height while maintaining aspect ratio
    func resized(toHeight height: CGFloat) -> UIImage {
        autoreleasepool {
            let scale = height / self.size.height
            let newWidth = self.size.width * scale
            let newSize = CGSize(width: newWidth, height: height)
            
            return UIGraphicsImageRenderer(size: newSize).image { _ in
                self.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }
    }
}
