//
//  FirebaseFactune + Ext.swift
//  MultipleImageBlendUsingMetal
//
//  Created by BCL Device 8 on 10/9/25.
//


import UIKit
import Foundation


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
                let dotRect = CGRect(
                    x: dot.x - DefaultConstants.pointRadius / 2,
                    y: dot.y - DefaultConstants.pointRadius / 2,
                    width: DefaultConstants.pointRadius,
                    height: DefaultConstants.pointRadius
                )
                //let path = UIBezierPath(ovalIn: dotRect)
                //DefaultConstants.pointFillColor.setFill()
                //DefaultConstants.pointColor.setStroke()
                //path.stroke()
                //path.fill()
                
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
            /*for lineConnection in faceOverlay.lineConnections {
             let path = UIBezierPath()
             for line in lineConnection.lines {
             path.move(to: line.from)
             path.addLine(to: line.to)
             }
             path.lineWidth = DefaultConstants.lineWidth
             lineConnection.color.setStroke()
             path.stroke()
             }*/
        }
    }
}
