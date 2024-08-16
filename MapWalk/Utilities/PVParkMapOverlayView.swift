//
//  PVParkMapOverlayView.swift
//  TimeWalk
//
//  Created by MyMac on 23/10/23.
//

import UIKit
import MapKit

//class PVParkMapOverlayView: MKOverlayRenderer {
//    private var overlayImage: UIImage
//    
//    init(overlay: MKOverlay, overlayImage: UIImage) {
//        self.overlayImage = overlayImage
//        super.init(overlay: overlay)
//    }
//    
//    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
//        let imageReference = overlayImage.cgImage
//
//        let theMapRect = overlay.boundingMapRect
//        let theRect = rect(for: theMapRect)
//        
//        context.scaleBy(x: 1.0, y: -1.0)
//        context.translateBy(x: 0.0, y: -theRect.size.height)
//        context.draw(imageReference!, in: theRect)
//    }
//}

//class PVParkMapOverlayView: MKOverlayRenderer {
//    private var overlayImage: UIImage
//    var imageTransform: CGAffineTransform = .identity
//
//    init(overlay: MKOverlay, overlayImage: UIImage) {
//        self.overlayImage = overlayImage
//        super.init(overlay: overlay)
//    }
//    
//    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
//        let imageReference = overlayImage.cgImage
//        let theMapRect = overlay.boundingMapRect
//        let theRect = rect(for: theMapRect)
//        
//        // Apply transformations
//        context.saveGState()
//        context.concatenate(imageTransform)
//        
//        // Draw the image
//        context.scaleBy(x: 1.0, y: -1.0)
//        context.translateBy(x: 0.0, y: -theRect.size.height)
//        context.draw(imageReference!, in: theRect)
//        
//        context.restoreGState()
//    }
//    
//    func applyTransform(_ transform: CGAffineTransform) {
//        imageTransform = transform
//        setNeedsDisplay()
//    }
//    
//}

class PVParkMapOverlayView: MKOverlayRenderer {
    private var overlayImage: UIImage
    private var currentBoundingMapRect: MKMapRect
    private var originalBounds: CGRect
    public var imageTransform: CGAffineTransform = .identity


    init(overlay: MKOverlay, overlayImage: UIImage) {
        self.overlayImage = overlayImage
        self.currentBoundingMapRect = overlay.boundingMapRect
        self.overlayImage = overlayImage
        self.currentBoundingMapRect = overlay.boundingMapRect
        self.originalBounds = CGRect(x: 0, y: 0, width: overlayImage.size.width, height: overlayImage.size.height)
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let imageReference = self.overlayImage.cgImage
        let theRect = self.rect(for: self.currentBoundingMapRect)
        
        // Apply transformations
        context.saveGState()
        context.concatenate(self.imageTransform)
        
        // Draw the image
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -theRect.size.height)
        context.draw(imageReference!, in: theRect)
        context.restoreGState()
    }

    func applyTransform(_ transform: CGAffineTransform) {
        self.imageTransform = transform
        self.setNeedsDisplay()
    }
}


extension PVParkMapOverlayView {
    var overlayCenter: CGPoint {
        let mapRect = self.overlay.boundingMapRect
        let rect = self.rect(for: mapRect)
        return CGPoint(x: rect.midX, y: rect.midY)
    }
}

