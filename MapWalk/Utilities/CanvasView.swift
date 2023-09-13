//
//  CanvasView.swift
//  MapWalkSwift
//
//  Created by MyMac on 13/09/23.
//

import Foundation
import UIKit

class CanvasView: UIImageView {
    weak var delegate: MapWalkViewController?
    private var location: CGPoint = .zero
    var selectedColor = UIColor.blue

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        delegate?.touchesBegan(touch)
        location = touch.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentLocation = touch.location(in: self)
        delegate?.touchesMoved(touch)

        UIGraphicsBeginImageContext(frame.size)
        if let ctx = UIGraphicsGetCurrentContext() {
            image?.draw(in: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
            ctx.setLineCap(.round)
            ctx.setLineWidth(2.5)
            ctx.setStrokeColor(selectedColor.withAlphaComponent(0.7).cgColor)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: location.x, y: location.y))
            ctx.addLine(to: CGPoint(x: currentLocation.x, y: currentLocation.y))
            ctx.strokePath()
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()

        location = currentLocation
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentLocation = touch.location(in: self)
        delegate?.touchesEnded(touch)

        UIGraphicsBeginImageContext(frame.size)
        if let ctx = UIGraphicsGetCurrentContext() {
            image?.draw(in: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
            ctx.setLineCap(.round)
            ctx.setLineWidth(2.5)
            ctx.setStrokeColor(selectedColor.withAlphaComponent(0.7).cgColor)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: location.x, y: location.y))
            ctx.addLine(to: CGPoint(x: currentLocation.x, y: currentLocation.y))
            ctx.strokePath()
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()

        location = currentLocation
    }
}
