//
//  FaceTuneFilterModelV2.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 9/9/25.
//
import UIKit
import MetalPetal
import MediaPipeTasksVision

enum FaceParsingIndex {
    static let rightEyeContourIndices: [Int] = [33, 7, 163, 144, 145, 153, 154, 155, 173, 157, 158, 159, 160, 161, 246]
    static let rightEyelidIndices: [Int] = [190,56,28,27,29,30,247,130,25,110,24,23,22,26,112,243]
    
    static let rightEyelidAndContourIndices = FaceParsingIndex.rightEyelidIndices + FaceParsingIndex.rightEyeContourIndices

    static let rightIrisIndices: [Int] = [471,160,159,158,469,153,145,144] //468
    
    static let leftEyeContourIndices: [Int] = [263, 249, 390, 373, 374, 380, 381, 382,362,398, 384, 385, 386, 387, 388, 466]
    
    static let leftEyelidIndices: [Int] = [414,286,258,257,259,260,467,359, 255,339,254,253,252,256,341,463]
    
    static let leftEyelidAndContourIndices = FaceParsingIndex.leftEyeContourIndices + FaceParsingIndex.leftEyelidIndices
    
    static let leftIrisIndices: [Int] = [476, 385, 386,387,474,373,374,380] //473
    
    //static let rightEyeBrow: [Int] = [71,70,63,53,105,52,66,65,107,55]
   // static let leftEyeBrow: [Int] = [336,285,296,295,334,282,293,283,301,300]
    static let rightEyeBrow: [Int] = [70,63,105,66,107,55,65,52,53,46]
    static let leftEyeBrow: [Int] = [336,296,334,293,300,276,283,282,295,285]
   
    static let  outerLipsPoints: [Int] = [
        61, 146, 91, 181, 84, 17,
        314, 405, 321, 375, 291,
        409, 270, 269, 267, 0,
        37, 39, 40, 185 ]
    
    static  let innerLipsIndices: [Int] = [
        78, 95, 88, 178, 87, 14, 317, 402,
        318, 324, 308, 415, 310, 311, 312,
        13, 82, 81, 80, 191
    ]
    
    static let faceOvalIndices: [Int] = FaceLandmarker.faceOvalConnections().compactMap { connection in
        return Int(connection.start)
    }
    
    static let cheeksIndices: [Int] = [215,58,138,135,172,136,135,169,150,149,32,262,208,
                                       199,428,369,395,379,176,171,175,148,152,377,396,400,
                                       378,394,365,364,397,367,288,435]
    
    static let commonIndices = [58, 136, 148, 149, 150, 152, 172, 176, 288, 365, 379, 378, 377, 397, 400]
    
    static let noseIndices = [
        // Nose bridge / center
        1, 2, 4, 5, 6, 19, 94, 168, 195, 197,8,
        // left area Point
        193, 245, 188, 128, 196, 114, 174, 217, 236, 122, 3, 51, 45, 44,
        218, 115, 198, 49, 48, 220, 237, 209, 131, 102, 129, 64, 98, 235,
        219, 240, 75, 60, 97, 166,126,134,99,
        //right Area Point
        417, 351, 412, 419, 399, 248, 456, 437, 420, 355, 429, 363, 360,
        281, 275, 274, 344, 438, 460, 327, 326, 290, 279, 371, 278, 358,
        331, 294, 277, 465,331,294
    ]
    
    static let noseIndicesc = [
        1, 2, 4, 5, 6, 19, 94, 168, 195, 197
    ]
    
    static let boundary = [244,245,189,413,464,453]
    
    static let neckIndices = [136,150,149,176,148,152,377,400,378,379,365]

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
    var eyeBrowBrightenModel: EyeBrowBrightenFilterModel = .init()
    var neckShadowFilterModel: NeckShadowFilterModel = .init()
    var faceShdowModel: FaceShadowModel = .init()
    var highlighstModel: FaceHightLightsModel = .init()
    var teethWhitenFilterModel: TeethWhiteningFilterModel = .init()
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
                    outputImage = self.applyNoseFilter(image: outputImage)
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
                    outputImage = self.applyLipsBrighterFilter(image: outputImage)
                }
            case .EyeBrowsConstrast:
                if category == filterCategory {
                    eyeBrowBrightenModel.scaleFactor = CGFloat(scaleValue)
                }
                if eyeBrowBrightenModel.scaleFactor != 0.0 {
                    outputImage = self.applyEyeBrowBrightnessFilter(image: outputImage)
                }
                
            case .neeckShadow:
                if category == filterCategory {
                    neckShadowFilterModel.scaleFactor = CGFloat(scaleValue)
                }
                if neckShadowFilterModel.scaleFactor != 0.0 {
                    outputImage = self.applyNeckShadowFilter(image: outputImage)
                }
                
            case .shadow:
                if category == filterCategory {
                    faceShdowModel.scaleFactor = CGFloat(scaleValue)
                }
                if faceShdowModel.scaleFactor != 0.0 {
                    outputImage = self.applyFaceShadowFilter(image: outputImage)
                }
                
            case .highlights:
                if category == filterCategory {
                    highlighstModel.scaleFactor = CGFloat(scaleValue)
                }
                if highlighstModel.scaleFactor != 0.0 {
                    outputImage = self.applyFaceHighlightsFilter(image: outputImage)
                }
            
            default: break
            }
        }
        return outputImage
    }
}

