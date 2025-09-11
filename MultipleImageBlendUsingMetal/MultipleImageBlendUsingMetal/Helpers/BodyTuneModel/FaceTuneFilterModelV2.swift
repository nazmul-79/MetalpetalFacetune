//
//  FaceTuneFilterModelV2.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 9/9/25.
//
import UIKit
import MetalPetal

enum FaceParsingIndex {
    static let rightEyeContourIndices: [Int] = [33, 7, 163, 144, 145, 153, 154, 155,133, 173, 157, 158, 159, 160, 161, 246]
    static let rightEyelidIndices: [Int] = [190,56,28,27,29,30,247,130,25,110,24,23,22,26,112,243]
    
    static let rightEyelidAndContourIndices = FaceParsingIndex.rightEyelidIndices + FaceParsingIndex.rightEyeContourIndices

    static let rightIrisIndices: [Int] = [469, 471,159,158,160,468,171,145]
    
    static let leftEyeContourIndices: [Int] = [263, 249, 390, 373, 374, 380, 381, 382,362,398, 384, 385, 386, 387, 388, 466]
    
    static let leftEyelidIndices: [Int] = [414,286,258,257,259,260,467,359, 255,339,254,253,252,256,341,463]
    
    static let leftEyelidAndContourIndices = FaceParsingIndex.leftEyeContourIndices + FaceParsingIndex.leftEyelidIndices
    
    static let leftIrisIndices: [Int] = [476, 385, 386, 473, 373,374,380,474]
    
    static let rightEyeBrow: [Int] = [71,70,46,63,53,105,52,66,65,107,55]
    static let leftEyeBrow: [Int] = [336,285,296,295,334,282,293,283,251,301,300]
}

struct FaceTuneFilterModelV2 {
    var allPoints: [CGPoint] = []
    var imageViewBounds: CGRect = .zero
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
                    //outputImage = self.applynoseFilter(image: outputImage)
                }
                break
            case .lips:
                if category == filterCategory {
                    lipsFilterModel.scaleFactor = CGFloat(scaleValue)
                }
                if lipsFilterModel.scaleFactor != 0.0 {
                    //outputImage = self.applyLipsFilter(image: outputImage)
                }
                break
            case .cheeks:
                if category == filterCategory {
                    jawFilterModel.scaleFactor = CGFloat(scaleValue)
                }
                if jawFilterModel.scaleFactor != 0.0 {
                    //outputImage = self.applyJawFilter(image: outputImage)
                }
                break
            case .facialProportion:
                if category == filterCategory {
                    faceProportionFilter.scaleFactor = CGFloat(scaleValue)
                }
                if faceProportionFilter.scaleFactor != 0.0 {
                    //outputImage = self.applyFaceProportionFilter(image: outputImage)
                }
                break
            case .eyeLashesh:
                if category == filterCategory {
                    eyelashFilterModel.scaleFactor = scaleValue
                }
                if eyelashFilterModel.scaleFactor != 0.0 {
                    //outputImage = self.applyEyelashesFilter(image: outputImage)
                }
            case .eyeContrast:
                if category == filterCategory {
                    eyeBrightnessFilterModel.scaleFactor = scaleValue
                }
                if eyeBrightnessFilterModel.scaleFactor != 0.0 {
                    //outputImage = self.applyEyeBrightnessFilter(image: outputImage)
                }
            case .teethWhitening:
                if category == filterCategory {
                    teethWhiteningModel.scaleFactor = scaleValue
                }
                if teethWhiteningModel.scaleFactor != 0.0 {
                    //outputImage = self.applyTeethWhiteningFilter(image: outputImage)
                }
            case .brighterLips:
                if category == filterCategory {
                    lipsBrighterModel.scaleFactor = CGFloat(scaleValue)
                }
                if lipsBrighterModel.scaleFactor != 0.0 {
                    //outputImage = self.applyLipsBrighterFilter(inputImage: outputImage)
                }
            
            default: break
            }
        }
        return outputImage
    }
}

//EyeBrow Filter
extension FaceTuneFilterModelV2 {
    mutating func applyEyeBrowFilter(image: MTIImage) -> MTIImage {
        let filter = EyeBrowZoomFilterV2()
        filter.inputImage = image
        filter.leftBrowCenter = eyeBrowFilterModel.leftEyeBrowcenter
        filter.rightBrowCenter = eyeBrowFilterModel.rightEyeBrowcenter
        filter.leftBrowRadius = eyeBrowFilterModel.leftEyeBrowRadius
        filter.rightBrowRadius = eyeBrowFilterModel.rightEyeBrowRadius
        
        filter.scaleFactor =  eyeBrowFilterModel.scaleFactor
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
    
    mutating func updateEyeBrowFilter() {
        
        let leftBrowpoints: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.leftEyeBrow)
        let rightEyeBrowPoints: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.rightEyeBrow)
        
        
        let convertedPointsleftEye = self.getNoramlizePoint(points: leftBrowpoints)
        
        let convertedPointsRightEye = self.getNoramlizePoint(points: rightEyeBrowPoints)
        
        
        let leftBox = eyeBrowBoundingBox(for: convertedPointsleftEye)
        let rightBox = eyeBrowBoundingBox(for: convertedPointsRightEye)
        
        
        
        
        let texWidth  = Float(self.imageSize.width)
        let texHeight = Float(self.imageSize.height)

        eyeBrowFilterModel.leftEyeBrowcenter = SIMD2<Float>(
            Float(leftBox.center.x) / texWidth,
            Float(leftBox.center.y) / texHeight
        )

