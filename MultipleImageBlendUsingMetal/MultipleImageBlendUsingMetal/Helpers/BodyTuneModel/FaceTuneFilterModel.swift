//
//  FaceTuneModel.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 24/8/25.
//

import UIKit
import MetalPetal

enum FilteryType: String, CaseIterable {
    case facialProportion = "Facial Proportion"
    case eyes = "Eyes"
    case nose = "Nose"
    case lips = "Lips"
    case cheeks = "Cheeks"
    case eyeBrow = "Eye Brow"
    case eyeLashesh = "Eye Lashesh"
    case eyeContrast = "Eye Contrast"
    case EyeBrowsConstrast = "Eye Brows"
    case brighterLips = "Brighter Lips"
    case teethWhitening = "Teeth Whitening"
    case shadow = "Shadow"
    case neeckShadow = "Neck Shadow"
}


struct EyeFilterModel {
    var rightEyePoints: [CGPoint] = []
    var leftEyePoints: [CGPoint] = []
    var leftEyeCenter: CGPoint = .zero
    var rightEyeCenter: CGPoint = .zero
    var leftEyeRadius: CGPoint = .zero
    var rightEyeRadius: CGPoint = .zero
    var scaleFactor: Float = 0
}

struct EyeBrowFilterModel {
    var leftEyeBrowPoints: [CGPoint] = []
    var rightEyeBrowPoints: [CGPoint] = []
    var leftEyeBrowcenter: SIMD2<Float> = .zero
    var rightEyeBrowcenter: SIMD2<Float> = .zero
    var leftEyeBrowRadius: SIMD2<Float> = .zero
    var rightEyeBrowRadius: SIMD2<Float> = .zero
    var scaleFactor: Float = 0
}

struct LipsFilterModel {
    var outerLipsPoints: [CGPoint] = []
    var outerLipscenter: CGPoint = .zero
    var lipsRadius: CGPoint = .zero
    var scaleFactor: CGFloat = 0
}

struct NoseFilterModel {
    var nosePoints: [CGPoint] = []
    var noseCenter: SIMD2<Float> = .zero
    var noseRadius: SIMD2<Float> = .zero
    var scaleFactor: Float = 0
    var nosePointsFloat: [SIMD2<Float>] = []
}

struct JawFilterModel {
    var jawPoints: [CGPoint] = []
    var smoothCurveFast: [SIMD2<Float>] = []
    var jawCenter: SIMD2<Float> = .zero
    var scaleFactor: CGFloat = 0
}

struct NeckShadowFilterModel {
    var jawPoints: [SIMD2<Float>] = []
    var scaleFactor: CGFloat = 0
}

struct LipsBrightenFilterModel {
    var outerPoints: [SIMD2<Float>] = []
    var innerPoints: [SIMD2<Float>] = []
    var scaleFactor: CGFloat = 0
}

struct EyeBrowBrightenFilterModel {
    var leftPoints: [SIMD2<Float>] = []
    var rightPoints: [SIMD2<Float>] = []
    var scaleFactor: CGFloat = 0
}

struct FacePropotionModel {
    var faceRect: CGRect = .zero
    var faceCenter: SIMD2<Float> = .zero
    var faceRadius: SIMD2<Float> = .zero
    var scaleFactor: CGFloat = 0
    var rotation: Float = 0
    var smoothCurveFast: [SIMD2<Float>] = []
}

struct FaceShadowModel {
    var faceRect: CGRect = .zero
    var faceCenter: SIMD2<Float> = .zero
    var faceRadius: SIMD2<Float> = .zero
    var scaleFactor: CGFloat = 0
    var rotation: Float = 0
    var smoothCurveFast: [SIMD2<Float>] = []
}

struct EyelashFilterModel {
    var scaleFactor: Float = 0
    var curveFast: [SIMD2<Float>] = []
}

struct EyeBrightnessFilterModel {
    var scaleFactor: Float = 0
    var leftEyePoints: [SIMD2<Float>] = []
    var leftIrisPoints: [SIMD2<Float>] = []
    var rightEyePoints: [SIMD2<Float>] = []
    var rightIrisPoints: [SIMD2<Float>] = []
}

struct TeethWhiteningFilterModel {
    var innerLipsPoints: [CGPoint] = []
    var scaleFactor: Float = 0.0
    var outerPoints: [SIMD2<Float>] = []
    var innerPoints: [SIMD2<Float>] = []
    var innerLipsCenter: SIMD2<Float> = .zero
    var innerLipsRadius: SIMD2<Float> = .zero
    var maskImage: MTIImage? = nil
}

struct FaceTuneFilterModel {
    var boundingBox: CGRect = .zero
    var eyeFilterModel: EyeFilterModel = .init()
    var eyeBrowFilterModel: EyeBrowFilterModel = .init()
    var noseFilterModel: NoseFilterModel = .init()
    var lipsFilterModel: LipsFilterModel = .init()
    var jawFilterModel: JawFilterModel = .init()
    var faceProportionFilter: FacePropotionModel = .init()
    var eyelashFilterModel: EyelashFilterModel = .init()
    var eyeBrightnessFilterModel: EyeBrightnessFilterModel = .init()
    var teethWhiteningModel: TeethWhiteningFilterModel = .init()
    var lipsBrighterModel: LipsBrightenFilterModel = .init()
    var imageSize: CGSize = .zero
    let allCat = FilteryType.allCases
    