extension FaceTuneFilterModelV2 {
    mutating func applyTeethWhiteningFilter(image: MTIImage) -> MTIImage {
        let filter = TeethBrighterFilterV2()
        
        filter.scaleFactor = Float(teethWhiteningModel.scaleFactor)
        filter.outerLipsPoint = teethWhiteningModel.outerPoints
        filter.innerLipsPoint = teethWhiteningModel.innerPoints
        filter.inputImage = image
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
}

extension FaceTuneFilterModelV2 {
    mutating func applyFaceHighlightsFilter(image: MTIImage) -> MTIImage {
       
        let filter = FaceHighLightsFilter()
        
        filter.faceScaleFactor = Float(self.highlighstModel.scaleFactor)
        filter.inputImage = image
        filter.faceRectCenter = self.faceShdowModel.faceCenter
        filter.faceRectRadius = self.faceShdowModel.faceRadius
        filter.rotation = self.faceShdowModel.rotation
        filter.point = self.faceShdowModel.smoothCurveFast
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
    mutating func applyFaceShadowFilter(image: MTIImage) -> MTIImage {
       
        let filter = FaceShadowMetalFilter()
        
        filter.faceScaleFactor = Float(self.faceShdowModel.scaleFactor)
        filter.inputImage = image
        filter.faceRectCenter = self.faceShdowModel.faceCenter
        filter.faceRectRadius = self.faceShdowModel.faceRadius
        filter.rotation = self.faceShdowModel.rotation
        filter.point = self.faceShdowModel.smoothCurveFast
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
    
    mutating func updateFaceShadowFilter() {
        self.faceShdowModel.scaleFactor = 0.0
        let faceOveralPoints: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.faceOvalIndices)
        let normalizedPoint = self.getNoramlizePoint(points: faceOveralPoints)
        
        let simdPoints: [SIMD2<Float>] = normalizedPoint.map { point in
            SIMD2(Float(point.x) / Float(imageSize.width),
                  Float(point.y) / Float(imageSize.height))
        }
       // let polygonImg = self.polygonMaskImage(points: normalizedPoint, size: self.imageSize)
        
        //let image = CIImage(cgImage: polygonImg!.cgImage!)
        
        debugPrint("Pintssss",normalizedPoint,faceOveralPoints,FaceParsingIndex.faceOvalIndices)
        
        
        let center = self.polygonCenter(points: normalizedPoint)
        let radius = self.polygonMaxRadius(points: normalizedPoint, center: center)
        //let maxRadius = self.maxDistance(points: normalizedPoint, center: center)
        
        let texWidth  = Float((self.imageSize.width))
        let texHeight = Float((self.imageSize.height))
        
        

        let faceCenter = SIMD2<Float>(
            Float(center.x / texWidth),
            Float(center.y / texHeight) // flip Y
        )

        let faceRadius = SIMD2<Float>(
            Float(radius / texWidth),
            Float(radius / texWidth)
        )
        self.faceShdowModel.faceCenter = faceCenter
        self.faceShdowModel.faceRadius = faceRadius
        self.faceShdowModel.rotation = 0.0
        self.faceShdowModel.smoothCurveFast = simdPoints
        
        self.highlighstModel.scaleFactor = 0.0
    }
}

extension FaceTuneFilterModelV2 {
    mutating func updateNeckShadow() {
        let neckShadowPoint: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.neckIndices)
        let neckShadowNormalized = self.getNoramlizePoint(points: neckShadowPoint)
        
        
        let neckShadowNormalizedSimd: [SIMD2<Float>] = neckShadowNormalized.map {
            SIMD2(Float($0.x),
                  Float($0.y))
        }
        
        let finalNeckShadowPolygon = self.shiftJawPointsDown(jawPoints: neckShadowNormalizedSimd,
                                                                     offset: 70)
        
        debugPrint("finalNeckShadowPolygon", finalNeckShadowPolygon,neckShadowNormalizedSimd)
        
