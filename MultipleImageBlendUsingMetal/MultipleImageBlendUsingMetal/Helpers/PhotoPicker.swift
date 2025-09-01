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
  
    func showPhotoPicker(controller: UIViewController) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1  // Change the limit based on your needs
        config.filter = .images    // You can also filter by .videos or other media types
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        controller.present(picker, animated: true)
    }
    
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
                        //self.setGalleryImg(image: image.fixedOrientation())
                        let resized = image.fixedOrientation().resized(toMaxDimension: 1440)
                        self.delegate?.didSelectPhoto(resized)
                    }
                } else if let error = error {
                    print("Failed to load image: \(error.localizedDescription)")
                }
            }
        }
    }
    
}

extension UIImage {
    // Resize to specific dimensions (may distort aspect ratio)
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // Resize while maintaining aspect ratio
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
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
    
    // Resize to specific width while maintaining aspect ratio
    func resized(toWidth width: CGFloat) -> UIImage {
        let scale = width / self.size.width
        let newHeight = self.size.height * scale
        let newSize = CGSize(width: width, height: newHeight)
        
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // Resize to specific height while maintaining aspect ratio
    func resized(toHeight height: CGFloat) -> UIImage {
        let scale = height / self.size.height
        let newWidth = self.size.width * scale
        let newSize = CGSize(width: newWidth, height: height)
        
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