    mutating func applyAllFilter(scaleValue : Float,
                                 image: MTIImage,
                                 filterName: String) -> MTIImage? {
        guard let category = FilteryType(rawValue: filterName) else {
            return image
        }
        var outputImage = image
        for filterCategory in allCat {
            switch filterCategory {
            case .eyes:
                if category == filterCategory {
                    eyeFilterModel.scaleFactor = scaleValue
                }
                if eyeFilterModel.scaleFactor != 0.0 {
                    outputImage = self.applyEyeFilter(image: outputImage)
                }
                
            case .eyeBrow:
                if category == filterCategory {
                    eyeBrowFilterModel.scaleFactor = scaleValue
                }
                if eyeBrowFilterModel.scaleFactor != 0.0 {
                    outputImage = self.applyEyeBrowFilter(image: outputImage)
                }
            case .nose:
                if category == filterCategory {
                    noseFilterModel.scaleFactor = scaleValue
                }
                if noseFilterModel.scaleFactor != 0.0 {
                    outputImage = self.applynoseFilter(image: outputImage)
                }
                break
            case .lips:
                if category == filterCategory {
                    lipsFilterModel.scaleFactor = CGFloat(scaleValue)
                }
                if lipsFilterModel.scaleFactor != 0.0 {
                    outputImage = self.applyLipsFilter(image: outputImage)
                }
                break
            case .cheeks:
                if category == filterCategory {
                    jawFilterModel.scaleFactor = CGFloat(scaleValue)
                }
                if jawFilterModel.scaleFactor != 0.0 {
                    outputImage = self.applyJawFilter(image: outputImage)
                }
                break
            case .facialProportion:
                if category == filterCategory {
                    faceProportionFilter.scaleFactor = CGFloat(scaleValue)
                }
                if faceProportionFilter.scaleFactor != 0.0 {
                    outputImage = self.applyFaceProportionFilter(image: outputImage)
                }
                break
            case .eyeLashesh:
                if category == filterCategory {
                    eyelashFilterModel.scaleFactor = scaleValue
                }
                if eyelashFilterModel.scaleFactor != 0.0 {
                    outputImage = self.applyEyelashesFilter(image: outputImage)
                }
            case .eyeContrast:
                if category == filterCategory {
                    eyeBrightnessFilterModel.scaleFactor = scaleValue
                }
                if eyeBrightnessFilterModel.scaleFactor != 0.0 {
                    outputImage = self.applyEyeBrightnessFilter(image: outputImage)
                }
            case .teethWhitening: 
                if category == filterCategory {
                    teethWhiteningModel.scaleFactor = scaleValue
                }
                if teethWhiteningModel.scaleFactor != 0.0 {
                    outputImage = self.applyTeethWhiteningFilter(image: outputImage)
                }
            case .brighterLips:
                if category == filterCategory {
                    lipsBrighterModel.scaleFactor = CGFloat(scaleValue)
                }
                if lipsBrighterModel.scaleFactor != 0.0 {
                    outputImage = self.applyLipsBrighterFilter(inputImage: outputImage)
                }
            
            default: break
            }
        }
        return outputImage
    }
}

//MARK: - FaceTuneFilterModel
extension FaceTuneFilterModel {
    mutating func updateLipsBritherFilter(innerLipsPoint: [CGPoint], outerLipsPoint: [CGPoint]) {
        let convertedPointsInnerLips = convertLandmarkPointsForImage(innerLipsPoint,
                                                                     boundingBox: self.boundingBox,
                                                                     imageSize: self.imageSize)
        
        let convertedOuterLips = convertLandmarkPointsForImage(outerLipsPoint,
                                                               boundingBox: self.boundingBox,
                                                               imageSize: self.imageSize)
        
        let normalizedPoints1 = convertedPointsInnerLips.map { point in
            SIMD2<Float>(Float(point.x) / Float(imageSize.width),
                         Float(point.y) / Float(imageSize.height))
        }
        
        
        let normalizedPoints2 = convertedOuterLips.map { point in
            SIMD2<Float>(Float(point.x) / Float(imageSize.width),
                         Float(point.y) / Float(imageSize.height))
        }
        
        lipsBrighterModel.innerPoints = normalizedPoints1
        lipsBrighterModel.outerPoints = normalizedPoints2
        
    }
    
    mutating func applyLipsBrighterFilter(inputImage: MTIImage) -> MTIImage {
        let filter = LipsBrightenFilter()
        filter.inputImage = inputImage.unpremultiplyingAlpha()
        filter.innerLipsPoints = lipsBrighterModel.innerPoints
        filter.outerLipsPoints = lipsBrighterModel.outerPoints
        filter.outerBrightness = Float(lipsBrighterModel.scaleFactor)
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return inputImage
    }
}