        let texWidth = Float(imageSize.width)
        let texHeight = Float(imageSize.height)

        let finalNeckShadowPolygonNoramlized: [SIMD2<Float>] = finalNeckShadowPolygon.map {
            SIMD2(Float($0.x) / texWidth,
                  Float($0.y) / texHeight)
        }
        
        neckShadowFilterModel.jawPoints = finalNeckShadowPolygonNoramlized
        neckShadowFilterModel.scaleFactor = 0.0
        debugPrint("neck Shadow Noramlized Point",finalNeckShadowPolygonNoramlized, neckShadowNormalizedSimd)
        
    }
    
   /* func makeSmartNeckShadowPolygon(jawPoints: [SIMD2<Float>], offset: Float) -> [SIMD2<Float>] {
        guard jawPoints.count > 1 else { return [] }
        
        var offsetPoints: [SIMD2<Float>] = []
        
        for i in 0..<jawPoints.count {
            let p = jawPoints[i]
            
            // Tangent: average of prev & next
            var tangent = SIMD2<Float>(0, 0)
            if i > 0 {
                tangent += simd_normalize(jawPoints[i] - jawPoints[i-1])
            }
            if i < jawPoints.count - 1 {
                tangent += simd_normalize(jawPoints[i+1] - jawPoints[i])
            }
            
            tangent = simd_normalize(tangent)
            
            // Perpendicular normal
            var normal = SIMD2<Float>(-tangent.y, tangent.x)
            
            // Ensure normal points downward (positive y)
            if normal.y < 0 {
                normal = -normal
            }
            
            let offsetPoint = p + normal * offset
            offsetPoints.append(offsetPoint)
        }
        
        // Polygon = top (jawline) + bottom (reversed offset)
        return jawPoints + offsetPoints.reversed()
    }*/
    
    func shiftJawPointsDown(jawPoints: [SIMD2<Float>], offset: Float) -> [SIMD2<Float>] {
        return jawPoints.map { SIMD2<Float>($0.x, $0.y + offset) }
    }


    
    mutating func applyNeckShadowFilter(image: MTIImage) -> MTIImage {
        let filter = NeckShadowMetalFilter()
        filter.scaleFactor =  Float(neckShadowFilterModel.scaleFactor)
        filter.jawPoints = neckShadowFilterModel.jawPoints
        filter.inputImage = image
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }

}

extension FaceTuneFilterModelV2 {
    mutating func updateEyeBrowContrast() {
        
        let leftBrowpoints: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.leftEyeBrow)
        let rightEyeBrowPoints: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.rightEyeBrow)
        
        
        let leftBrowpointsNormalized = self.getNoramlizePoint(points: leftBrowpoints)
        
        let rightBrowpointsNormalized = self.getNoramlizePoint(points: rightEyeBrowPoints)
        
    
        let texWidth = Float(imageSize.width)
        let texHeight = Float(imageSize.height)

        let leftContourPointsNormalized: [SIMD2<Float>] = leftBrowpointsNormalized.map {
            SIMD2(Float($0.x) / texWidth,
                  Float($0.y) / texHeight)
        }
        
        let rightContourPointsNormalized: [SIMD2<Float>] = rightBrowpointsNormalized.map {
            SIMD2(Float($0.x) / texWidth,
                  Float($0.y) / texHeight)
        }
        
       // let orderPointsleft = self.orderBrowPolygonByAngle(leftContourPointsNormalized)
        //let orderPointsright = self.orderBrowPolygonByAngle(rightContourPointsNormalized)
        //debugPrint("Eye Brow Points ", orderPointsleft, leftBrowpointsNormalized, rightBrowpointsNormalized, orderPointsright)
        
        eyeBrowBrightenModel.leftPoints = leftContourPointsNormalized
        eyeBrowBrightenModel.rightPoints = rightContourPointsNormalized
        eyeBrowFilterModel.scaleFactor = 0.0
    }
    
    func orderBrowPolygonByAngle(_ points: [SIMD2<Float>]) -> [SIMD2<Float>] {
        // 1. Find centroid
        let center = points.reduce(SIMD2<Float>(0,0)) { $0 + $1 } / Float(points.count)
        
        // 2. Sort points by angle from center
        let sorted = points.sorted {
            let angle0 = atan2($0.y - center.y, $0.x - center.x)
            let angle1 = atan2($1.y - center.y, $1.x - center.x)
            return angle0 < angle1
        }
        
        return sorted
    }

    mutating func applyEyeBrowBrightnessFilter(image: MTIImage) -> MTIImage {
        let filter = EyeBrowMetalFilter()
        filter.scaleFactor =  Float(eyeBrowBrightenModel.scaleFactor)
        filter.leftbrowPoints = eyeBrowBrightenModel.leftPoints
        filter.rightbrowPoints = eyeBrowBrightenModel.rightPoints
        filter.inputImage = image
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
    
}


