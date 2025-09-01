//
//  FaceTuneVC.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 11/8/25.
//

import UIKit
import PhotosUI
import Photos
import MetalPetal
import Vision
//https://www.bombaysoftwares.com/blog/real-time-face-detection-on-ios

class FaceTuneVC: UIViewController {
    
    @IBOutlet weak var imageView: MTIImageView!
    @IBOutlet weak var optionCollectionView: UICollectionView!
    @IBOutlet weak var sliderValueLabel: UILabel!
    @IBOutlet weak var centerOriginSlider: CenterOriginSlider!
    @IBOutlet weak var skinBtn: UIButton!
    @IBOutlet weak var ShapesBtn: UIButton!
    @IBOutlet weak var lookBtn: UIButton!
    
    
    var currentCategory: FeatureCategory = .Skin
    
    let shapeLayer = CAShapeLayer()
    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    let faceDetectionRequest = VNSequenceRequestHandler()
    private var isFirstTime: Bool = true
    private var selectedIndex = 0
    
    
    let photoPicker = PhotoPicker()
    private var image: MTIImage? = nil
    private var boundingBox: CGRect = .zero
  
    private var rightEyePoints: [CGPoint] = []
    private var leftEyePoints: [CGPoint] = []
    private var outerLipsPoints: [CGPoint] = []
    private var nosePoints: [CGPoint] = []
    private var currentTransform = CGAffineTransform.identity
    private var jawPoints: [CGPoint] = []
    private var leftEyebrow: [CGPoint] = []
    private var rightEyeBrow: [CGPoint] = []
    
    var faceTuneModel = FaceTuneFilterModel()
    lazy var optionsBtn : [UIButton] = [skinBtn, ShapesBtn, lookBtn]
    private var currentSelectedShapeOption: ShapeOption = .facialProportion
    private var currentSelectedLookOption: Looks = .eyeLashesh

    override func viewDidLoad() {
        super.viewDidLoad()
        photoPicker.delegate = self
        imageView.resizingMode = .aspectFill
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
               imageView.addGestureRecognizer(pinchGesture)
               imageView.isUserInteractionEnabled = true
        pinchGesture.delegate = self
             let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
             imageView.addGestureRecognizer(panGesture)
    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstTime {
            self.isFirstTime = false
            self.view.layoutIfNeeded()
            view.layer.addSublayer(shapeLayer)
            optionCollectionView.dataSource = self
            optionCollectionView.delegate = self
            shapeLayer.frame = imageView.bounds
            shapeLayer.strokeColor = UIColor.blue.cgColor
            shapeLayer.lineWidth = 4.0
            self.registerCollectionViewCell()
        }
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
           switch gesture.state {
           case .began, .changed:
               // Apply incremental scale
               let scale = gesture.scale
               imageView.transform = imageView.transform.scaledBy(x: scale, y: scale)
               gesture.scale = 1.0 // reset so scaling is incremental
           case .ended, .cancelled:
               // Optionally clamp scale
               var finalScale = imageView.transform.a
               finalScale = max(1.0, min(finalScale, 10.0)) // min=1, max=3
               imageView.transform = CGAffineTransform(scaleX: finalScale, y: finalScale)
           default:
               break
           }
       }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let imageView = self.imageView, let superview = imageView.superview else { return }
        let translation = gesture.translation(in: superview)
        