extension FaceTuneFilterModel {
    mutating func updateTeethWhiteningFilter(innerLipsPoint: [CGPoint], size: CGSize) {
        self.imageSize = size
        self.teethWhiteningModel.innerLipsPoints = innerLipsPoint
        self.teethWhiteningModel.scaleFactor = 0.0
        /*let convertedPointsLips = convertLandmarkPointsForImage(innerLipsPoint,
                                                                boundingBox: self.boundingBox,
                                                                imageSize: self.imageSize)*/
        
        
        //let (lefteyeCenter, lefteyeRadiusX, lefteyeRadiusY) = calculateEyeEllipse(points: convertedPointsLips,
                                                                                 // imageSize: self.imageSize)
        
        let (image,center,radius) = createInnerLipsMask1(points: innerLipsPoint, imageSize: self.imageSize)!
        
        teethWhiteningModel.innerLipsCenter = SIMD2<Float>(Float(center.x / self.imageSize.width),
                                            Float(center.y / self.imageSize.height))
        
        teethWhiteningModel.innerLipsRadius = SIMD2<Float>(Float(radius.width / self.imageSize.width),
                                                           Float(radius.height / self.imageSize.height))
        //teethWhiteningModel.maskImage = self.createInnerLipsMask(points: innerLipsPoint, imageSize: self.imageSize)
        teethWhiteningModel.maskImage = image

    }
    
    mutating func applyTeethWhiteningFilter(image: MTIImage) -> MTIImage {
       
        let filter = TeethWhiteningMetalFilter()
        filter.inputImage = image.unpremultiplyingAlpha()
        filter.maskImage = teethWhiteningModel.maskImage
        filter.innerLipsCenter = teethWhiteningModel.innerLipsCenter
        filter.innerLipsRadius = teethWhiteningModel.innerLipsRadius
        filter.effectFactor = teethWhiteningModel.scaleFactor
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
    
}

//MARK: - EyeContrastFilter
extension FaceTuneFilterModel {
    mutating func applyEyeBrightnessFilter(image: MTIImage) -> MTIImage {
       
        let filter = EyeContrastFilter()
        filter.inputImage = image
        filter.leftEyeCenter = SIMD2<Float>(Float(eyeFilterModel.leftEyeCenter.x / self.imageSize.width),
                                            Float(eyeFilterModel.leftEyeCenter.y / self.imageSize.height))
        
        filter.leftEyeRadius = SIMD2<Float>(Float(eyeFilterModel.leftEyeRadius.x / self.imageSize.width),
                                              Float(eyeFilterModel.leftEyeRadius.y / self.imageSize.height))
        
        filter.rightEyeCenter = SIMD2<Float>(Float(eyeFilterModel.rightEyeCenter.x / self.imageSize.width),
                                             Float(eyeFilterModel.rightEyeCenter.y /  self.imageSize.height))
        
        filter.rightEyeRadius = SIMD2<Float>(Float(eyeFilterModel.rightEyeRadius.x /  self.imageSize.width),
                                               Float(eyeFilterModel.rightEyeRadius.y /  self.imageSize.height))
        filter.effectFactor = Float(self.eyeBrightnessFilterModel.scaleFactor)
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
}

//MARK: - Eyelashes Filter From Look
extension FaceTuneFilterModel {
    mutating func applyEyelashesFilter(image: MTIImage) -> MTIImage {
       
        let filter = EyelashEffectFilter()
        filter.inputImage = image
        filter.leftEyeCenter = SIMD2<Float>(Float(eyeFilterModel.leftEyeCenter.x / self.imageSize.width),
                                            Float(eyeFilterModel.leftEyeCenter.y / self.imageSize.height))
        
        filter.leftEyeRadius = SIMD2<Float>(Float(eyeFilterModel.leftEyeRadius.x / self.imageSize.width),
                                              Float(eyeFilterModel.leftEyeRadius.y / self.imageSize.height))
        
        filter.rightEyeCenter = SIMD2<Float>(Float(eyeFilterModel.rightEyeCenter.x / self.imageSize.width),
                                             Float(eyeFilterModel.rightEyeCenter.y /  self.imageSize.height))
        
        filter.rightEyeRadius = SIMD2<Float>(Float(eyeFilterModel.rightEyeRadius.x /  self.imageSize.width),
                                               Float(eyeFilterModel.rightEyeRadius.y /  self.imageSize.height))
        filter.effectFactor = Float(self.eyelashFilterModel.scaleFactor)
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
}

//MARK: - FaceproportionFilter
extension FaceTuneFilterModel {
    mutating func updateFaceProportionFilter() {
        self.faceProportionFilter.scaleFactor = 0.0
        let cx = (boundingBox.origin.x + boundingBox.size.width / 2)
        let cy = (boundingBox.origin.y + boundingBox.size.height / 2)

        let faceCenter = SIMD2<Float>(
            Float(cx / imageSize.width),
            Float(cy / imageSize.height) // flip Y
        )

        let faceRadius = SIMD2<Float>(
            Float((boundingBox.size.width / 2) / imageSize.width),
            Float((boundingBox.size.height / 2) / imageSize.height)
        )
        self.faceProportionFilter.faceCenter = faceCenter
        self.faceProportionFilter.faceRadius = faceRadius
    }
    