extension FaceTuneFilterModelV2 {
    mutating func updateEyeContrast() {
        
        let rightEyeLashesUpIndices = [246,160,161,159,158,157]
        let rightEyeLashesDownIndices = [154,153,145,163,7]//[33,7, 163, 144, 145, 153, 154,155]
        let leftEyelashesUpIndices = [398, 384, 385, 386, 387, 388, 466]
        let leftEyelashesDownIndices = [249,390,373,374,380,381]//[381,380,374,373,390,249,263]
        
        
        
        let rightEyeLashesupPoint = self.processEyelashesPoints(indices: rightEyeLashesUpIndices,
                                                                imageSize: self.imageSize,
                                                                offset: 2)
        
        let rightEyeLashesDownPoint = self.processEyelashesPoints(indices: rightEyeLashesDownIndices,
                                                                imageSize: self.imageSize,
                                                                offset: -2)
        
        let leftEyelashesUpPoint = self.processEyelashesPoints(indices: leftEyelashesUpIndices,
                                                                imageSize: self.imageSize,
                                                                offset: 2)
        
        let leftEyelashesDownPoint = self.processEyelashesPoints(indices: leftEyelashesDownIndices,
                                                                imageSize: self.imageSize,
                                                                offset: -2)
        
        let leftEyeIrisIndices: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.leftIrisIndices)
        let rightEyeIrisIndices: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.rightIrisIndices)
        
        
       // let leftEyeContourPoints: [CGPoint] = self.getNoramlizePoint(points: leftEyeContourIndices)
        //let rightEyeContourPoints: [CGPoint] = self.getNoramlizePoint(points: rightEyeContourIndices)
        
        let leftEyeIrisPoint: [CGPoint] = self.getNoramlizePoint(points: leftEyeIrisIndices)
        let rightEyeIrisPoints: [CGPoint] = self.getNoramlizePoint(points: rightEyeIrisIndices)
        
        
        //let innerLipsNormalizedPoint = self.getNoramlizePoint(points: innerLipsPoint)
        //let outerLipsNormalizedPoint = self.getNoramlizePoint(points: outerLipsPoint)
        
        let texWidth = Float(imageSize.width)
        let texHeight = Float(imageSize.height)

        
        let leftIrisPointsNormalized: [SIMD2<Float>] = leftEyeIrisPoint.map {
            SIMD2(Float($0.x) / texWidth,
                  Float($0.y) / texHeight)
        }
        
        let rightIrisPointsNormalized: [SIMD2<Float>] = rightEyeIrisPoints.map {
            SIMD2(Float($0.x) / texWidth,
                  Float($0.y) / texHeight)
        }
        
        let rightEyePoint1 = rightEyeLashesupPoint + rightEyeLashesDownPoint
        // --- Compute centroid ---
        let centroid = rightEyePoint1.reduce(SIMD2<Float>(0,0), +) / Float(rightEyePoint1.count)

        // --- Sort points clockwise ---
        let sortedRightEye = rightEyePoint1.sorted { a, b in
            let angleA = atan2(a.y - centroid.y, a.x - centroid.x)
            let angleB = atan2(b.y - centroid.y, b.x - centroid.x)
            return angleA < angleB
        }

        // --- Close polygon by repeating first point ---
        let hullPoints = sortPointsClockwise(rightEyePoint1)
        let rightEyeContour = sortedRightEye + [sortedRightEye[0]]
        
        let sortedByY = rightEyePoint1.sorted { $0.y < $1.y }
        
        eyeBrightnessFilterModel.scaleFactor = 0
        eyeBrightnessFilterModel.leftEyePoints = leftEyelashesUpPoint + leftEyelashesDownPoint
        eyeBrightnessFilterModel.leftIrisPoints = leftIrisPointsNormalized
        eyeBrightnessFilterModel.rightEyePoints = rightEyePoint1 //rightEyeLashesupPoint + rightEyeLashesDownPoint
        eyeBrightnessFilterModel.rightIrisPoints = rightIrisPointsNormalized
        
        debugPrint("Left and right Points",  hullPoints,  eyeBrightnessFilterModel.leftEyePoints)
        
    }
    
    func sortPointsClockwise(_ points: [SIMD2<Float>]) -> [SIMD2<Float>] {
        guard points.count > 2 else { return points }
        
        // Calculate centroid
        var centroid = SIMD2<Float>(0, 0)
        for point in points {
            centroid += point
        }
        centroid /= Float(points.count)
        
        // Sort points by angle around centroid
        return points.sorted { pointA, pointB in
            let angleA = atan2(pointA.y - centroid.y, pointA.x - centroid.x)
            let angleB = atan2(pointB.y - centroid.y, pointB.x - centroid.x)
            return angleA < angleB
        }
    }

    // Use convex hull for better polygon formation
  
    
    mutating func applyEyeBrightnessFilter(image: MTIImage) -> MTIImage {
        let filter = EyeConstrastMetalFilterV2()
        
        filter.scaleFactor = Float(eyeBrightnessFilterModel.scaleFactor)
        filter.leftEyeIrisPoints = eyeBrightnessFilterModel.leftIrisPoints
        filter.leftEyeContourPoints = eyeBrightnessFilterModel.leftEyePoints
        filter.rightEyeIrisPoints = eyeBrightnessFilterModel.rightIrisPoints
        filter.rightEyeContourPoints = eyeBrightnessFilterModel.rightEyePoints
        filter.inputImage = image
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
}

