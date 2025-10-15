//
//  FaceTuneModel.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 14/8/25.
//


enum JawOption: String, CaseIterable {
    case slim = "Slim"
    case width = "Width"
    case temples = "Temples"
    case checkbones = "Checkbones"
    case jaw = "Jaw"
    case vShape = "V Shape"
    case chin = "Chin"
    case forhead = "Forhead"
    case top = "Top"
    case upper = "Upper"
    case lower = "Lower"
    case middle = "Middle"
}

enum ShapeOption: String, CaseIterable {
    case facialProportion = "Facial Proportion"
    case eyes = "Eyes"
    case nose = "Nose"
    case lips = "Lips"
    case cheeks = "Cheeks"
    case eyeBrow = "Eye Brow"
}

enum Looks: String, CaseIterable {
    case eyeLashesh = "Eye Lashesh"
    case eyeContrast = "Eye Contrast"
    case EyeBrows = "Eye Brows"
    case brighterLips = "Brighter Lips"
    case teethWhitening = "Teeth Whitening"
    case shadow = "Shadow"
    case highlights = "Highlights"
    case neeckShadow = "Neck Shadow"
}

enum Skin: String, CaseIterable {
    case skintone  = "Skintone"
    case blemishes  = "Blemishes"
    case faceMatte = "Face Matte"
}

enum NoseOption: String, CaseIterable {
    case size = "Size"
    case width = "Width"
    case tip = "Tip"
    case wing = "Wing"
    case bridge = "Bridge"
    case lift = "Lift"
}

enum EyeOption: String, CaseIterable {
    case size = "Size"
    case lift = "Lift"
    case distance = "Distance"
    case height = "Height"
    case width = "Width"
    case tilt = "Tilt"
    case pupil = "Pupil"
    case tail = "Tail"
    case innerCorner = "Inner Corner"
    case outerCorner = "Outer Corner"
    case lowerEyelid = "Lower Eyelid"
}

enum EyeBrowOption: String, CaseIterable {
    case thickNess = "Thickness"
    case lenght = "Lenght"
    case lift = "Lift"
    case peak = "Peak"
    case tilt = "Tilt"
    case distance = "Distance"
    case inner = "Inner"
}

enum FeatureCategory: String, CaseIterable {
    case Skin = "Skin"
    case Shape = "Shape"
    case Look = "Look"
}

let featureOptions: [FeatureCategory: [Any]] = [
    .Skin: Skin.allCases,
    .Shape: ShapeOption.allCases,
    .Look: Looks.allCases,
]
