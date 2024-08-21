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
    public var currentBoundingMapRect: MKMapRect
    public var imageTransform: CGAffineTransform = .identity


    init(overlay: MKOverlay, overlayImage: UIImage) {
        let fixedImage = overlayImage.flip(flipVertically: true, flipHorizontally: false)
        self.overlayImage = fixedImage
        
        //Calculate Cordinates and convert it to the MKMapRect to set into the word sized PVParkMapOverlay
        let mapImageOverlay = (overlay as? PVParkMapOverlay)!.mapImageOverlay
        let topLeft = MKMapPoint(mapImageOverlay.overlayTopLeftCoord!.toCoordinate())
        let topRight = MKMapPoint(mapImageOverlay.overlayTopRightCoord!.toCoordinate())
        let bottomLeft = MKMapPoint(mapImageOverlay.overlayBottomLeftCoord!.toCoordinate())
        let mapRect = MKMapRect(origin: MKMapPoint(x: topLeft.x, y: topLeft.y), size: MKMapSize(width: fabs(topLeft.x - topRight.x), height: fabs(topLeft.y - bottomLeft.y)))
        
        self.currentBoundingMapRect = mapRect
        super.init(overlay: overlay)
    }
    
   override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let imageReference = self.overlayImage.cgImage else { return }

        // Calculate the rectangle where the image will be drawn
        let imageRect = self.rect(for: self.currentBoundingMapRect)

        // Save the current context state
        context.saveGState()
        context.clip()
        context.translateBy(x: imageRect.midX, y: imageRect.midY)
        context.concatenate(self.imageTransform)
        context.translateBy(x: -imageRect.midX, y: -imageRect.midY)
        context.draw(imageReference, in: imageRect)
        context.restoreGState()
    }

    func getCoordinates() -> Coordinates {
        let mapRect = self.currentBoundingMapRect
        
        // Calculate the center point
        let centerPoint = MKMapPoint(x: mapRect.midX, y: mapRect.midY)
        let centerCoordinate = centerPoint.coordinate
        
        // Calculate the corner points
        let topLeftPoint = MKMapPoint(x: mapRect.minX, y: mapRect.minY)
        let topRightPoint = MKMapPoint(x: mapRect.maxX, y: mapRect.minY)
        let bottomLeftPoint = MKMapPoint(x: mapRect.minX, y: mapRect.maxY)
        let bottomRightPoint = MKMapPoint(x: mapRect.maxX, y: mapRect.maxY)
        
        // Convert map points to geographic coordinates
        let topLeftCoordinate = topLeftPoint.coordinate
        let topRightCoordinate = topRightPoint.coordinate
        let bottomLeftCoordinate = bottomLeftPoint.coordinate
        let bottomRightCoordinate = bottomRightPoint.coordinate
        
        // Return the tuple with all coordinates
        return (
            center: centerCoordinate,
            topLeft: topLeftCoordinate,
            topRight: topRightCoordinate,
            bottomLeft: bottomLeftCoordinate,
            bottomRight: bottomRightCoordinate
        )
    }

    func applyTransform(_ transform: CGAffineTransform) {
        self.imageTransform = transform
        self.setNeedsDisplay()
    }
}

// MARK: - Coordinates
typealias Coordinates = (center: CLLocationCoordinate2D, topLeft: CLLocationCoordinate2D, topRight: CLLocationCoordinate2D, bottomLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D)