extension FaceTuneFilterModelV2 {
    mutating func updateLipsContrastFilterModel() {
        let innerLipsPoint: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.innerLipsIndices)
        let innerLipsNormalizedPoint = self.getNoramlizePoint(points: innerLipsPoint)
        let outerLipsPoint: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.outerLipsPoints)
        let outerLipsNormalizedPoint = self.getNoramlizePoint(points: outerLipsPoint)
        
        let texWidth = Float(imageSize.width)
        let texHeight = Float(imageSize.height)

        let noramlizedOuter: [SIMD2<Float>] = outerLipsNormalizedPoint.map {
            SIMD2(Float($0.x) / texWidth,
                  Float($0.y) / texHeight)
        }
        
        let noramlizedInner: [SIMD2<Float>] = innerLipsNormalizedPoint.map {
            SIMD2(Float($0.x) / texWidth,
                  Float($0.y) / texHeight)
        }
        
        lipsBrighterModel.outerPoints = noramlizedOuter
        lipsBrighterModel.innerPoints = noramlizedInner
        lipsBrighterModel.scaleFactor = 0.0
        
        teethWhiteningModel.outerPoints = noramlizedOuter
        teethWhiteningModel.innerPoints = noramlizedInner
        teethWhiteningModel.scaleFactor = 0.0
        debugPrint("Inner Lips and OuterLips Count", outerLipsNormalizedPoint, innerLipsNormalizedPoint)
    }
    
    mutating func applyLipsBrighterFilter(image: MTIImage) -> MTIImage {
        let filter = LipsBrighterFilterV2()
        
        filter.scaleFactor = Float(lipsBrighterModel.scaleFactor)
        filter.outerLipsPoint = lipsBrighterModel.outerPoints
        filter.innerLipsPoint = lipsBrighterModel.innerPoints
        filter.inputImage = image
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
}

extension FaceTuneFilterModelV2 {
    mutating func updateEyelashFilterModel() {
        
        /*let rightEyeLashesUpIndices = [246,160,161,159,158,157,173]
        let rightEyeLashesDownIndices = [33,7, 163, 144, 145, 153, 154,155]
        let leftEyelashesUpIndices = [398, 384, 385, 386, 387, 388, 466]
        let leftEyelashesDownIndices = [381,380,374,373,390,249,263]*/
        
        let rightEyeLashesUpIndices = [246,160,161,159,158,157,173]
        let rightEyeLashesDownIndices = [154,153,145,163,7,33]//[33,7, 163, 144, 145, 153, 154,155]
        let leftEyelashesUpIndices = [398, 384, 385, 386, 387, 388, 466]
        let leftEyelashesDownIndices = [249,390,373,374,380,381]//[381,380,374,373,390,249,263]
        
        
        
        let rightEyeLashesupPoint = self.processEyelashesPoints(indices: rightEyeLashesUpIndices,
                                                                imageSize: self.imageSize,
                                                                offset: 0)
        
        let rightEyeLashesDownPoint = self.processEyelashesPoints(indices: rightEyeLashesDownIndices,
                                                                imageSize: self.imageSize,
                                                                offset: 0)
        
        let leftEyelashesUpPoint = self.processEyelashesPoints(indices: leftEyelashesUpIndices,
                                                                imageSize: self.imageSize,
                                                                offset: 0)
        
        let leftEyelashesDownPoint = self.processEyelashesPoints(indices: leftEyelashesDownIndices,
                                                                imageSize: self.imageSize,
                                                                offset: 0)
        
        
       /* let rightEyeContourUpIndices: [Int] = [381,380,374,373,390,249,263] //[398, 384, 385, 386, 387, 388, 466]//[33,7, 163, 144, 145, 153, 154,155] //[246,160,161,159,158,157,173] //[33,7, 163, 144, 145, 153, 154,155] //133, 158, 159, 160, 161
        //let rightEyeDownIndices: [Int] = [33,7,]
        let righteyelashesUpIndices: [CGPoint] = self.getSpecificFaceIndices(indices: rightEyeContourUpIndices)
        let normalizedRightEyeUPPoint = self.getNoramlizePoint(points: righteyelashesUpIndices)
        
        //[263, 249, 390, 373, 374, 380, 381, 382,362,398, 384, 385, 386, 387, 388, 466]
        
        let texWidth = Float(imageSize.width)
        let texHeight = Float(imageSize.height)
        
        let simdPoints1: [SIMD2<Float>] = normalizedRightEyeUPPoint.map {
            SIMD2(Float($0.x),
                  Float($0.y))
        }
        
        
        let points = self.shiftJawPointsDown(jawPoints: simdPoints1,
                                             offset: 6)

        let simdPoints: [SIMD2<Float>] = points.map {
            SIMD2(Float($0.x) / texWidth,
                  Float($0.y) / texHeight)
        }*/
        
        self.eyelashFilterModel.leftEyeUpIndices = leftEyelashesUpPoint + leftEyelashesDownPoint
        self.eyelashFilterModel.rightEyeUpIndices = rightEyeLashesupPoint + rightEyeLashesDownPoint
    }
    