    mutating func applyFaceProportionFilter(image: MTIImage) -> MTIImage {
       
        let filter = FacePFilter()
        
        filter.faceScaleFactor = Float(self.faceProportionFilter.scaleFactor)
        filter.inputImage = image
        filter.faceRectCenter = self.faceProportionFilter.faceCenter
        filter.faceRectRadius = self.faceProportionFilter.faceRadius
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
}

//MARK: - Jaw Filter
extension FaceTuneFilterModel {
    mutating func updateJawFilter(jawPoints: [CGPoint]) {
        self.jawFilterModel.jawPoints = jawPoints
        self.jawFilterModel.scaleFactor = 0.0
        let convertedPointsLips = convertLandmarkPointsForImage( self.jawFilterModel.jawPoints,
                                                                 boundingBox: self.boundingBox,
                                                                 imageSize: self.imageSize)
        
        
        let chinCenters = computeSmoothChinCurveFast(points: convertedPointsLips, imageSize: imageSize)
        
        //var count = UInt32(chinCenters.count)
        //var lineWidthNormalized: Float = 15.0 / Float(imageSize.width)
        
        let center = self.computeJawCenter(jawPoints: convertedPointsLips, samplesPerSegment: 4)
        self.jawFilterModel.jawCenter = center
        self.jawFilterModel.smoothCurveFast = chinCenters
    }
    
    mutating func applyJawFilter(image: MTIImage) -> MTIImage {
        
        let lineWidthNormalized: Float = 15.0 / Float(imageSize.width)
       
        let filter = ChinMetalFilter()
        
        filter.scaleFactor = Float(self.jawFilterModel.scaleFactor)
        filter.inputImage = image
        filter.lineWidth = lineWidthNormalized
        filter.point = self.jawFilterModel.smoothCurveFast
        filter.center = SIMD2<Float>(Float(self.jawFilterModel.jawCenter.x / Float(self.imageSize.width)),
                                     Float(self.jawFilterModel.jawCenter.y / Float(self.imageSize.height)))
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
}


//MARK: - Lips Filter
extension FaceTuneFilterModel {
    mutating func updateLipsFilter(lipsPoints: [CGPoint]) {
        self.lipsFilterModel.outerLipsPoints = lipsPoints
        self.lipsFilterModel.scaleFactor = 0.0
        let convertedPointsLips = convertLandmarkPointsForImage(lipsFilterModel.outerLipsPoints,
                                                                boundingBox: self.boundingBox,
                                                                imageSize: self.imageSize)
        
        let (outerLipsCenter, outerLipsRadiusX, outerLipsRadiusY) = calculateLipEllipse(points: convertedPointsLips,
                                                                      imageSize:self.imageSize)
        
        self.lipsFilterModel.outerLipscenter = outerLipsCenter
        self.lipsFilterModel.lipsRadius.x = outerLipsRadiusX
        self.lipsFilterModel.lipsRadius.y = outerLipsRadiusY
    }
    
    mutating func applyLipsFilter(image: MTIImage) -> MTIImage {
        
        let lipsFilter = LipsMetalFilter()
        lipsFilter.inputImage = image
        lipsFilter.lipCenter = SIMD2<Float>(Float(self.lipsFilterModel.outerLipscenter.x / image.size.width),
                                            Float(self.lipsFilterModel.outerLipscenter.y / image.size.height))
        lipsFilter.lipRadiusXY =  SIMD2<Float>(Float(self.lipsFilterModel.lipsRadius.x / image.size.width),
                                               Float(self.lipsFilterModel.lipsRadius.y / image.size.height))
        
        lipsFilter.lipScaleFactor = Float(self.lipsFilterModel.scaleFactor) // positive = enlarge, negative = shrink*/
        if let outputImage = lipsFilter.outputImage {
            return outputImage
        }
        
        return image
    }
}

//MARK: - Update Nose Filter
extension FaceTuneFilterModel {
    mutating func updateNoseFilter(nosePoints: [CGPoint]) {
        self.noseFilterModel.nosePoints = nosePoints
        self.noseFilterModel.scaleFactor = 0.0
        let convertedPointsLips = convertLandmarkPointsForImage(noseFilterModel.nosePoints,
                                                                boundingBox: self.boundingBox,
                                                                imageSize: self.imageSize)
        
        let (noseCenterUV, noseRadiusXY) = self.createCenterAndRadius(imageSize: self.imageSize,
                                                                      points: convertedPointsLips)
        
        self.noseFilterModel.noseCenter = noseCenterUV
        self.noseFilterModel.noseRadius = noseRadiusXY
    }
    
