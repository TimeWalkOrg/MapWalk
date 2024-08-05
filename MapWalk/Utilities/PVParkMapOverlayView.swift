//
//  PVParkMapOverlayView.swift
//  TimeWalk
//
//  Created by MyMac on 23/10/23.
//

import UIKit
import MapKit

class PVParkMapOverlayView: MKOverlayRenderer {
    private var overlayImage: UIImage
    
    init(overlay: MKOverlay, overlayImage: UIImage) {
        self.overlayImage = overlayImage
        super.init(overlay: overlay)
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let imageReference = overlayImage.cgImage

        let theMapRect = overlay.boundingMapRect
        let theRect = rect(for: theMapRect)
        
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -theRect.size.height)
        context.draw(imageReference!, in: theRect)
    }
}