    func processEyelashesPoints(indices: [Int],
                                imageSize: CGSize,
                                offset: Float = 6) -> [SIMD2<Float>] {
        
        let points = self.getSpecificFaceIndices(indices: indices)
        let normalizedPoints = self.getNoramlizePoint(points: points)
        
        let texWidth = Float(imageSize.width)
        let texHeight = Float(imageSize.height)
        
        let simdPoints1: [SIMD2<Float>] = normalizedPoints.map {
            SIMD2(Float($0.x), Float($0.y))
        }
        
        let shiftedPoints = self.shiftJawPointsDown(jawPoints: simdPoints1, offset: offset)
        
        let simdPoints: [SIMD2<Float>] = shiftedPoints.map {
            SIMD2(Float($0.x) / texWidth, Float($0.y) / texHeight)
        }
        
        return simdPoints
    }

    
    mutating func applyEyelashesFilter(image: MTIImage) -> MTIImage {
        let filter = EyelashMetalFilterV2()
        
        filter.scaleFactor = eyelashFilterModel.scaleFactor
        filter.rightPoints = eyelashFilterModel.rightEyeUpIndices
        filter.leftPoints = eyelashFilterModel.leftEyeUpIndices
        filter.inputImage = image
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
}

//MARK: - Nose Tune Filter
extension FaceTuneFilterModelV2 {
    mutating func updateNoseFilterModel() {
        let nosePoints: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.noseIndices)
        
        let boundaryP: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.boundary)
        //let sortedPoints = nosePoints.sorted { $0.x < $1.x } // left → right
        let normalizedPoint = self.getNoramlizePoint(points: nosePoints)
        let normalizedPoint1 = self.getNoramlizePoint(points: boundaryP)
        
        let simdPoints: [SIMD2<Float>] = normalizedPoint1.map { point in
            SIMD2(Float(point.x) / Float(imageSize.width),
                  Float(point.y) / Float(imageSize.height))
        }
        
        debugPrint("normalizedPoint ----- NN", normalizedPoint, normalizedPoint1, simdPoints)
        
        let (noseCenterUV, noseRadiusXY) = self.createCenterAndRadius(imageSize: self.imageSize,
                                                                      points: normalizedPoint)
        
        self.noseFilterModel.noseCenter = noseCenterUV
        self.noseFilterModel.noseRadius = noseRadiusXY
        self.noseFilterModel.scaleFactor = 0
        self.noseFilterModel.nosePointsFloat = simdPoints
        
    }
    
    func createCenterAndRadius(imageSize: CGSize, points: [CGPoint], padding: CGFloat = 0) -> (center: SIMD2<Float>, radiusXY: SIMD2<Float>) {
        
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
        
        return (centerUV, radiusUV)
    }
    
    mutating func applyNoseFilter(image: MTIImage) -> MTIImage {
        
        let filter = NoseMetalFilterV2()
        
        filter.noseScaleFactor = Float(self.noseFilterModel.scaleFactor)
        filter.inputImage = image
        filter.noseCenter = self.noseFilterModel.noseCenter
        filter.noseRadiusXY = self.noseFilterModel.noseRadius
        filter.point = self.noseFilterModel.nosePointsFloat
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
}

