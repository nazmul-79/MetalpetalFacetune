//
//  Transformableview.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 4/8/25.
//

import UIKit
import MetalPetal

class TransformableView: UIView {

    private var panGesture: UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!
    private var rotationGesture: UIRotationGestureRecognizer!
    private var currentTransform: CGAffineTransform = .identity
    
    public var imageView: MTIImageView? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
        self.isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
        self.isUserInteractionEnabled = true
        
    }

    private func setupGestures() {
        // Move
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(panGesture)

        // Zoom
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        self.addGestureRecognizer(pinchGesture)

        // Rotate
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        self.addGestureRecognizer(rotationGesture)

        // Allow simultaneous gesture recognition
        panGesture.delegate = self
        pinchGesture.delegate = self
        rotationGesture.delegate = self
        self.imageView = MTIImageView(frame: self.bounds)
        self.imageView?.isUserInteractionEnabled = false
        if let imageView = self.imageView {
            self.addSubview(imageView)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        if gesture.state == .began || gesture.state == .changed {
            self.center = CGPoint(x: self.center.x + translation.x,
                                  y: self.center.y + translation.y)
            gesture.setTranslation(.zero, in: self.superview)
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            self.transform = self.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
        }
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            self.transform = self.transform.rotated(by: gesture.rotation)
            gesture.rotation = 0.0
        }
    }
}

extension TransformableView {
   // extension TransformableView {
        func currentTransformValues() -> (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, rotation: CGFloat) {
            // 1. Read transform matrix
            let t = self.transform

            let transformedFrame = self.convert(self.bounds, to: superview)

            let actualX = transformedFrame.origin.x
            let actualY = transformedFrame.origin.y
            
           
            // 3. Extract scale (magnitude from matrix)
            let scaleX = sqrt(t.a * t.a + t.c * t.c)
            let scaleY = sqrt(t.b * t.b + t.d * t.d)

            // 4. Extract rotation in radians
            let rotation = atan2(t.b, t.a)

            // 5. Apply scale to base size
            let baseWidth = self.bounds.width
            let baseHeight = self.bounds.height
            let actualWidth = baseWidth * scaleX
            let actualHeight = baseHeight * scaleY
            
            let valueX  = self.center.x - (actualWidth * 0.5)
            let valueY  = self.center.y - (actualHeight * 0.5)
            
            let actualWidth1 = transformedFrame.size.width
            let actualHeight1 = transformedFrame.size.height

            return (
                x: valueX,
                y: valueY,
                width: actualWidth,
                height: actualHeight,
                rotation: rotation
            )
        }
    //}

}

//MARK: - UIGestureRecognizerDelegate
extension TransformableView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true // allow pinch + rotate + pan together
    }
}