    mutating func applynoseFilter(image: MTIImage) -> MTIImage {
        
        let lipsFilter = NoseMetalFilter()
        lipsFilter.inputImage = image
        lipsFilter.noseCenter = noseFilterModel.noseCenter
        lipsFilter.noseRadiusXY = noseFilterModel.noseRadius
        lipsFilter.noseScaleFactor = noseFilterModel.scaleFactor
        
        if let output = lipsFilter.outputImage {
            return output
        }
        return image
    }
}

//Eye Brow Filter Functionality
extension FaceTuneFilterModel {
    mutating func updateEyeBrowFilter(leftEyeBrowPoints: [CGPoint],
                                      rightEyeBrowPoints: [CGPoint]) {
        
        self.eyeBrowFilterModel.leftEyeBrowPoints = leftEyeBrowPoints
        self.eyeBrowFilterModel.rightEyeBrowPoints = rightEyeBrowPoints
        self.eyeBrowFilterModel.scaleFactor = 0.0
        
        let leftEyeBrowPoints = convertLandmarkPointsForImage(self.eyeBrowFilterModel.leftEyeBrowPoints ,
                                                              boundingBox: self.boundingBox,
                                                              imageSize: self.imageSize)
       
        let rightEyeBrowPoints = convertLandmarkPointsForImage( self.eyeBrowFilterModel.rightEyeBrowPoints,
                                                               boundingBox: self.boundingBox,
                                                               imageSize: self.imageSize)
        
        let leftCenter = eyebrowCenter(points: leftEyeBrowPoints, imageSize: self.imageSize)
        let rightCenter = eyebrowCenter(points: rightEyeBrowPoints, imageSize: self.imageSize)

        let leftRadius = eyebrowRadius(points: leftEyeBrowPoints, imageSize: self.imageSize)
        let rightRadius = eyebrowRadius(points: rightEyeBrowPoints, imageSize:self.imageSize)
        
        self.eyeBrowFilterModel.leftEyeBrowcenter = leftCenter
        self.eyeBrowFilterModel.rightEyeBrowcenter = rightCenter
        self.eyeBrowFilterModel.leftEyeBrowRadius = leftRadius
        self.eyeBrowFilterModel.rightEyeBrowRadius = rightRadius
    }
    
    mutating func applyEyeBrowFilter(image: MTIImage) -> MTIImage {
        let filter = EyeBrowZoomFilter()
        filter.inputImage = image
        filter.leftBrowCenter = eyeBrowFilterModel.leftEyeBrowcenter
        filter.rightBrowCenter = eyeBrowFilterModel.rightEyeBrowcenter
        filter.leftBrowRadius = eyeBrowFilterModel.leftEyeBrowRadius
        filter.rightBrowRadius = eyeBrowFilterModel.rightEyeBrowRadius
        
        filter.leftScaleFactor =  eyeBrowFilterModel.scaleFactor
        filter.rightScaleFactor =  eyeBrowFilterModel.scaleFactor
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
}

//Eye Filter Model
extension FaceTuneFilterModel {
    mutating func updateEyeFilterModel(leftpoints: [CGPoint],
                                       rightEyePoints: [CGPoint]) -> Void {
       
        eyeFilterModel.leftEyePoints = leftpoints
        eyeFilterModel.rightEyePoints = rightEyePoints
        eyeFilterModel.scaleFactor = 0.0
        
        let convertedPointsleftEye = convertLandmarkPointsForImage(self.eyeFilterModel.leftEyePoints,
                                                                   boundingBox: self.boundingBox,
                                                                   imageSize: self.imageSize)
        
        let convertedPointsRightEye = convertLandmarkPointsForImage(self.eyeFilterModel.rightEyePoints,
                                                                    boundingBox: self.boundingBox,
                                                                    imageSize: self.imageSize)
        
        debugPrint("Left eye and right eye points: \(convertedPointsleftEye) \(convertedPointsRightEye)")
        
        let (lefteyeCenter, lefteyeRadiusX, lefteyeRadiusY) = calculateEyeEllipse(points: convertedPointsleftEye,
                                                                                  imageSize: self.imageSize)
        
        let (righteyeCenter, righteyeRadiusX, righteyeRadiusY) = calculateEyeEllipse(points: convertedPointsRightEye,
                                                                                     imageSize: self.imageSize)
        
        
        eyeFilterModel.leftEyeCenter = lefteyeCenter
        eyeFilterModel.leftEyeRadius.x = lefteyeRadiusX
        eyeFilterModel.leftEyeRadius.y = lefteyeRadiusY
        
        eyeFilterModel.rightEyeCenter = righteyeCenter
        eyeFilterModel.rightEyeRadius.x = righteyeRadiusX
        eyeFilterModel.rightEyeRadius.y = righteyeRadiusY
    }
    
