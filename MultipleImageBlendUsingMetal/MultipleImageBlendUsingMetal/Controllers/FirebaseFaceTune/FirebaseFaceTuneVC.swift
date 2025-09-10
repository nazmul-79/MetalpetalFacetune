//
//  FirebaseFaceTuneVC.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 2/9/25.
//

import UIKit
import MetalPetal
import Photos
import AVFoundation
import MediaPipeTasksVision

class FirebaseFaceTuneVC: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var imageView: MTIImageView!
    @IBOutlet weak var valueShowLabelText: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var centerOriginSlider: CenterOriginSlider!
    @IBOutlet weak var containerScrollView: UIScrollView!
    
    private var faceLandmarkerService: FaceLandmarkerService?
    
    var isFirstTimeLoad = true
    //let modelPath: String? = Bundle.main.path(forResource: "face_landmarker", ofType: "task")
    private let backgroundQueue = DispatchQueue(label: "com.google.mediapipe.cameraController.backgroundQueue")
    
    private var photoPicker: PhotoPicker? = nil
    private var image: MTIImage? = nil
    private var boundingBox: CGRect = .zero
    private var isServiceInitialized = false
    private var overlayView: OverlayView!
    var faceTuneModel = FaceTuneFilterModel()
    var faceTuneModelV2 = FaceTuneFilterModelV2()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeFaceLandmarkerIfNeeded()
        photoPicker = PhotoPicker()
        photoPicker?.delegate = self
        imageView.resizingMode = .aspect
        containerScrollView.delegate = self
        containerScrollView.minimumZoomScale = 1.0
        containerScrollView.maximumZoomScale = 5.0
        containerScrollView.zoomScale = 1.0
        self.imageView.backgroundColor = .white
    }
    
    deinit {
        debugPrint("Deinit Called")
        cleanupFaceLandmarker()
        self.photoPicker = nil
        self.image = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstTimeLoad {
            self.isFirstTimeLoad = false
            self.view.layoutIfNeeded()
            overlayView = OverlayView(frame: imageView.bounds)
            overlayView.backgroundColor = .clear
            overlayView.isUserInteractionEnabled = false
            imageView.addSubview(overlayView)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        overlayView?.faceOverlays = []
        cleanupFaceLandmarker()
    }
    
    private func faceLandMarKCreate() {
        
    }
    
    @IBAction func tappedOnCancelBtn(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func tappedOnGallery(_ sender: UIButton) {
        self.requestPhotoLibraryPermission()
    }
    
    @IBAction func tappedOnMainMenuBtn(_ sender: UIButton) {
        debugPrint("tappedOnMainMenuBtn sender ",sender.tag)
    }
    
    @IBAction func centerOriginSliderAction(_ sender: CenterOriginSlider) {
        debugPrint("Value ",sender.value)
        let img = faceTuneModelV2.applyAllFilter(scaleValue: sender.value,
                                                 image: self.image!,
                                                 filterName: ShapeOption.eyes.rawValue)
//        let fitler = MTIBlendFilter(blendMode: .screen)
//        fitler.inputImage = img
//        fitler.inputBackgroundImage = self.image!
        self.imageView.image = img
    }
    
    private func cleanupFaceLandmarker() {
        // remove wrapper reference
        faceLandmarkerService?.faceLandmarker = nil
        faceLandmarkerService = nil

        // other cleanup
        photoPicker?.delegate = nil
        photoPicker = nil

        overlayView?.faceOverlays = []
        overlayView?.removeFromSuperview()
        overlayView = nil

        // free heavy images / GPU textures
        imageView.image = nil
        image = nil
    }

    
    private func initializeFaceLandmarkerIfNeeded() {
        guard !isServiceInitialized else { return }
        autoreleasepool {
            faceLandmarkerService = FaceLandmarkerService.stillImageLandmarkerService(
                modelPath: InferenceConfigurationManager.sharedInstance.modelPath,
                numFaces: InferenceConfigurationManager.sharedInstance.numFaces,
                minFaceDetectionConfidence: InferenceConfigurationManager.sharedInstance.minFaceDetectionConfidence,
                minFacePresenceConfidence: InferenceConfigurationManager.sharedInstance.minFacePresenceConfidence,
                minTrackingConfidence: InferenceConfigurationManager.sharedInstance.minTrackingConfidence,
                delegate: InferenceConfigurationManager.sharedInstance.delegate)
            
            isServiceInitialized = true
            debugPrint("Face Landmarker Service Initialized")
        }
    }
    
    func resizedImage(_ image: UIImage, maxSize: CGFloat = 512) -> UIImage {
        autoreleasepool {
            let scale = min(maxSize / image.size.width, maxSize / image.size.height)
            if scale >= 1 { return image } // already small
            let newSize = CGSize(width: image.size.width * scale,
                                 height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return resized!
        }
    }
}

//MARK: - requestPhotoLibraryPermission
extension FirebaseFaceTuneVC {
    func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
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
        photoPicker?.showPhotoPicker(controller: self)
    }
    
    // Delegate method (must have)
       func viewForZooming(in scrollView: UIScrollView) -> UIView? {
           return imageView
       }
    
    // MARK: Helper Functions
    func offsetsAndScaleFactor(
      forImageOfSize imageSize: CGSize,
      tobeDrawnInViewOfSize viewSize: CGSize,
      withContentMode contentMode: UIView.ContentMode)
    -> (xOffset: CGFloat, yOffset: CGFloat, scaleFactor: Double) {

      let widthScale = viewSize.width / imageSize.width;
      let heightScale = viewSize.height / imageSize.height;

      var scaleFactor = 0.0

      switch contentMode {
      case .scaleAspectFill:
        scaleFactor = max(widthScale, heightScale)
      case .scaleAspectFit:
        scaleFactor = min(widthScale, heightScale)
      default:
        scaleFactor = 1.0
      }

      let scaledSize = CGSize(
        width: imageSize.width * scaleFactor,
        height: imageSize.height * scaleFactor)
      let xOffset = (viewSize.width - scaledSize.width) / 2
      let yOffset = (viewSize.height - scaledSize.height) / 2

      return (xOffset, yOffset, scaleFactor)
    }
    
    // Helper to get object overlays from detections.
    func faceOverlays(
      fromMultipleFaceLandmarks landmarks: [[NormalizedLandmark]],
      inferredOnImageOfSize originalImageSize: CGSize,
      ovelayViewSize: CGSize,
      imageContentMode: UIView.ContentMode,
      andOrientation orientation: UIImage.Orientation) -> [FaceOverlay] {

        var faceOverlays: [FaceOverlay] = []

        guard !landmarks.isEmpty else {
          return []
        }

          let offsetsAndScaleFactor = self.offsetsAndScaleFactor(
          forImageOfSize: originalImageSize,
          tobeDrawnInViewOfSize: ovelayViewSize,
          withContentMode: imageContentMode)
          
        for faceLandmarks in landmarks {
          var transformedFaceLandmarks: [CGPoint]!
          
            debugPrint("Point",faceLandmarks)
            
          switch orientation {
          case .left:
            transformedFaceLandmarks = faceLandmarks.map({CGPoint(x: CGFloat($0.y), y: 1 - CGFloat($0.x))})
          case .right:
            transformedFaceLandmarks = faceLandmarks.map({CGPoint(x: 1 - CGFloat($0.y), y: CGFloat($0.x))})
          case .leftMirrored:
              transformedFaceLandmarks = faceLandmarks.map {
                     CGPoint(
                         x: CGFloat($0.y),         // horizontal flip
                         y: CGFloat($0.x)              // swapped coordinate
                     )
                 }
          default:
            transformedFaceLandmarks = faceLandmarks.map({CGPoint(x: CGFloat($0.x), y: CGFloat($0.y))})
          }
            
            debugPrint("Point",transformedFaceLandmarks.count)

          let dots: [CGPoint] = transformedFaceLandmarks.map({CGPoint(x: CGFloat($0.x) * originalImageSize.width * offsetsAndScaleFactor.scaleFactor + offsetsAndScaleFactor.xOffset, y: CGFloat($0.y) * originalImageSize.height * offsetsAndScaleFactor.scaleFactor + offsetsAndScaleFactor.yOffset)})

          var lineConnections: [LineConnection] = []
            /*lineConnections.append(LineConnection(
            color: DefaultConstants.faceOvalConnectionsColor,
            lines: FaceLandmarker.faceOvalConnections()
              .map({ connection in
              let start = dots[Int(connection.start)]
              let end = dots[Int(connection.end)]
              return Line1(from: start, to: end)
              })))
          lineConnections.append(LineConnection(
            color: DefaultConstants.rightEyebrowConnectionsColor,
            lines: FaceLandmarker.rightEyebrowConnections()
              .map({ connection in
              let start = dots[Int(connection.start)]
              let end = dots[Int(connection.end)]
                return Line1(from: start, to: end)
            })))
          lineConnections.append(LineConnection(
            color: DefaultConstants.leftEyebrowConnectionsColor,
            lines: FaceLandmarker.leftEyebrowConnections()
            .map({ connection in
            let start = dots[Int(connection.start)]
            let end = dots[Int(connection.end)]
              return Line1(from: start, to: end)
          })))
          lineConnections.append(LineConnection(
            color: DefaultConstants.rightEyeConnectionsColor,
            lines: FaceLandmarker.rightEyeConnections()
            .map({ connection in
            let start = dots[Int(connection.start)]
            let end = dots[Int(connection.end)]
              return Line1(from: start, to: end)
          })))
          lineConnections.append(LineConnection(
            color: DefaultConstants.leftEyeConnectionsColor,
            lines: FaceLandmarker.leftEyeConnections()
            .map({ connection in
            let start = dots[Int(connection.start)]
            let end = dots[Int(connection.end)]
              return Line1(from: start, to: end)
          })))
          lineConnections.append(LineConnection(
            color: DefaultConstants.lipsConnectionsColor,
            lines: FaceLandmarker.lipsConnections()
            .map({ connection in
            let start = dots[Int(connection.start)]
            let end = dots[Int(connection.end)]
              return Line1(from: start, to: end)
          })))*/
            
            let innerLipsConnections: [(Int, Int)] = [
                (78, 95), (95, 88), (88, 178), (178, 87), (87, 14),
                (14, 317), (317, 402), (402, 318), (318, 324), (324, 308),
                (308, 415), (415, 310), (310, 311), (311, 312), (312, 13),
                (13, 82), (82, 81), (81, 80), (80, 191), (191, 78) // closed loop
            ]
            
            let innerLipsIndices: [Int] = [
                78, 95, 88, 178, 87, 14, 317, 402,
                318, 324, 308, 415, 310, 311, 312,
                13, 82, 81, 80, 191
            ]
            
            /*lineConnections.append(LineConnection(
                color: DefaultConstants.lipsConnectionsColor,
                lines: FaceLandmarker.lipsConnections()
                    .compactMap { connection -> Line1? in
                        // যদি connection start বা end inner lips এ থাকে → বাদ দাও
//                        if innerLipsIndices.contains(Int(connection.start)) ||
//                           innerLipsIndices.contains(Int(connection.end)) {
//                            return nil
//                        }
                        let start = dots[Int(connection.start)]
                        let end = dots[Int(connection.end)]
                        return Line1(from: start, to: end)
                    }
            ))*/
            
            let outerLipsConnections: [(Int, Int)] = [
                (61, 146), (146, 91), (91, 181), (181, 84), (84, 17),
                (17, 314), (314, 405), (405, 321), (321, 375), (375, 291),
                (291, 409), (409, 270), (270, 269), (269, 267), (267, 0),
                (0, 37), (37, 39), (39, 40), (40, 185), (185, 61) // closed loop
            ]
            
//        lineConnections.append(LineConnection(
//                color: DefaultConstants.lipsConnectionsColor,
//                lines: innerLipsConnections.map { connection in
//                    let start = dots[connection.0]
//                    let end = dots[connection.1]
//                    return Line1(from: start, to: end)
//                }
//            ))
            
            // 🔥 Only keep inner lips points
                let innerLipsDots = innerLipsIndices.compactMap { index in
                    index < dots.count ? dots[index] : nil
                }
            
            let leftEye: [Int] =  [2, 98, 97, 99, 100, 101, 102, 103, 67, 66, 105, 63, 51]

//https://gist.github.com/Asadullah-Dal17/fd71c31bac74ee84e6a31af50fa62961
            
            
            //[469, 471,159,158,160,468,171,145]
            
            //[474, 475, 476, 477 ] right eyeris
            
            
            
            //[113, 225, 65, 66, 107, 55, 193]
            
            
            //[52, 53, 46, 225, 224, 223, 222] brow er kacha kachi
            
            
            //[112, 26, 22, 23, 24, 110, 25, 226] //Choker pata nicher
            
            
            //[33, 7, 163, 144, 145, 153, 154, 155,
                                 // 133, 173, 157, 158, 159, 160, 161, 246] //mian region
            
            /*[33, 7, 163, 144, 145, 153, 154, 155,
            133, 173, 157, 158, 159, 160, 161, 246,
            112, 26, 22, 23, 24, 110, 25, 226]*/
           
            let leftEyeDots = leftEye.compactMap { index in
                index < dots.count ? dots[index] : nil
            }
        
            
            debugPrint("Inner Lips Point", innerLipsDots)

          faceOverlays.append(FaceOverlay(dots: dots, lineConnections: lineConnections))
        }

        return faceOverlays
      }
    
    private func getNoramlizePoint(innerLipsDots: [CGPoint] ) -> [CGPoint] {
        let imageSize = self.image!.size
        let viewSize = imageView.bounds.size

        let widthScale = viewSize.width / imageSize.width
        let heightScale = viewSize.height / imageSize.height

        let scale = min(widthScale, heightScale) // Aspect Fit

        // offsets (image centered in view)
        let xOffset = (viewSize.width - imageSize.width * scale) / 2
        let yOffset = (viewSize.height - imageSize.height * scale) / 2

        let normalizedPoints: [CGPoint] = innerLipsDots.map { point in
            // remove offset, scale back to original image
            let x = (point.x - xOffset) / scale
            let y = (point.y - yOffset) / scale
            // normalize 0…1 for shader
            //return SIMD2(Float(x / imageSize.width), Float(y / imageSize.height))
            return CGPoint(x: x, y: y)
        }
        return normalizedPoints
    }

}

extension FirebaseFaceTuneVC: PhotoPickerDelegate {
    func didSelectPhoto(_ photo: UIImage) {
        image = MTIImage(cgImage: photo.cgImage!,
                         options: [.SRGB: false],
                         isOpaque: false).unpremultiplyingAlpha()
       
        debugPrint("Image Orientation", photo.imageOrientation.rawValue)
        backgroundQueue.async { [weak self] in
            guard let self = self else {return}
            autoreleasepool {
                self.faceTuneModel.imageSize = photo.size
                let photoR = self.resizedImage(photo, maxSize: 256)
                debugPrint("OriginalImage size",photoR.size, photo.size )
                let resultBundle = self.faceLandmarkerService?.detect(image: photoR)
                let faceLandmarkerResult = resultBundle?.faceLandmarkerResults.first
                let faceLandmarkerResult1 = faceLandmarkerResult
                
              
                DispatchQueue.main.async { [weak self] in
                    autoreleasepool {
                        guard let self = self else { return }
                        let faceOverlays = self.faceOverlays(
                            fromMultipleFaceLandmarks: faceLandmarkerResult??.faceLandmarks ?? [],
                            inferredOnImageOfSize: photo.size,
                            ovelayViewSize: self.imageView.bounds.size,
                            imageContentMode: .scaleAspectFit,
                            andOrientation: photo.imageOrientation)
                        self.containerScrollView.zoomScale = 1.0
                        self.imageView.image = self.image
                        
                        if let dots = faceOverlays.first?.dots {
                            self.faceTuneModelV2.imageSize = photo.size
                            self.faceTuneModelV2.allPoints = dots
                            self.faceTuneModelV2.imageViewBounds = self.imageView.bounds
                            self.faceTuneModelV2.updateEyeFilterModel()
                            //self.faceTuneModel.updateTeethWhiteningFilter(innerLipsPoint: normalizePoint,
                                                                          //size: photo.size)
                        }
                       
                       //self.overlayView.faceOverlays = faceOverlays
                    }
                }
                debugPrint("Update",faceLandmarkerResult1??.faceLandmarks.first?.count)
            }
        }
    }
}


/// A straight line.
struct Line1 {
  let from: CGPoint
  let to: CGPoint
}

/// Line connection
struct LineConnection {
  let color: UIColor
  let lines: [Line1]
}

/**
 This structure holds the display parameters for the overlay to be drawon on a detected object.
 */
struct FaceOverlay {
  let dots: [CGPoint]
  let lineConnections: [LineConnection]
}

class OverlayView: UIView {
    var faceOverlays: [FaceOverlay] = [] {
        didSet { setNeedsDisplay() }
    }
    
    override func draw(_ rect: CGRect) {
        guard !faceOverlays.isEmpty else { return }
        
        for faceOverlay in faceOverlays {
            // draw dots
            for (index, dot) in faceOverlay.dots.enumerated() {
                /*let dotRect = CGRect(
                    x: dot.x - DefaultConstants.pointRadius / 2,
                    y: dot.y - DefaultConstants.pointRadius / 2,
                    width: DefaultConstants.pointRadius,
                    height: DefaultConstants.pointRadius
                )
                let path = UIBezierPath(ovalIn: dotRect)
                DefaultConstants.pointFillColor.setFill()
                DefaultConstants.pointColor.setStroke()
                path.stroke()
                path.fill()*/
                
                // Index text
                let indexString = "\(index)" as NSString
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 5, weight: .regular),
                    .foregroundColor: UIColor.white
                ]
                let textSize = indexString.size(withAttributes: attributes)
                let textPoint = CGPoint(
                    x: dot.x - textSize.width / 2,
                    y: dot.y - textSize.height / 2
                )
                indexString.draw(at: textPoint, withAttributes: attributes)
            }
            
            // draw lines
            for lineConnection in faceOverlay.lineConnections {
             let path = UIBezierPath()
             for line in lineConnection.lines {
             path.move(to: line.from)
             path.addLine(to: line.to)
             }
             path.lineWidth = DefaultConstants.lineWidth
             lineConnection.color.setStroke()
             path.stroke()
             }
        }
    }
}