        if gesture.state == .began || gesture.state == .changed {
            imageView.center = CGPoint(
                x: imageView.center.x + translation.x,
                y: imageView.center.y + translation.y
            )
            gesture.setTranslation(.zero, in: superview)
        }
    }
    
    @IBAction func tappedOnCancelButton(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func TappedOnGalleryButton(_ sender: UIButton) {
        requestPhotoLibraryPermission()
    }
    
    
    @IBAction func centerOriginSlider(_ sender: CenterOriginSlider) {
        debugPrint("Slider Value",sender.value)
        self.sliderValueLabel.text = "\(Int(sender.value))"
        //self.convertPointsForFace(self.leftEyePoints, self.boundingBox, value: sender.value)
        let value = sender.value
        var outputImage = self.image
        switch currentCategory {
        case .Skin:
            break
        case .Shape:
            outputImage = self.faceTuneModel.applyAllFilter(scaleValue: value,
                                                            image: outputImage!,
                                                            filterName: self.currentSelectedShapeOption.rawValue)
            break
        case .Look:
            outputImage = self.faceTuneModel.applyAllFilter(scaleValue: value,
                                                            image: outputImage!,
                                                            filterName: self.currentSelectedLookOption.rawValue)
        }
        
        DispatchQueue.main.async {
            self.imageView.image = outputImage
        }
        /* let value = sender.value
         DispatchQueue.global(qos: .userInitiated).async {
         autoreleasepool {
         var outputImage = self.image
         switch self.currentCategory {
         case .eye:
         outputImage = self.faceTuneModel.applyAllFilter(scaleValue: value,
         image: outputImage!,
         category: .eyes)
         case .eyebrow:
         outputImage = self.faceTuneModel.applyAllFilter(scaleValue: value,
         image: outputImage!,
         category: .eyeBrow)
         case .nose:
         outputImage = self.faceTuneModel.applyAllFilter(scaleValue: value,
         image: outputImage!,
         category: .nose)
         break
         case .lips:
         outputImage = self.faceTuneModel.applyAllFilter(scaleValue: value,
         image: outputImage!,
         category: .lips)
         break
         case .jaw:
         outputImage = self.faceTuneModel.applyAllFilter(scaleValue: value,
         image: outputImage!,
         category: .chin)
         break
         default:
         break
         }
         
         }
         }*/
    }
    
    private func registerCollectionViewCell() {
        // Register cell
        self.optionCollectionView.register(UINib(nibName: TuneOptionCollectionViewCell.cellID, bundle: nil), forCellWithReuseIdentifier: TuneOptionCollectionViewCell.cellID)
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal // or .vertical
        layout.minimumLineSpacing = 10       // space between rows/items horizontally
        layout.minimumInteritemSpacing = 10   // space between items in same row
        layout.itemSize = CGSize(width: 80.0, height: 44.0) // fixed cell size
        optionCollectionView.collectionViewLayout = layout
    }
    
    @IBAction func tappedOnMenuOptionBtn(_ sender: UIButton) {
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
        self.optionCollectionView.reloadData()
    }
    
    
    @IBAction func tappedOnFeatureOptionBtn(_ sender: UIButton) {
        switch sender.tag {
        case 2000:
            //currentCategory = .nose
            self.centerOriginSlider.value = Float(faceTuneModel.jawFilterModel.scaleFactor)
            self.sliderValueLabel.text = "\(faceTuneModel.jawFilterModel.scaleFactor)"
            //currentCategory = .jaw
        case 2001:
            //currentCategory = .nose
            self.centerOriginSlider.value = Float(faceTuneModel.lipsFilterModel.scaleFactor)
            self.sliderValueLabel.text = "\(faceTuneModel.lipsFilterModel.scaleFactor)"
            //currentCategory = .lips
        case 2002:
            //currentCategory = .nose
            self.centerOriginSlider.value = faceTuneModel.noseFilterModel.scaleFactor
            self.sliderValueLabel.text = "\(faceTuneModel.noseFilterModel.scaleFactor)"
        case 2003:
            //currentCategory = .eye
            self.centerOriginSlider.value = faceTuneModel.eyeFilterModel.scaleFactor
            self.sliderValueLabel.text = "\(faceTuneModel.eyeFilterModel.scaleFactor)"
        case 2004:
            self.centerOriginSlider.value = faceTuneModel.eyeBrowFilterModel.scaleFactor
            self.sliderValueLabel.text = "\(faceTuneModel.eyeBrowFilterModel.scaleFactor)"
            //currentCategory = .eyebrow
        default:
            break
        }
        //self.imageView.image = self.image
        setSelectedBtnTitleColor(index: sender.tag)
        self.optionCollectionView.reloadData()
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
    
    private func setCurretnSelectShapeOptions(shapeOptions: ShapeOption) {
        self.currentSelectedShapeOption = shapeOptions
        var value: Float = 0.0
        switch shapeOptions {
        case .facialProportion:
            value = Float(faceTuneModel.faceProportionFilter.scaleFactor)
            break
        case .eyes:
            value = Float(faceTuneModel.eyeFilterModel.scaleFactor)
        case .nose:
            value = Float(faceTuneModel.noseFilterModel.scaleFactor)
        case .lips:
            value = Float(faceTuneModel.lipsFilterModel.scaleFactor)
        case .cheeks:
            value = Float(faceTuneModel.jawFilterModel.scaleFactor)
        case .eyeBrow:
            value = Float(faceTuneModel.eyeBrowFilterModel.scaleFactor)
        }
        self.centerOriginSlider.value = value
        self.sliderValueLabel.text = "\(value)"
    }
    
    private func setCurrentSelectedLooksOption(look: Looks) {
        self.currentSelectedLookOption = look
        var value: Float = 0.0
        switch look {
        case .eyeLashesh:
            value = self.faceTuneModel.eyelashFilterModel.scaleFactor
        case .eyeContrast:
            value = self.faceTuneModel.eyeBrightnessFilterModel.scaleFactor
        case .teethWhitening:
            value = self.faceTuneModel.teethWhiteningModel.scaleFactor
        default:
            break
        }
        self.centerOriginSlider.value = value
        self.sliderValueLabel.text = "\(value)"
    }
    
}

//MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension FaceTuneVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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


//MARK: - requestPhotoLibraryPermission
extension FaceTuneVC {
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

extension FaceTuneVC: PhotoPickerDelegate {
    func didSelectPhoto(_ photo: UIImage) {
        image = MTIImage(cgImage: photo.cgImage!,
                         options: [.SRGB: false],
                         isOpaque: false).unpremultiplyingAlpha()
        imageView.image = self.image
        shapeLayer.frame = imageView.frame
        shapeLayer.setAffineTransform(CGAffineTransform(scaleX: 1, y: -1))
        detectFace(on: CIImage(cgImage: photo.cgImage!))
    }
}

extension FaceTuneVC {
    func detectFace(on image: CIImage) {
        try? faceDetectionRequest.perform([faceDetection], on: image)
        if let results = faceDetection.results as? [VNFaceObservation] {
            
            if results.count == 0{
                DispatchQueue.main.async {
                    self.shapeLayer.sublayers?.removeAll()
                }
            }
            if !results.isEmpty {
                faceLandmarks.revision = 3
                faceLandmarks.inputFaceObservations = results
                detectLandmarks(on: image)
                DispatchQueue.main.async {
                    self.shapeLayer.sublayers?.removeAll()
                }
            }
        }
    }
    
    func detectLandmarks(on image: CIImage) {
        try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
        if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
            
            for observation in landmarksResults {
                
                DispatchQueue.main.async {
                    if let boundingBox = self.faceLandmarks.inputFaceObservations?.first?.boundingBox {
                        let faceBoundingBox = self.convertBoundingBox(observation.boundingBox,
                                                                      inImageView: self.imageView)
                        //different types of landmarks
                        //allPoints?.normalizedPoints
                        if let lefteye = observation.landmarks?.leftEye?.normalizedPoints,
                           let rightEye = observation.landmarks?.rightEye?.normalizedPoints,
                           let outerLips = observation.landmarks?.outerLips?.normalizedPoints,
                           let nose = observation.landmarks?.nose?.normalizedPoints,
                           let noseCrest =  observation.landmarks?.noseCrest?.normalizedPoints,
                           let allpoint = observation.landmarks?.allPoints?.normalizedPoints,
                           let lefteyebrow = observation.landmarks?.leftEyebrow?.normalizedPoints,
                           let rightEyebrow = observation.landmarks?.rightEyebrow?.normalizedPoints {
                            let neededIndices = [61,62,63,64,65,66,67,68,69,70,71,72,73]
                            let selectedPoints = neededIndices.compactMap { index -> CGPoint? in
                                return index < allpoint.count ? allpoint[index] : nil
                            }
                            
                          
                            
                            let faceRect = CGRect(
                                x: boundingBox.origin.x * self.image!.size.width,
                                y: (1.0 - boundingBox.origin.y - boundingBox.height) * self.image!.size.height,
                                width: boundingBox.width * self.image!.size.width,
                                height: boundingBox.height * self.image!.size.height
                            )
                            
                            var innerlips = observation.landmarks?.innerLips?.normalizedPoints
                            self.leftEyePoints =  lefteye
                            self.rightEyePoints = rightEye
                            self.outerLipsPoints = outerLips
                            self.jawPoints = selectedPoints
                            self.nosePoints = nose + noseCrest
                            self.boundingBox = faceRect
                            self.leftEyebrow = lefteyebrow
                            self.rightEyeBrow = rightEyebrow
                            
                            debugPrint("All Points", allpoint,faceRect)
                            self.sliderValueLabel.text = "0"
                            self.centerOriginSlider.value = 0
                            self.faceTuneModel.boundingBox = faceRect
                            self.faceTuneModel.imageSize = self.image!.size
                            self.faceTuneModel.updateEyeFilterModel(leftpoints: lefteye,
                                                                    rightEyePoints: rightEye)
                            self.faceTuneModel.updateEyeBrowFilter(leftEyeBrowPoints: lefteyebrow,
                                                                   rightEyeBrowPoints: rightEyebrow)
                            self.faceTuneModel.updateNoseFilter(nosePoints: nose + noseCrest)
                            self.faceTuneModel.updateLipsFilter(lipsPoints: outerLips)
                            let isTeeth = self.isTeethVisible(innerPoints: innerlips!)
                            
                            innerlips!.insert(allpoint[26], at: 0)
                            innerlips!.insert(allpoint[34], at: 4)
                            
                            self.faceTuneModel.updateJawFilter(jawPoints: selectedPoints)
                            self.faceTuneModel.updateFaceProportionFilter()
                            self.faceTuneModel.updateTeethWhiteningFilter(innerLipsPoint: innerlips!)
                            
                            debugPrint("All Points111", isTeeth,innerlips!,outerLips, allpoint[45])
                            
                          
                            //self.convertPointsForFace(allPoints, faceBoundingBox)
                        }
                    }
                }
            }
        }
        
    }
    

    func isTeethVisible(innerPoints: [CGPoint], threshold: CGFloat = 0.16) -> Bool {
        convertInnerLips1(innerlips: innerPoints)
        guard !innerPoints.isEmpty else { return false }
        
        let ys = innerPoints.map { $0.y }
        guard let maxY = ys.max(), let minY = ys.min() else { return false }
        
        let height = maxY - minY
        return height > threshold
    }

    
    func contentFrameForImageView(_ imageView: MTIImageView) -> CGRect {
        guard let image = imageView.image else { return .zero }
        let imageRatio = image.size.width / image.size.height
        let viewRatio = imageView.bounds.width / imageView.bounds.height
        
        if imageRatio > viewRatio {
            // Image is wider than view, height matches view's height
            let height = imageView.bounds.height
            let width = height * imageRatio
            let x = (imageView.bounds.width - width) / 2
            return CGRect(x: x, y: 0, width: width, height: height)
        } else {
            // Image is taller than view, width matches view's width
            let width = imageView.bounds.width
            let height = width / imageRatio
            let y = (imageView.bounds.height - height) / 2
            return CGRect(x: 0, y: y, width: width, height: height)
        }
    }
    
    func convertBoundingBox(_ boundingBox: CGRect, inImageView imageView: MTIImageView) -> CGRect {
        let contentFrame = contentFrameForImageView(imageView)
        
        let originX = boundingBox.origin.x * contentFrame.width + contentFrame.origin.x
        let originY = boundingBox.origin.y * contentFrame.height + contentFrame.origin.y
        let width = boundingBox.width * contentFrame.width
        let height = boundingBox.height * contentFrame.height
        
        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    func convertLandmarkPoints(_ points: [CGPoint], boundingBox: CGRect, inImageView imageView: MTIImageView) -> [CGPoint] {
        return points.map { point in
            let x = boundingBox.origin.x + point.x * boundingBox.width
            let y = boundingBox.origin.y + point.y * boundingBox.height
            return CGPoint(x: x, y: y)
        }
    }
    
    func convertLandmarkPointsForImage(_ points: [CGPoint], boundingBox: CGRect, imageSize: CGSize) -> [CGPoint] {
        return points.map { point in
            let x = boundingBox.origin.x + point.x * boundingBox.width
            let y = boundingBox.origin.y + (1.0 - point.y) * boundingBox.height // flip y inside bounding box
            return CGPoint(x: x, y: y)
        }
    }
    
    func convertInnerLips1(innerlips: [CGPoint]) {
        let convertedPoints = convertLandmarkPointsForImage(innerlips,
                                                                   boundingBox: self.boundingBox,
                                                                   imageSize: self.image!.size)
        
        let maskImg = createMaskImage(from: convertedPoints, imageSize: self.image!.size)
        
        //self.createLipMaskAndCenter(imageSize: self.image!.size, points: convertedPoints)
        
        debugPrint("Masking Image",maskImg)
        
    }

    func createMaskImage(from points: [CGPoint], imageSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Black background (mask=0)
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: imageSize))
        
        // Path for mask
        let path = UIBezierPath()
        guard let first = points.first else { return nil }
        path.move(to: first)
        for p in points.dropFirst() {
            path.addLine(to: p)
        }
        path.close()
        
        // Fill path white (mask=1)
        context.setFillColor(UIColor.white.cgColor)
        path.fill()
        
        let maskImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return maskImage
    }


    // Example usage inside your function
    func convertInnerLips(innerlips: [CGPoint]) -> UIImage? {
        guard let image = self.image else { return nil }
        let convertedPoints = convertLandmarkPointsForImage(innerlips,
                                                            boundingBox: self.boundingBox,
                                                            imageSize: image.size)
        
        let maskUIImage = createMaskImage(from: convertedPoints, imageSize: image.size)
        return maskUIImage
    }


    func convertPointsForFace(_ landmark: [CGPoint],
                              _ boundingBox: CGRect,
                              value: Float) {
        /*debugPrint("Total Point", landmark)
        //let convertedPoints = convertLandmarkPoints(landmark,
        // boundingBox: boundingBox,
        // inImageView: self.imageView)
        
        /*let faceLandmarkVertices = convertedPoints.map { point in
         Vertex(x: Double(point.x), y: Double(point.y))
         }
         
         DispatchQueue.main.async {
         // self.draw(vertices: faceLandmarkVertices, boundingBox: boundingBox)
         // self.drawChinCurve(points: convertedPoints)
         self.drawEye(points: convertedPoints)
        
         }
        
        let imageSize = self.image!.size
        
        if self.currentCategory == .eye {
           let normalizedBoundingBox = CGRect(
                x: boundingBox.origin.x / imageSize.width,
                y: boundingBox.origin.y / imageSize.height,
                width: boundingBox.size.width / imageSize.width,
                height: boundingBox.size.height / imageSize.height
            )

            let convertedPointsleftEye = convertLandmarkPointsForImage(self.leftEyePoints,
                                                                       boundingBox: self.boundingBox,
                                                                       imageSize: self.image!.size)
            
            let convertedPointsRightEye = convertLandmarkPointsForImage(self.rightEyePoints,
                                                                        boundingBox: self.boundingBox,
                                                                        imageSize: self.image!.size)
            
           
            
            let (lefteyeCenter, lefteyeRadiusX, lefteyeRadiusY) = calculateEyeEllipse(points: convertedPointsleftEye,
                                                                          imageSize: image!.size)
            
            let (righteyeCenter, righteyeRadiusX, righteyeRadiusY) = calculateEyeEllipse(points: convertedPointsRightEye,
                                                                          imageSize: image!.size)
            
            let filter = EyeMetalFilter()
            filter.leftEyeCenter = SIMD2<Float>(Float(lefteyeCenter.x / image!.size.width),
                                                Float(lefteyeCenter.y / image!.size.height))
            filter.leftEyeRadiusXY = SIMD2<Float>(Float(lefteyeRadiusX / image!.size.width),
                                             Float(lefteyeRadiusY / image!.size.height))
            
            filter.rightEyeCenter = SIMD2<Float>(Float(righteyeCenter.x / image!.size.width),
                                                Float(righteyeCenter.y / image!.size.height))
            
            filter.rightEyeRadiusXY = SIMD2<Float>(Float(righteyeRadiusX / image!.size.width),
                                             Float(righteyeRadiusY / image!.size.height))
            filter.leftScaleFactor = value  // slider এর value -10..10 এর মধ্যে
            filter.rightScaleFactor = value
            
            filter.inputImage = self.image*/
            
            let outputImage = self.faceTuneModel.applyEyeFilter(image: self.image!)
            
            DispatchQueue.main.async {
                self.imageView.image = outputImage
            }
        } else if currentCategory == .lips {
            let convertedPointsLips = convertLandmarkPointsForImage(self.outerLipsPoints,
                                                                       boundingBox: self.boundingBox,
                                                                       imageSize: self.image!.size)
            
            
            let (outerLipsCenter, outerLipsRadiusX, outerLipsRadiusY) = calculateLipEllipse(points: convertedPointsLips,
                                                                          imageSize: image!.size)
            
            
            // 3. Create filter
            /*let lipsFilter = LipsAirbrushFilter()
            lipsFilter.inputImage =  self.image
            lipsFilter.maskImage = maskImage.unpremultiplyingAlpha()
            lipsFilter.lipCenter = lipCenterUV
            lipsFilter.lipRadiusXY = lipRadiusXY
            lipsFilter.lipScaleFactor = value*/
            
            //debugPrint("convertedPointsLips",convertedPointsLips,lipCenterUV,lipRadiusXY)
            
           let lipsFilter = LipsMetalFilter()
            lipsFilter.inputImage = self.image
            lipsFilter.lipCenter = SIMD2<Float>(Float(outerLipsCenter.x / image!.size.width),
                                                Float(outerLipsCenter.y / image!.size.height))
            lipsFilter.lipRadiusXY =  SIMD2<Float>(Float(outerLipsRadiusX / image!.size.width),
                                                   Float(outerLipsRadiusY / image!.size.height))

            lipsFilter.lipScaleFactor = value // positive = enlarge, negative = shrink
            
            if let outputImage = lipsFilter.outputImage {
                DispatchQueue.main.async {
                    self.imageView.image = outputImage
                }
            }
        } else if self.currentCategory == .nose {
            let convertedPointsLips = convertLandmarkPointsForImage(self.nosePoints,
                                                                       boundingBox: self.boundingBox,
                                                                       imageSize: self.image!.size)
            
            let (noseCenterUV, noseRadiusXY) = self.createCenterAndRadius(imageSize: self.image!.size,
                                                                                   points: convertedPointsLips)
            
            let lipsFilter = NoseMetalFilter()
             lipsFilter.inputImage = self.image
             lipsFilter.noseCenter = noseCenterUV
             lipsFilter.noseRadiusXY = noseRadiusXY
             lipsFilter.noseScaleFactor = value // positive = enlarge, negative = shrink
             
             if let outputImage = lipsFilter.outputImage {
                 DispatchQueue.main.async {
                     self.imageView.image = outputImage
                 }
             }
        } else if self.currentCategory == .jaw {
            let convertedPointsLips = convertLandmarkPointsForImage(self.jawPoints,
                                                                       boundingBox: self.boundingBox,
                                                                       imageSize: self.image!.size)
            
            
            let chinCenters = computeSmoothChinCurveFast(points: convertedPointsLips, imageSize: imageSize)
            
            debugPrint("computeChinCurveCenters",convertedPointsLips, chinCenters)
            
            var count = UInt32(chinCenters.count)
            var lineWidthNormalized: Float = 15.0 / Float(imageSize.width)
            
            let center = self.computeJawCenter(jawPoints: convertedPointsLips, samplesPerSegment: 4)
            
            let filter = ChinMetalFilter()
            filter.scaleFactor = value
            filter.inputImage = self.image
            filter.lineWidth = lineWidthNormalized
            filter.point = chinCenters
            filter.center = SIMD2<Float>(Float(center.x / Float(image!.size.width)),
                                        Float(center.y / Float(image!.size.height)))
            
            if let outputImage = filter.outputImage {
                DispatchQueue.main.async {
                    self.imageView.image = outputImage
                }
            }
        } else if self.currentCategory == .eyebrow {
            /*let leftEyeBrowPoints = convertLandmarkPointsForImage(self.leftEyebrow,
             boundingBox: self.boundingBox,
             imageSize: self.image!.size)
             
             let rightEyeBrowPoints = convertLandmarkPointsForImage(self.rightEyeBrow,
             boundingBox: self.boundingBox,
             imageSize: self.image!.size)
             
             let leftCenter = eyebrowCenter(points: leftEyeBrowPoints, imageSize: image!.size)
             let rightCenter = eyebrowCenter(points: rightEyeBrowPoints, imageSize: image!.size)
             
             let leftRadius = eyebrowRadius(points: leftEyeBrowPoints, imageSize: image!.size)
             let rightRadius = eyebrowRadius(points: rightEyeBrowPoints, imageSize: image!.size)
             
             let filter = EyeBrowZoomFilter()
             filter.inputImage = self.image
             filter.leftBrowCenter = leftCenter
             filter.rightBrowCenter = rightCenter
             filter.leftBrowRadius = leftRadius
             filter.rightBrowRadius = rightRadius
             
             filter.leftScaleFactor = value
             filter.rightScaleFactor = value
             if let outputImage = filter.outputImage {
             DispatchQueue.main.async {
             self.imageView.image = outputImage
             }
             }*/
            let outputImage = faceTuneModel.applyEyeBrowFilter(
                                                               image: self.image!)
            DispatchQueue.main.async {
                self.imageView.image = outputImage
            }
            
            //debugPrint("left Right Eye Brow Points",leftEyeBrowPoints,rightEyeBrowPoints,self.image!.size)
        }
    */
    }
    
    func eyebrowCenter(points: [CGPoint], imageSize: CGSize) -> SIMD2<Float> {
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let center = CGPoint(x: sum.x / CGFloat(points.count),
                             y: sum.y / CGFloat(points.count))
        return SIMD2(Float(center.x / imageSize.width),
                     Float(center.y / imageSize.height)) // flip Y for Metal UV
    }
    
    func eyebrowRadius(points: [CGPoint], imageSize: CGSize) -> SIMD2<Float> {
        guard !points.isEmpty else { return SIMD2<Float>(0.05, 0.02) }

        let xs = points.map { $0.x }
        let ys = points.map { $0.y }

        let minX = xs.min()!
        let maxX = xs.max()!
        let minY = ys.min()!
        let maxY = ys.max()!

        let width = maxX - minX
        let height = maxY - minY

        // normalize to UV (0..1)
        return SIMD2(Float(width / imageSize.width * 0.5),  // half width
                     Float(height / imageSize.height * 0.5)) // half height
    }

    
    func computeJawCenter(jawPoints: [CGPoint], samplesPerSegment: Int = 2) -> SIMD2<Float> {
        guard jawPoints.count > 1 else { return SIMD2<Float>(0,0) }
        
        var center = SIMD2<Float>(0,0)
        var totalSamples = 0
        
        for i in 0..<jawPoints.count-1 {
            let p0 = SIMD2<Float>(Float(jawPoints[i].x), Float(jawPoints[i].y))
            let p2 = SIMD2<Float>(Float(jawPoints[i+1].x), Float(jawPoints[i+1].y))
            let p1 = (p0 + p2) * 0.5 // quadratic midpoint
            
            for s in 0..<samplesPerSegment {
                let t = Float(s) / Float(samplesPerSegment)
                let u = 1.0 - t
                let pt = u*u*p0 + 2.0*u*t*p1 + t*t*p2
                center += pt
                totalSamples += 1
            }
        }
        
        return center / Float(totalSamples)
    }
    
    
    // Smooth quad curve interpolation
    /*func computeChinCurveCenters(points: [CGPoint], imageSize: CGSize, steps: Int = 100) -> [SIMD2<Float>] {
        var centers: [SIMD2<Float>] = []
        for interp in  points{
            centers.append(SIMD2(Float(interp.x / imageSize.width), Float(interp.y / imageSize.height)))
        }
        return centers
    }*/
    
    func computeSmoothChinCurveFast(points: [CGPoint], imageSize: CGSize, steps: Int  = 2) -> [SIMD2<Float>] {
        guard points.count >= 4 else {
            return points.map { SIMD2(Float($0.x / imageSize.width), Float($0.y / imageSize.height)) }
        }

        let imgSizeF = SIMD2(Float(imageSize.width), Float(imageSize.height))
        let pts = points.map { SIMD2(Float($0.x), Float($0.y)) }
        var result: [SIMD2<Float>] = []

        for i in 1..<(pts.count - 2) {
            let p0 = pts[i - 1]
            let p1 = pts[i]
            let p2 = pts[i + 1]
            let p3 = pts[i + 2]

            for tIndex in 0..<steps {
                let t = Float(tIndex) / Float(steps)
                let t2 = t * t
                let t3 = t2 * t

                // Catmull-Rom spline in SIMD
                let part1 = p1 * 2.0
                let part2 = (p2 - p0) * t
                let part3 = (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * t2
                let part4 = (-p0 + p1 * 3.0 - p2 * 3.0 + p3) * t3

                let point = (part1 + part2 + part3 + part4) * 0.5
                result.append(point / imgSizeF)
            }
        }

        return result
    }


    
    func convertLandmarkPoints(_ points: [CGPoint], boundingBox: CGRect, imageSize: CGSize) -> [CGPoint] {
        return points.map { point in
            // normalized point inside boundingBox (normalized coords)
            let absoluteX = boundingBox.origin.x + point.x * boundingBox.width
            let absoluteY = boundingBox.origin.y + point.y * boundingBox.height
            
            // convert to pixel coords with y axis flip for UIKit coordinate system
            let pixelX = absoluteX * imageSize.width
            let pixelY = (1.0 - absoluteY) * imageSize.height
            
            return CGPoint(x: pixelX, y: pixelY)
        }
    }

    
    
    /*func draw(vertices: [Vertex], boundingBox: CGRect) {
        let newLayer = CAShapeLayer()
        newLayer.strokeColor = UIColor.blue.cgColor
        newLayer.lineWidth = 4.0
        var newVertices = vertices
        
        newVertices.remove(at: newVertices.count - 1)
        
        
        let triangles = Delaunay().triangulate(newVertices)
        
        for triangle in triangles {
            let triangleLayer = CAShapeLayer()
            triangleLayer.path = triangle.toPath()
            triangleLayer.strokeColor = UIColor.red.cgColor
            triangleLayer.lineWidth = 1.0
            triangleLayer.fillColor = UIColor.clear.cgColor
            triangleLayer.backgroundColor = UIColor.clear.cgColor
            shapeLayer.addSublayer(triangleLayer)
        }
    }*/
    
    func draw(vertices: [Vertex], boundingBox: CGRect) {
        shapeLayer.sublayers?.forEach { $0.removeFromSuperlayer() } // clear old drawings
        
        for (index, vertex) in vertices.enumerated() {
            let dotLayer = CAShapeLayer()
            let dotRadius: CGFloat = 3
            let dotPath = UIBezierPath(ovalIn: CGRect(
                x: CGFloat(vertex.x) - dotRadius,
                y: CGFloat(vertex.y) - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            
            dotLayer.path = dotPath.cgPath
            dotLayer.fillColor = UIColor.blue.cgColor
            shapeLayer.addSublayer(dotLayer)
            
            // Add index text
            let textLayer = CATextLayer()
            textLayer.string = "\(index)"
            textLayer.fontSize = 10
            textLayer.alignmentMode = .center
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.frame = CGRect(
                x: CGFloat(vertex.x) + 4,
                y: CGFloat(vertex.y) - 6,
                width: 20,
                height: 12
            )

            // Flip vertically so it’s not upside-down
            textLayer.setAffineTransform(CGAffineTransform(scaleX: 1, y: -1))
            
            shapeLayer.addSublayer(textLayer)
        }
    }
    
    func drawEye(points: [CGPoint]) {
        shapeLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        guard points.count > 2 else { return }
        
        // smooth closed curve path তৈরি করলাম
        let path = UIBezierPath(smoothPoints: points, closed: true)
        
        let eyeLayer = CAShapeLayer()
        eyeLayer.path = path.cgPath
        eyeLayer.strokeColor = UIColor.green.cgColor
        eyeLayer.fillColor = UIColor.clear.cgColor
        eyeLayer.lineWidth = 1.5
        shapeLayer.addSublayer(eyeLayer)
    }

    
    func drawChinCurve(points: [CGPoint]) {
        guard points.count == 3 else { return }
        
        shapeLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let path = UIBezierPath()
        
        // প্রথম পয়েন্ট থেকে শুরু
        path.move(to: points[0])
        
        // দ্বিতীয় পয়েন্টকে control point ধরে quadratic curve তৈরি করব তৃতীয় পয়েন্ট পর্যন্ত
        path.addQuadCurve(to: points[2], controlPoint: points[1])
        
        let chinLayer = CAShapeLayer()
        chinLayer.path = path.cgPath
        chinLayer.strokeColor = UIColor.red.cgColor
        chinLayer.fillColor = UIColor.clear.cgColor
        chinLayer.lineWidth = 2.0
        shapeLayer.addSublayer(chinLayer)
    }
    
    
    /*// 3. Eye center & radius
    func calculateEyeCenterAndRadius(points: [CGPoint], imageSize: CGSize) -> (SIMD2<Float>, Float) {
        guard !points.isEmpty else { return (SIMD2<Float>(0.5, 0.5), 0.1) }

        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let center = CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))

        let maxDist = points.map { hypot($0.x - center.x, $0.y - center.y) }.max() ?? 0

        // Metal UV coordinates (0..1)
        let uvCenter = SIMD2<Float>(
            Float(center.x / imageSize.width),
            Float(center.y / imageSize.height)
        )
        let normalizedRadius = Float(maxDist / max(imageSize.width, imageSize.height))
        return (uvCenter, normalizedRadius)
    }*/
    
    /*func calculateEyeEllipse(points: [CGPoint], imageSize: CGSize) -> (center: CGPoint, radiusX: CGFloat, radiusY: CGFloat) {
        guard !points.isEmpty else {
            return (CGPoint(x: imageSize.width/2, y: imageSize.height/2),
                    imageSize.width * 0.05,
                    imageSize.height * 0.03)
        }

        // centroid = center
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let center = CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))

        // max horizontal distance = radiusX
        let radiusX = points.map { abs($0.x - center.x) }.max() ?? 0
        // max vertical distance = radiusY
        let radiusY = points.map { abs($0.y - center.y) }.max() ?? 0

        return (center, radiusX, radiusY)
    }*/
    
    func calculateEyeEllipse(points: [CGPoint], imageSize: CGSize) -> (center: CGPoint, radiusX: CGFloat, radiusY: CGFloat) {
        guard !points.isEmpty else {
            // Fallback ellipse in the center with proportional size
            let defaultRadiusX = imageSize.width * 0.05
            let defaultRadiusY = imageSize.height * 0.03
            return (CGPoint(x: imageSize.width / 2, y: imageSize.height / 2), defaultRadiusX, defaultRadiusY)
        }
        
        // Calculate centroid
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let center = CGPoint(x: sum.x / CGFloat(points.count),
                             y: sum.y / CGFloat(points.count))
        
        // Calculate horizontal & vertical radii from the farthest points
        let radiusX = points.reduce(0) { max($0, abs($1.x - center.x)) }
        let radiusY = points.reduce(0) { max($0, abs($1.y - center.y)) }
        
        // Add a small padding to ensure effect covers the entire eye
        let paddingFactor: CGFloat = 1.2
        var clampedRadiusX = radiusX * paddingFactor
        var clampedRadiusY = radiusY * paddingFactor
        
        // Avoid too-small ellipse for very small eyes
        let minRadiusX = imageSize.width * 0.01
        let minRadiusY = imageSize.height * 0.01
        clampedRadiusX = max(clampedRadiusX, minRadiusX)
        clampedRadiusY = max(clampedRadiusY, minRadiusY)
        
        return (center, clampedRadiusX, clampedRadiusY)
    }
    
    func calculateLipEllipse(points: [CGPoint], imageSize: CGSize) -> (center: CGPoint, radiusX: CGFloat, radiusY: CGFloat) {
        guard !points.isEmpty else {
            // Fallback: center of image with small default radii
            let defaultRadiusX = imageSize.width * 0.05
            let defaultRadiusY = imageSize.height * 0.03
            return (CGPoint(x: imageSize.width/2, y: imageSize.height/2), defaultRadiusX, defaultRadiusY)
        }

        // Sort points by X to find corners
        let sortedByX = points.sorted { $0.x < $1.x }
        let leftCorner = sortedByX.first!
        let rightCorner = sortedByX.last!

        // Center is midpoint between corners
        let centerX = (leftCorner.x + rightCorner.x) / 2
        let centerY = (leftCorner.y + rightCorner.y) / 2
        let center = CGPoint(x: centerX, y: centerY)

        // Horizontal radius = distance between corners / 2, with padding
        var radiusX = hypot(rightCorner.x - leftCorner.x, 0) / 2
        // Vertical radius = max distance from center vertically
        let topMost = points.min { $0.y < $1.y }!.y
        let bottomMost = points.max { $0.y < $1.y }!.y
        var radiusY = max(abs(topMost - centerY), abs(bottomMost - centerY))

        // Add padding
        let paddingFactor: CGFloat = 1.0
        radiusX *= paddingFactor
        radiusY *= paddingFactor

        // Minimum radius safeguard
        let minRadiusX = imageSize.width * 0.01
        let minRadiusY = imageSize.height * 0.01
        radiusX = max(radiusX, minRadiusX)
        radiusY = max(radiusY, minRadiusY)

        return (center, radiusX, radiusY)
    }
    
    
    func createLipMaskAndCenter(imageSize: CGSize, points: [CGPoint], padding: CGFloat = 5) -> (mask: MTIImage, center: SIMD2<Float>, radiusXY: SIMD2<Float>) {
        
        // Compute polygon bounding center
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let center = CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
        
        // Compute radiusXY (elliptical bounds)
        let minX = points.map {$0.x}.min()! - padding
        let maxX = points.map {$0.x}.max()! + padding
        let minY = points.map {$0.y}.min()! - padding
        let maxY = points.map {$0.y}.max()! + padding
        
        let radiusX = (maxX - minX) / 2
        let radiusY = (maxY - minY) / 2
        
        // Normalize to 0..1 UV
        let centerUV = SIMD2<Float>(Float(center.x / imageSize.width),
                                    Float(center.y / imageSize.height))
        
        let radiusUV = SIMD2<Float>(Float(radiusX / imageSize.width),
                                    Float(radiusY / imageSize.height))
        
        // Draw polygon mask
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { fatalError() }
        
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.beginPath()
        ctx.addLines(between: points)
        ctx.closePath()
        ctx.fillPath()
        
        let cgImage = UIGraphicsGetImageFromCurrentImageContext()!.cgImage!
        UIGraphicsEndImageContext()
        
        let image = CIImage(cgImage: cgImage)
        
        let maskImage = MTIImage(cgImage: cgImage, options: [.SRGB: false], isOpaque: false)
        
        return (maskImage, centerUV, radiusUV)
    }
    
    func createJawMaskAndCenter(imageSize: CGSize,
                                points: [CGPoint],
                                padding: CGFloat = 5) -> (mask: MTIImage, center: SIMD2<Float>, radiusXY: SIMD2<Float>) {
        
        // ---- 1. Filter out top points (near lips) ----
        // Heuristic: keep only the lower 60% of points by Y
        let sortedByY = points.sorted { $0.y < $1.y }
        let cutoffIndex = Int(Double(sortedByY.count) * 0.4) // top 40% removed
        let jawPoints = Array(sortedByY[cutoffIndex...])
        
        // ---- 2. Compute center (polygon average) ----
        let sum = jawPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let center = CGPoint(x: sum.x / CGFloat(jawPoints.count),
                             y: sum.y / CGFloat(jawPoints.count))
        
        // ---- 3. Compute elliptical bounds ----
        let minX = jawPoints.map { $0.x }.min()! - padding
        let maxX = jawPoints.map { $0.x }.max()! + padding
        let minY = jawPoints.map { $0.y }.min()! - padding
        let maxY = jawPoints.map { $0.y }.max()! + padding
        
        let radiusX = (maxX - minX) / 2
        let radiusY = (maxY - minY) / 2
        
        // ---- 4. Normalize to UV (0..1) ----
        let centerUV = SIMD2<Float>(Float(center.x / imageSize.width),
                                    Float(center.y / imageSize.height))
        let radiusUV = SIMD2<Float>(Float(radiusX / imageSize.width),
                                    Float(radiusY / imageSize.height))
        
        // ---- 5. Draw polygon mask ----
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { fatalError() }
        
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.beginPath()
        ctx.addLines(between: jawPoints)
        ctx.closePath()
        ctx.fillPath()
        
        let cgImage = UIGraphicsGetImageFromCurrentImageContext()!.cgImage!
        UIGraphicsEndImageContext()
        
        let maskImage = MTIImage(cgImage: cgImage, options: [.SRGB: false], isOpaque: false)
        
        return (maskImage, centerUV, radiusUV)
    }

    
    func createCenterAndRadius(imageSize: CGSize, points: [CGPoint], padding: CGFloat = 5) -> (center: SIMD2<Float>, radiusXY: SIMD2<Float>) {
        
        // Compute polygon bounding center
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let center = CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
        
        // Compute radiusXY (elliptical bounds)
        let minX = points.map {$0.x}.min()! - padding
        let maxX = points.map {$0.x}.max()! + padding
        let minY = points.map {$0.y}.min()! - padding
        let maxY = points.map {$0.y}.max()! + padding
        
        let radiusX = (maxX - minX) / 2
        let radiusY = (maxY - minY) / 2
        
       // Normalize to 0..1 UV
        let centerUV = SIMD2<Float>(Float(center.x / imageSize.width),
                                    Float(center.y / imageSize.height))
        
        let radiusUV = SIMD2<Float>(Float(radiusX / imageSize.width),
                                    Float(radiusY / imageSize.height))
        
        /*
        // Draw polygon mask
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { fatalError() }
        
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.beginPath()
        ctx.addLines(between: points)
        ctx.closePath()
        ctx.fillPath()
        
        let cgImage = UIGraphicsGetImageFromCurrentImageContext()!.cgImage!
        UIGraphicsEndImageContext()
        
        let image = CIImage(cgImage: cgImage)
        
        let maskImage = MTIImage(cgImage: cgImage, options: [.SRGB: false], isOpaque: false)*/
        
        return (centerUV, radiusUV)
    }
    
    func createJawCenterAndRadius(imageSize: CGSize,
                                  points: [CGPoint],
                                  shrinkX: CGFloat = 0.45,
                                  shrinkY: CGFloat = 0.5,
                                  chinBias: CGFloat = 0.25) -> (center: SIMD2<Float>, radiusXY: SIMD2<Float>) {
        
        // bounding box
        let minX = points.map { $0.x }.min()!
        let maxX = points.map { $0.x }.max()!
        let minY = points.map { $0.y }.min()!
        let maxY = points.map { $0.y }.max()!
        
        // base center = bbox mid
        var center = CGPoint(x: (minX + maxX) / 2.0,
                             y: (minY + maxY) / 2.0)
        
        // bias center downward toward chin
        center.y = center.y + (maxY - minY) * chinBias
        
        // shrink radius
        let radiusX = (maxX - minX) / 2.0 * shrinkX
        let radiusY = (maxY - minY) / 2.0 * shrinkY
        
        // normalize UV
        let centerUV = SIMD2<Float>(Float(center.x / imageSize.width),
                                    Float(center.y / imageSize.height))
        
        let radiusUV = SIMD2<Float>(Float(radiusX / imageSize.width),
                                    Float(radiusY / imageSize.height))
        
        return (centerUV, radiusUV)
    }
    
    func createSlimJawPolygonMask(imageSize: CGSize,
                                  points: [CGPoint],
                                  shrinkFactor: CGFloat = 0.9) -> MTIImage {
        
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { fatalError() }
        
        ctx.clear(CGRect(origin: .zero, size: imageSize))
        ctx.setFillColor(UIColor.white.cgColor)
        
        // smooth quad curve
           let path = UIBezierPath()
           path.move(to: points[0])
           for i in 0..<points.count-1 {
               let current = points[i]
               let next = points[i+1]
               let mid = CGPoint(x: (current.x + next.x)/2, y: (current.y + next.y)/2)
               path.addQuadCurve(to: next, controlPoint: mid)
           }
           
           path.lineWidth = 100
           path.lineCapStyle = .round
           ctx.setLineWidth(15)
            ctx.setLineCap(.round)
           ctx.setStrokeColor(UIColor.blue.cgColor)
           ctx.addPath(path.cgPath)
           ctx.strokePath()
        
        let cgImage = UIGraphicsGetImageFromCurrentImageContext()!.cgImage!
           UIGraphicsEndImageContext()
           
        let image = CIImage(cgImage: cgImage)
        
        
        
        return MTIImage(cgImage: cgImage,
                        options: [.SRGB: false],
                        isOpaque: false)
    }


}




extension UIBezierPath {
    /// Creates a smooth closed curve through the given points using Catmull-Rom spline.
    convenience init(smoothPoints points: [CGPoint], closed: Bool = true) {
        self.init()
        guard points.count > 1 else { return }
        
        let n = points.count
        
        func point(at index: Int) -> CGPoint {
            if index < 0 {
                return closed ? points[(index + n) % n] : points[0]
            } else if index >= n {
                return closed ? points[index % n] : points[n - 1]
            } else {
                return points[index]
            }
        }
        
        self.move(to: points[0])
        
        for i in 0..<n {
            let p0 = point(at: i - 1)
            let p1 = point(at: i)
            let p2 = point(at: i + 1)
            let p3 = point(at: i + 2)
            
            // Calculate control points for cubic Bezier segment
            let controlPoint1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6.0,
                y: p1.y + (p2.y - p0.y) / 6.0
            )
            let controlPoint2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6.0,
                y: p2.y - (p3.y - p1.y) / 6.0
            )
            
            self.addCurve(to: p2, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        }
        
        if closed {
            self.close()
        }
    }
    
   
}


//MARK: - UIGestureRecognizerDelegate
extension FaceTuneVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true // allow pinch + rotate + pan together
    }
}