//MARK: - Cheeeks Filter
extension FaceTuneFilterModelV2 {
    mutating func updateFaceCheeksFilter() {
        self.jawFilterModel.scaleFactor = 0.0
        // Convert to Set
        let faceOvalSet = Set(FaceParsingIndex.faceOvalIndices)
        let cheeksSet = Set(FaceParsingIndex.cheeksIndices)

        // Intersection = common indices
        let commonIndices = [58, 136, 148, 149, 150, 152, 172, 176, 288, 365, 379, 378, 377, 397, 400]

        let faceOveralPoints: [CGPoint] = self.getSpecificFaceIndices(indices: commonIndices)
        let sortedPoints = faceOveralPoints.sorted { $0.x < $1.x } // left → right
        let normalizedPoint = self.getNoramlizePoint(points: sortedPoints)
        
        let simdPoints: [SIMD2<Float>] = normalizedPoint.map { point in
            SIMD2(Float(point.x) / Float(imageSize.width),
                  Float(point.y) / Float(imageSize.height))
        }
        debugPrint("updateFaceCheeksFilter",normalizedPoint,faceOveralPoints,FaceParsingIndex.faceOvalIndices, FaceParsingIndex.cheeksIndices)
        let texWidth  = Float((self.imageSize.width))
        let texHeight = Float((self.imageSize.height))
        
        //self.jawFilterModel.smoothCurveFast = simdPoints
        
        self.jawFilterModel.jawPoints = sortedPoints
        self.jawFilterModel.scaleFactor = 0.0
        
        let chinCenters = computeSmoothChinCurveFast(points: normalizedPoint, imageSize: self.imageSize)
        
        //var count = UInt32(chinCenters.count)
        //var lineWidthNormalized: Float = 15.0 / Float(imageSize.width)
        
        let center = self.computeJawCenter(jawPoints: normalizedPoint, samplesPerSegment: 4)
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
}

//FaceProportion Filter
extension FaceTuneFilterModelV2 {
    mutating func updateFaceProportionFilter() {
        self.faceProportionFilter.scaleFactor = 0.0
        let faceOveralPoints: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.faceOvalIndices)
        let normalizedPoint = self.getNoramlizePoint(points: faceOveralPoints)
        
        let simdPoints: [SIMD2<Float>] = normalizedPoint.map { point in
            SIMD2(Float(point.x) / Float(imageSize.width),
                  Float(point.y) / Float(imageSize.height))
        }
       // let polygonImg = self.polygonMaskImage(points: normalizedPoint, size: self.imageSize)
        
        //let image = CIImage(cgImage: polygonImg!.cgImage!)
        
        debugPrint("Pintssss",normalizedPoint,faceOveralPoints,FaceParsingIndex.faceOvalIndices)
        
        
        let center = self.polygonCenter(points: normalizedPoint)
        let radius = self.polygonMaxRadius(points: normalizedPoint, center: center)
        //let maxRadius = self.maxDistance(points: normalizedPoint, center: center)
        
        let texWidth  = Float((self.imageSize.width))
        let texHeight = Float((self.imageSize.height))
        
        

        let faceCenter = SIMD2<Float>(
            Float(center.x / texWidth),
            Float(center.y / texHeight) // flip Y
        )

        let faceRadius = SIMD2<Float>(
            Float(radius / texWidth),
            Float(radius / texWidth)
        )
        self.faceProportionFilter.faceCenter = faceCenter
        self.faceProportionFilter.faceRadius = faceRadius
        self.faceProportionFilter.rotation = 0.0
        self.faceProportionFilter.smoothCurveFast = simdPoints
    }
    
    mutating func applyFaceProportionFilter(image: MTIImage) -> MTIImage {
       
        let filter = FacePFilterV2()
        
        filter.faceScaleFactor = Float(self.faceProportionFilter.scaleFactor)
        filter.inputImage = image
        filter.faceRectCenter = self.faceProportionFilter.faceCenter
        filter.faceRectRadius = self.faceProportionFilter.faceRadius
        filter.rotation = self.faceProportionFilter.rotation
        filter.point = self.faceProportionFilter.smoothCurveFast
        
        debugPrint("Rotation----",self.faceProportionFilter.rotation)
        
        if let outputImage = filter.outputImage {
            return outputImage
        }
        return image
    }
    
    func polygonBounds(points: [CGPoint]) -> (min: SIMD2<Float>, max: SIMD2<Float>) {
        guard let first = points.first else { return (SIMD2<Float>(0,0), SIMD2<Float>(0,0)) }
        var minPoint = SIMD2<Float>(Float(first.x), Float(first.y))
        var maxPoint = minPoint
        
        for p in points {
            let sp = SIMD2<Float>(Float(p.x), Float(p.y))
            minPoint = min(minPoint, sp)
            maxPoint = max(maxPoint, sp)
        }
        return (minPoint, maxPoint)
    }