        eyeBrowFilterModel.leftEyeBrowRadius = SIMD2<Float>(
            Float(leftBox.size.width) / texWidth,
            Float(leftBox.size.height) / texHeight
        )

        eyeBrowFilterModel.rightEyeBrowcenter = SIMD2<Float>(
            Float(rightBox.center.x) / texWidth,
            Float(rightBox.center.y) / texHeight
        )

        eyeBrowFilterModel.rightEyeBrowRadius = SIMD2<Float>(
            Float(rightBox.size.width) / texWidth,
            Float(rightBox.size.height) / texHeight
        )
    }
    
    func eyeBrowBoundingBox(for points: [CGPoint]) -> (center: CGPoint, size: CGSize) {
        guard !points.isEmpty else { return (CGPoint.zero, .zero) }
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        let center = CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        return (center, CGSize(width: maxX - minX, height: maxY - minY))
    }
    
}

//MARK Eyes Functionality For V2
extension FaceTuneFilterModelV2 {
    
    mutating func applyEyeFilter(image: MTIImage) -> MTIImage {
        let filter = EyeMetalFilterV2()
        
        filter.leftEyeCenter = SIMD2<Float>(Float(eyeFilterModel.leftEyeCenter.x / self.imageSize.width),
                                            Float(eyeFilterModel.leftEyeCenter.y / self.imageSize.height))
        
        filter.leftEyeRadiusXY = SIMD2<Float>(Float(eyeFilterModel.leftEyeRadius.x / self.imageSize.width),
                                              Float(eyeFilterModel.leftEyeRadius.y / self.imageSize.height))
        
        filter.rightEyeCenter = SIMD2<Float>(Float(eyeFilterModel.rightEyeCenter.x / self.imageSize.width),
                                             Float(eyeFilterModel.rightEyeCenter.y /  self.imageSize.height))
        
        filter.rightEyeRadiusXY = SIMD2<Float>(Float(eyeFilterModel.rightEyeRadius.x /  self.imageSize.width),
                                               Float(eyeFilterModel.leftEyeRadius.y /  self.imageSize.height))
        
        filter.scaleFactor = eyeFilterModel.scaleFactor
        
        filter.inputImage = image
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
    
    mutating func updateEyeFilterModel() -> Void {
        
        let leftpoints: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.leftEyelidAndContourIndices)
        let rightEyePoints: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.rightEyelidAndContourIndices)
       
        eyeFilterModel.leftEyePoints = leftpoints
        eyeFilterModel.rightEyePoints = rightEyePoints
        eyeFilterModel.scaleFactor = 0.0
        
        let convertedPointsleftEye = self.getNoramlizePoint(points: leftpoints)
        
        let convertedPointsRightEye = self.getNoramlizePoint(points: rightEyePoints)
        
        debugPrint("Left eye and right eye points: \(convertedPointsleftEye) \(convertedPointsRightEye)")
        
        let (lefteyeCenter, lefteyeRadiusX, lefteyeRadiusY) = calculateEyeEllipse(points: convertedPointsleftEye)
        
        let (righteyeCenter, righteyeRadiusX, righteyeRadiusY) = calculateEyeEllipse(points: convertedPointsRightEye)
        
        
        eyeFilterModel.leftEyeCenter = lefteyeCenter
        eyeFilterModel.leftEyeRadius.x = lefteyeRadiusX
        eyeFilterModel.leftEyeRadius.y = lefteyeRadiusY
        
        eyeFilterModel.rightEyeCenter = righteyeCenter
        eyeFilterModel.rightEyeRadius.x = righteyeRadiusX
        eyeFilterModel.rightEyeRadius.y = righteyeRadiusY
    }
    
    func calculateEyeEllipse(points: [CGPoint]) -> (center: CGPoint, radiusX: CGFloat, radiusY: CGFloat) {
        guard !points.isEmpty else {
            return (CGPoint(x: 0.5, y: 0.5), 0.05, 0.03) // fallback normalized
        }

        // centroid
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let center = CGPoint(x: sum.x / CGFloat(points.count),
                             y: sum.y / CGFloat(points.count))

        // radius = farthest distance in x and y
        let radiusX = points.reduce(0) { max($0, abs($1.x - center.x)) }
        let radiusY = points.reduce(0) { max($0, abs($1.y - center.y)) }

        // padding
        let padding: CGFloat = 1.0
        return (center, radiusX * padding, radiusY * padding)
    }
}

extension FaceTuneFilterModelV2 {
    private func getNoramlizePoint(points: [CGPoint] ) -> [CGPoint] {
        let imageSize = self.imageSize
        let viewSize = self.imageViewBounds.size
        
        let widthScale = viewSize.width / imageSize.width
        let heightScale = viewSize.height / imageSize.height
        
        let scale = min(widthScale, heightScale) // Aspect Fit
        
        // offsets (image centered in view)
        let xOffset = (viewSize.width - imageSize.width * scale) / 2
        let yOffset = (viewSize.height - imageSize.height * scale) / 2
        
        let normalizedPoints: [CGPoint] = points.map { point in
            let x = (point.x - xOffset) / scale
            let y = (point.y - yOffset) / scale
            return CGPoint(x: x, y: y)
        }
        return normalizedPoints
    }
    
    func getSpecificFaceIndices(indices: [Int]) -> [CGPoint] {
        let filterDots = indices.compactMap { index in
            index < self.allPoints.count ? self.allPoints[index] : nil
        }
        return filterDots
    }
}