    mutating func applyEyeFilter(image: MTIImage) -> MTIImage {
        let filter = EyeMetalFilter()
        
        filter.leftEyeCenter = SIMD2<Float>(Float(eyeFilterModel.leftEyeCenter.x / self.imageSize.width),
                                            Float(eyeFilterModel.leftEyeCenter.y / self.imageSize.height))
        
        filter.leftEyeRadiusXY = SIMD2<Float>(Float(eyeFilterModel.leftEyeRadius.x / self.imageSize.width),
                                              Float(eyeFilterModel.leftEyeRadius.y / self.imageSize.height))
        
        filter.rightEyeCenter = SIMD2<Float>(Float(eyeFilterModel.rightEyeCenter.x / self.imageSize.width),
                                             Float(eyeFilterModel.rightEyeCenter.y /  self.imageSize.height))
        
        filter.rightEyeRadiusXY = SIMD2<Float>(Float(eyeFilterModel.rightEyeRadius.x /  self.imageSize.width),
                                               Float(eyeFilterModel.leftEyeRadius.y /  self.imageSize.height))
        filter.leftScaleFactor = eyeFilterModel.scaleFactor
        filter.rightScaleFactor = eyeFilterModel.scaleFactor
        
        filter.inputImage = image
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
}


extension FaceTuneFilterModel {
    func convertLandmarkPointsForImage(_ points: [CGPoint],
                                       boundingBox: CGRect,
                                       imageSize: CGSize) -> [CGPoint] {
        return points.map { point in
            let x = boundingBox.origin.x + point.x * boundingBox.width
            let y = boundingBox.origin.y + (1.0 - point.y) * boundingBox.height // flip y inside bounding box
            return CGPoint(x: x, y: y)
        }
    }
    