    func polygonCenter(points: [CGPoint]) -> SIMD2<Float> {
        let (minPoint, maxPoint) = polygonBounds(points: points)
        return (minPoint + maxPoint) * 0.5
    }

    func polygonMaxRadius(points: [CGPoint], center: SIMD2<Float>) -> Float {
        var maxDist: Float = 0
        for p in points {
            let sp = SIMD2<Float>(Float(p.x), Float(p.y))
            let d = length(sp - center)
            maxDist = max(maxDist, d)
        }
        return maxDist
    }



    // Compute bounding box center, radius, roll
    /*func computeFaceWarpData(landmarks: [CGPoint],
                             imageSize: CGSize,
                             leftEyeIndices: [Int],
                             rightEyeIndices: [Int],
                             scaleFactor: Float) -> FaceWarpData? {
        guard !landmarks.isEmpty else { return nil }

        // Bounding box
        let minX = landmarks.map { $0.x }.min()!
        let maxX = landmarks.map { $0.x }.max()!
        let minY = landmarks.map { $0.y }.min()!
        let maxY = landmarks.map { $0.y }.max()!

        let center = SIMD2<Float>(
            Float((minX + maxX)/2) / Float(imageSize.width),
            Float((minY + maxY)/2) / Float(imageSize.height)
        )

        var radius = SIMD2<Float>(
            Float((maxX - minX)/2) / Float(imageSize.width),
            Float((maxY - minY)/2) / Float(imageSize.height)
        )

        // Add margin for forehead & chin
        radius.x *= 1.2
        radius.y *= 1.5

        // Eye centers
        let leftEyeCenter = eyeCenter(from: landmarks, indices: leftEyeIndices)
        let rightEyeCenter = eyeCenter(from: landmarks, indices: rightEyeIndices)

      

        return FaceWarpData(center: center, radius: radius, rotation: roll, scaleFactor: scaleFactor)
    }*/

}

extension FaceTuneFilterModelV2 {
    mutating func applyLipsFilter(image: MTIImage) -> MTIImage {
        
        let lipsFilter = LipsMetalFilterV2()
        lipsFilter.inputImage = image
        lipsFilter.lipCenter = SIMD2<Float>(Float(self.lipsFilterModel.outerLipscenter.x / self.imageSize.width),
                                            Float(self.lipsFilterModel.outerLipscenter.y / self.imageSize.height))
        lipsFilter.lipRadiusXY =  SIMD2<Float>(Float(self.lipsFilterModel.lipsRadius.x / self.imageSize.width),
                                               Float(self.lipsFilterModel.lipsRadius.y / self.imageSize.height))
        
        lipsFilter.lipScaleFactor = Float(self.lipsFilterModel.scaleFactor) // positive = enlarge, negative = shrink*/
        if let outputImage = lipsFilter.outputImage {
            return outputImage
        }
        
        return image
    }
    
    mutating func updateLipsFilter() {
        
        let outerLipsPoint: [CGPoint] = self.getSpecificFaceIndices(indices: FaceParsingIndex.outerLipsPoints)
        let normalizedPoint = self.getNoramlizePoint(points: outerLipsPoint)
        
        let (outerLipsCenter, outerLipsRadiusX, outerLipsRadiusY) = calculateLipEllipse(points: normalizedPoint)
        
        self.lipsFilterModel.outerLipsPoints = outerLipsPoint
        self.lipsFilterModel.scaleFactor = 0.0
        self.lipsFilterModel.outerLipscenter = outerLipsCenter
        self.lipsFilterModel.lipsRadius.x = outerLipsRadiusX 
        self.lipsFilterModel.lipsRadius.y = outerLipsRadiusY
    }
    
    func calculateLipEllipse(points: [CGPoint]) -> (center: CGPoint, radiusX: CGFloat, radiusY: CGFloat) {
        guard !points.isEmpty else { return (CGPoint.zero, 0, 0) }

        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 0
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 0

        let center = CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        let radiusX = (maxX - minX) / 2
        let radiusY = (maxY - minY) / 2

        return (center, radiusX, radiusY)
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
    
    func polygonMaskImage(points: [CGPoint], size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        ctx.setFillColor(UIColor.white.cgColor) // inside polygon → white
        ctx.setStrokeColor(UIColor.clear.cgColor)

        // Start drawing polygon
        ctx.beginPath()
        if let first = points.first {
            ctx.move(to: first)
            for p in points.dropFirst() {
                ctx.addLine(to: p)
            }
            ctx.closePath()
        }
        ctx.fillPath()

        let maskImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return maskImage
    }

}