extension FaceTuneVC {
    func normalizePoints(_ pts: [CGPoint], imageSize: CGSize) -> [SIMD2<Float>] {
        return pts.map { p in
            SIMD2(Float(p.x / imageSize.width), Float(p.y / imageSize.height))
        }
    }

    func catmullRomToBezier(points: [SIMD2<Float>]) -> [SIMD2<Float>] {
        var out: [SIMD2<Float>] = []
        let n = points.count
        if n < 4 { return out } // need at least 4 for Catmull-Rom

        for i in 0..<(n-3) {
            let p0 = points[i]
            let p1 = points[i+1]
            let p2 = points[i+2]
            let p3 = points[i+3]

            let b0 = p1
            let b1 = (-p0 + 6*p1 + p2) / 6.0
            let b2 = (p1 + 6*p2 - p3) / 6.0
            let b3 = p2

            out.append(b0); out.append(b1); out.append(b2); out.append(b3)
        }
        return out
    }
    
    func prepareEyebrowCurves(left: [CGPoint],
                              right: [CGPoint],
                              imageSize: CGSize) -> ([SIMD2<Float>], UInt32, SIMD2<Float>) {
        // normalize points
        let leftNorm  = normalizePoints(left, imageSize: imageSize)
        let rightNorm = normalizePoints(right, imageSize: imageSize)

        // convert to bezier control points
        let leftBezier  = catmullRomToBezier(points: leftNorm)
        let rightBezier = catmullRomToBezier(points: rightNorm)

        // combine both eyebrows
        let allBezier = leftBezier + rightBezier

        // segment count (4 control points per segment)
        let segCount = UInt32(allBezier.count / 4)

        // global center = midpoint between left+right centroids
        let leftCenter  = leftNorm.reduce(SIMD2<Float>(0,0), +) / Float(leftNorm.count)
        let rightCenter = rightNorm.reduce(SIMD2<Float>(0,0), +) / Float(rightNorm.count)
        let globalCenter = (leftCenter + rightCenter) * 0.5

        return (allBezier, segCount, globalCenter)
    }

}