    func calculateEyeEllipse(points: [CGPoint],
                             imageSize: CGSize) -> (center: CGPoint,
                                                    radiusX: CGFloat,
                                                    radiusY: CGFloat) {
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
    
    func eyebrowCenter(points: [CGPoint],
                       imageSize: CGSize) -> SIMD2<Float> {
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let center = CGPoint(x: sum.x / CGFloat(points.count),
                             y: sum.y / CGFloat(points.count))
        return SIMD2(Float(center.x / imageSize.width),
                     Float(center.y / imageSize.height)) // flip Y for Metal UV
    }
    
    func eyebrowRadius(points: [CGPoint],
                       imageSize: CGSize) -> SIMD2<Float> {
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
    
    /*func createInnerLipsMask(points: [CGPoint], imageSize: CGSize) -> MTIImage? {
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // Black background
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fill(CGRect(origin: .zero, size: imageSize))

        // White polygon (mask = 1)
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.beginPath()
        ctx.addLines(between: points)
        ctx.closePath()
        ctx.fillPath()

        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
        UIGraphicsEndImageContext()
        
        let image = CIImage(cgImage: cgImage)

        return MTIImage(cgImage: cgImage, options: [.SRGB:false], isOpaque:false).unpremultiplyingAlpha()
    }*/
    
    /*func createInnerLipsMask(points: [CGPoint], imageSize: CGSize) -> MTIImage? {
        guard points.count > 2 else { return nil }

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // Black background
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fill(CGRect(origin: .zero, size: imageSize))

        // Smooth path
        let path = UIBezierPath()
        path.move(to: points[0])
        
        // Using Catmull-Rom / smooth cubic curve approximation
        for i in 1..<points.count {
            let prev = points[i-1]
            let current = points[i]
            let midPoint = CGPoint(x: (prev.x + current.x)/2, y: (prev.y + current.y)/2)
            path.addQuadCurve(to: midPoint, controlPoint: prev)
        }
        
        // Connect last point back to first to close
        let last = points.last!
        path.addQuadCurve(to: points[0], controlPoint: last)
        
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        
        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
        UIGraphicsEndImageContext()
        
        let image = CIImage(cgImage: cgImage)

        return MTIImage(cgImage: cgImage, options: [.SRGB:false], isOpaque:false).unpremultiplyingAlpha()
    }*/
    
    /*func createInnerLipsMask(points: [CGPoint], imageSize: CGSize) -> MTIImage? {
        guard points.count > 2 else { return nil }

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // Black background
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fill(CGRect(origin: .zero, size: imageSize))

        let path = UIBezierPath()
        
        // Duplicate first and last points for proper Catmull-Rom
        let pts = [points.last!] + points + [points.first!]
        
        path.move(to: points[0])
        
        for i in 1..<pts.count-2 {
            let p0 = pts[i-1]
            let p1 = pts[i]
            let p2 = pts[i+1]
            let p3 = pts[i+2]
            
            // Catmull-Rom to cubic Bezier conversion
            let tension: CGFloat = 0.5 // adjust to make curves tighter/slimmer
            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension / 6,
                y: p1.y + (p2.y - p0.y) * tension / 6
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension / 6,
                y: p2.y - (p3.y - p1.y) * tension / 6
            )
            
            path.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
        }
        
        path.close()
        
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        
        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
        UIGraphicsEndImageContext()

        return MTIImage(cgImage: cgImage, options: [.SRGB:false], isOpaque:false).unpremultiplyingAlpha()
    }*/
    
    /*func createInnerLipsMask(
        points: [CGPoint],
        imageSize: CGSize,
        padding: CGFloat = 0,
        shrinkFactor: CGFloat = 1.0,
        verticalOffset: CGFloat = 0
    ) -> MTIImage? {
        guard points.count > 2 else { return nil }

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // Transparent background
        ctx.setFillColor(UIColor.clear.cgColor)
        ctx.fill(CGRect(origin: .zero, size: imageSize))

        // Compute center
        let center = CGPoint(
            x: points.map { $0.x }.reduce(0, +) / CGFloat(points.count),
            y: points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
        )

        // Adjust points
        let adjustedPoints = points.map { point -> CGPoint in
            let dx = point.x - center.x
            let dy = point.y - center.y
            return CGPoint(
                x: center.x + dx * shrinkFactor + padding,
                y: center.y + dy * shrinkFactor + verticalOffset + padding
            )
        }

        let path = UIBezierPath()
        let count = adjustedPoints.count

        // Smoothed cubic Bezier
        let tension: CGFloat = 0.5
        for i in 0..<count {
            let p0 = adjustedPoints[(i - 1 + count) % count]
            let p1 = adjustedPoints[i]
            let p2 = adjustedPoints[(i + 1) % count]
            let p3 = adjustedPoints[(i + 2) % count]

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension / 6,
                y: p1.y + (p2.y - p0.y) * tension / 6
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension / 6,
                y: p2.y - (p3.y - p1.y) * tension / 6
            )

            if i == 0 { path.move(to: p1) }
            path.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
        }

        path.close()

        // Fill lips area with white (opaque)
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()

        // Create MTIImage with alpha
        return MTIImage(cgImage: cgImage, options: [.SRGB: false], isOpaque: false)
            .unpremultiplyingAlpha()
    }
    */
    /*func createInnerLipsMask(
        points: [CGPoint],
        imageSize: CGSize,
        padding: CGFloat = 0,
        shrinkFactor: CGFloat = 1.0,
        verticalOffset: CGFloat = 0,
        boundaryWidth: CGFloat = 3
    ) -> MTIImage? {
        guard points.count > 2 else { return nil }

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // Transparent background
        ctx.setFillColor(UIColor.clear.cgColor)
        ctx.fill(CGRect(origin: .zero, size: imageSize))

        // Compute center
        let center = CGPoint(
            x: points.map { $0.x }.reduce(0, +) / CGFloat(points.count),
            y: points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
        )

        // Adjust points
        let adjustedPoints = points.map { point -> CGPoint in
            let dx = point.x - center.x
            let dy = point.y - center.y
            return CGPoint(
                x: center.x + dx * shrinkFactor + padding,
                y: center.y + dy * shrinkFactor + verticalOffset + padding
            )
        }

        // Create smoothed path
        let path = UIBezierPath()
        let count = adjustedPoints.count
        let tension: CGFloat = 0.5
        for i in 0..<count {
            let p0 = adjustedPoints[(i - 1 + count) % count]
            let p1 = adjustedPoints[i]
            let p2 = adjustedPoints[(i + 1) % count]
            let p3 = adjustedPoints[(i + 2) % count]

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension / 6,
                y: p1.y + (p2.y - p0.y) * tension / 6
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension / 6,
                y: p2.y - (p3.y - p1.y) * tension / 6
            )

            if i == 0 { path.move(to: p1) }
            path.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
        }
        path.close()

        // Draw boundary (soft edge)
        ctx.setLineWidth(boundaryWidth)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.05).cgColor)
        ctx.addPath(path.cgPath)
        ctx.strokePath()

        // Fill lips area with solid white
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        // Extract CGImage
        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()
        
        let fImage = CIImage(cgImage: cgImage)

        return MTIImage(cgImage: cgImage, options: [.SRGB: false], isOpaque: false)
            .unpremultiplyingAlpha()
    }

*/
    
    func createInnerLipsMask(
        points: [CGPoint],
        imageSize: CGSize,
        padding: CGFloat = 0,
        shrinkFactor: CGFloat = 1.0,
        verticalOffset: CGFloat = 0,
        boundaryWidth: CGFloat = 3,
        cornerRadius: CGFloat = 6.0
    ) -> MTIImage? {
        guard points.count > 2 else { return nil }

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // Transparent background
        ctx.setFillColor(UIColor.clear.cgColor)
        ctx.fill(CGRect(origin: .zero, size: imageSize))

        // Compute center
        let center = CGPoint(
            x: points.map { $0.x }.reduce(0, +) / CGFloat(points.count),
            y: points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
        )

        // Adjust points
        let adjustedPoints = points.map { point -> CGPoint in
            let dx = point.x - center.x
            let dy = point.y - center.y
            return CGPoint(
                x: center.x + dx * shrinkFactor + padding,
                y: center.y + dy * shrinkFactor + verticalOffset + padding
            )
        }

        // -------- Create path with smooth curves -------- //
        let path = UIBezierPath()
        let count = adjustedPoints.count
        guard let first = adjustedPoints.first, let last = adjustedPoints.last else {
            UIGraphicsEndImageContext()
            return nil
        }

        // Move to first point
        path.move(to: first)

        // Draw middle smooth curves (tension-based)
        let tension: CGFloat = 0.5
        for i in 0..<count-1 {
            let p0 = adjustedPoints[(i - 1 + count) % count]
            let p1 = adjustedPoints[i]
            let p2 = adjustedPoints[(i + 1) % count]
            let p3 = adjustedPoints[(i + 2) % count]

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension / 6,
                y: p1.y + (p2.y - p0.y) * tension / 6
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension / 6,
                y: p2.y - (p3.y - p1.y) * tension / 6
            )

            path.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
        }

        // Left corner rounded
        path.addArc(
            withCenter: first,
            radius: cornerRadius,
            startAngle: CGFloat.pi / 2,
            endAngle: CGFloat.pi * 3/2,
            clockwise: true
        )

        // Right corner rounded
        path.addArc(
            withCenter: last,
            radius: cornerRadius,
            startAngle: -CGFloat.pi / 2,
            endAngle: CGFloat.pi / 2,
            clockwise: true
        )

        path.close()

        // Draw boundary (soft edge)
        ctx.setLineWidth(boundaryWidth)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.05).cgColor)
        ctx.addPath(path.cgPath)
        ctx.strokePath()

