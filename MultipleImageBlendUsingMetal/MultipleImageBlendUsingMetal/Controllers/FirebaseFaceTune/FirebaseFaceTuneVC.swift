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
    @IBOutlet weak var skinBtn: UIButton!
    @IBOutlet weak var shapeBtn: UIButton!
    @IBOutlet weak var lookBtn: UIButton!
    
    
    private var faceLandmarkerService: FaceLandmarkerService?
    
    var isFirstTimeLoad = true
    //let modelPath: String? = Bundle.main.path(forResource: "face_landmarker", ofType: "task")
    private let backgroundQueue = DispatchQueue(label: "com.google.mediapipe.cameraController.backgroundQueue")
    
    private var photoPicker: PhotoPicker? = nil
    private var image: MTIImage? = nil
    private var boundingBox: CGRect = .zero
    private var isServiceInitialized = false
    private var overlayView: OverlayView!
    var faceTuneModelV2 = FaceTuneFilterModelV2()
    
    lazy var optionsBtn : [UIButton] = [skinBtn, shapeBtn, lookBtn]
    private var currentSelectedShapeOption: ShapeOption = .facialProportion
    private var currentSelectedLookOption: Looks = .eyeLashesh
    var currentCategory: FeatureCategory = .Shape
    private var selectedIndex = 0
    
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
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        registerCollectionViewCell()
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
    
    private func registerCollectionViewCell() {
        // Register cell
        self.collectionView.register(UINib(nibName: TuneOptionCollectionViewCell.cellID, bundle: nil), forCellWithReuseIdentifier: TuneOptionCollectionViewCell.cellID)
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal // or .vertical
        layout.minimumLineSpacing = 10       // space between rows/items horizontally
        layout.minimumInteritemSpacing = 10   // space between items in same row
        layout.itemSize = CGSize(width: 80.0, height: 44.0) // fixed cell size
        collectionView.collectionViewLayout = layout
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
        self.valueShowLabelText.text = "\(Int(sender.value))"
        guard var orginalImage = self.image else {return}
       // let img = faceTuneModelV2.applyAllFilter(scaleValue: sender.value,
                                                // image: orginalImage,
                                                 //filterName: ShapeOption.eyes.rawValue)
        
      
        //self.convertPointsForFace(self.leftEyePoints, self.boundingBox, value: sender.value)
        let value = sender.value
        switch currentCategory {
        case .Skin:
            break
        case .Shape:
            orginalImage = self.faceTuneModelV2.applyAllFilter(scaleValue: value,
                                                            image: orginalImage,
                                                               filterName: self.currentSelectedShapeOption.rawValue) ?? MTIImage.black
            break
        case .Look:
            orginalImage = self.faceTuneModelV2.applyAllFilter(scaleValue: value,
                                                            image: orginalImage,
                                                            filterName: self.currentSelectedLookOption.rawValue) ?? MTIImage.black
        }
        
        DispatchQueue.main.async {
            self.imageView.image = orginalImage
        }
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
    
    
    @IBAction func tappedOnMenuOption(_ sender: UIButton) {
        debugPrint("tappedOnMenuOptionBtn",sender.tag)
        switch sender.tag {
        case 2000:
            self.currentCategory = .Skin
            debugPrint("Skin Tag",sender.tag)
        case 2001:
            self.currentCategory = .Shape
            debugPrint("Shapes Tag",sender.tag)
        case 2002:
            self.currentCategory = .Look
            debugPrint("Look Tag",sender.tag)
        default:
            break
        }
        setSelectedBtnTitleColor(index: sender.tag)
        self.collectionView.reloadData()
    }
    
    private func setSelectedBtnTitleColor(index: Int) {
        for btn in optionsBtn {
            if btn.tag == index {
                btn.setTitleColor(.red, for: .normal)
            } else {
                btn.setTitleColor(.blue, for: .normal)
            }
        }
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
    
    private func setCurretnSelectShapeOptions(shapeOptions: ShapeOption) {
        self.currentSelectedShapeOption = shapeOptions
        var value: Float = 0.0
        switch shapeOptions {
        case .facialProportion:
            value = Float(faceTuneModelV2.faceProportionFilter.scaleFactor)
            break
        case .eyes:
            value = Float(faceTuneModelV2.eyeFilterModel.scaleFactor)
        case .nose:
            value = Float(faceTuneModelV2.noseFilterModel.scaleFactor)
        case .lips:
            value = Float(faceTuneModelV2.lipsFilterModel.scaleFactor)
        case .cheeks:
            value = Float(faceTuneModelV2.jawFilterModel.scaleFactor)
        case .eyeBrow:
            value = Float(faceTuneModelV2.eyeBrowFilterModel.scaleFactor)
        }
        self.centerOriginSlider.value = value
        self.valueShowLabelText.text = "\(value)"
    }
    
    private func setCurrentSelectedLooksOption(look: Looks) {
        self.currentSelectedLookOption = look
        var value: Float = 0.0
        switch look {
        case .eyeLashesh:
            value = self.faceTuneModelV2.eyelashFilterModel.scaleFactor
        case .eyeContrast:
            value = self.faceTuneModelV2.eyeBrightnessFilterModel.scaleFactor
        case .teethWhitening:
            value = self.faceTuneModelV2.teethWhiteningModel.scaleFactor
        default:
            break
        }
        self.centerOriginSlider.value = value
        self.valueShowLabelText.text = "\(value)"
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
                            self.faceTuneModelV2.updateEyeBrowFilter()
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

//MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension FirebaseFaceTuneVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        debugPrint("featureOptions[currentCategory]?.count ?? 0",featureOptions[currentCategory]?.count ?? 0)
        return featureOptions[currentCategory]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TuneOptionCollectionViewCell.cellID,
                                                            for: indexPath) as? TuneOptionCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        if selectedIndex == indexPath.item {
            cell.layer.borderColor = UIColor.red.cgColor
        } else {
            cell.layer.borderColor = UIColor.black.cgColor
        }
        if let enumCase = featureOptions[currentCategory]?[indexPath.item] {
            switch enumCase {
            case let skin as Skin:
                cell.setName(name: skin.rawValue)
            case let shape as ShapeOption:
                cell.setName(name: shape.rawValue)
            case let look as Looks:
                cell.setName(name: look.rawValue)
            default:
                break
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selected = featureOptions[currentCategory]?[indexPath.item] else { return }
        
        self.selectedIndex = indexPath.item
        
        switch selected {
        case let skin as Skin:
            print("Selected Jaw: \(skin.rawValue)")
            // call jaw effect function here
        case let shape as ShapeOption:
            setCurretnSelectShapeOptions(shapeOptions: shape)
            print("Selected Lips: \(shape.rawValue)")
            // call lips effect function here
        case let look as Looks:
            print("Selected Nose: \(look.rawValue)")
            setCurrentSelectedLooksOption(look: look)
            // call nose effect function here
        default:
            break
        }
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let text: String
        if let enumCase = featureOptions[currentCategory]?[indexPath.item] {
            switch enumCase {
            case let skin as Skin:
                text = skin.rawValue
            case let shape as ShapeOption:
                text = shape.rawValue
            case let look as Looks:
                text = look.rawValue
            default:
                text = ""
            }
        } else {
            text = ""
        }
        
        // Calculate width based on text
        let font = UIFont.systemFont(ofSize: 16) // Use the font your cell label uses
        let padding: CGFloat = 20 // left + right padding
        let textWidth = text.size(withAttributes: [.font: font]).width
        let cellWidth = textWidth + padding
        
        let height: CGFloat = 44 // Or whatever height your cell uses
        return CGSize(width: cellWidth, height: height)
    }

}