        // Fill lips area with solid white
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        // Extract CGImage
        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()
        
        let fImage = CIImage(cgImage: cgImage)

        return MTIImage(cgImage: cgImage, options: [.SRGB: false], isOpaque: false)
            .unpremultiplyingAlpha()
    }
    
    func createInnerLipsMask1(
        points: [CGPoint],
        imageSize: CGSize,
        padding: CGFloat = 0,
        shrinkFactor: CGFloat = 0.95,
        verticalOffset: CGFloat = 0,
        boundaryWidth: CGFloat = 0,
        cornerRadius: CGFloat = 0.0
    ) -> (mask: MTIImage, center: CGPoint, radius: CGSize)? {
        guard points.count > 2 else { return nil }

        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // Transparent background
        ctx.setFillColor(UIColor.clear.cgColor)
        ctx.fill(CGRect(origin: .zero, size: imageSize))

        // Compute arithmetic center of points (initial)
        let initialCenter = CGPoint(
            x: points.map { $0.x }.reduce(0, +) / CGFloat(points.count),
            y: points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
        )

        // Adjust points with shrinkFactor / padding / verticalOffset
        let adjustedPoints = points.map { point -> CGPoint in
            let dx = point.x - initialCenter.x
            let dy = point.y - initialCenter.y
            return CGPoint(
                x: initialCenter.x + dx * shrinkFactor + padding,
                y: initialCenter.y + dy * shrinkFactor + verticalOffset + padding
            )
        }

        // -------- Create smooth path -------- //
        let path = UIBezierPath()
        let count = adjustedPoints.count
        guard let first = adjustedPoints.first, let last = adjustedPoints.last else {
            UIGraphicsEndImageContext()
            return nil
        }

        path.move(to: first)

        // Tension-based smooth curves
        let tension: CGFloat = 0.5
        for i in 0..<count-1 {
            let p0 = adjustedPoints[(i - 1 + count) % count]
            let p1 = adjustedPoints[i]
            let p2 = adjustedPoints[(i + 1) % count]
            let p3 = adjustedPoints[(i + 2) % count]

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension / 6,
                y: p1.y + (p2.y - p0.y) * tension / 6
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension / 6,
                y: p2.y - (p3.y - p1.y) * tension / 6
            )

            path.addCurve(to: p2, controlPoint1: cp1, controlPoint2: cp2)
        }

        // Rounded corners
        path.addArc(withCenter: first, radius: cornerRadius, startAngle: CGFloat.pi / 2, endAngle: CGFloat.pi * 3/2, clockwise: true)
        path.addArc(withCenter: last, radius: cornerRadius, startAngle: -CGFloat.pi / 2, endAngle: CGFloat.pi / 2, clockwise: true)

        path.close()

        // Draw boundary (soft edge)
        ctx.setLineWidth(boundaryWidth)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.05).cgColor)
        ctx.addPath(path.cgPath)
        ctx.strokePath()

        // Fill lips area
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        // Extract CGImage
        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()

        // -------- Compute exact center & radius of path -------- //
        let boundingBox = path.cgPath.boundingBox
        let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        let radius = CGSize(width: boundingBox.width / 2, height: boundingBox.height / 2)
        
        let ciimage = CIImage(cgImage: cgImage)

        // Convert to MTIImage
        let maskImage = MTIImage(cgImage: cgImage, options: [.SRGB: false], isOpaque: false).unpremultiplyingAlpha()

        return (mask: maskImage, center: center, radius: radius)
    }


}
