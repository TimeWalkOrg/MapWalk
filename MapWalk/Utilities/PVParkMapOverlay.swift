//
//  PVParkMapOverlay.swift
//  TimeWalk
//
//  Created by MyMac on 23/10/23.
//

import UIKit
import MapKit

//class PVParkMapOverlay: NSObject, MKOverlay {
//    var coordinate: CLLocationCoordinate2D
//    var boundingMapRect: MKMapRect
//
//    init(park: PVPark) {
//        boundingMapRect = park.overlayBoundingMapRect
//        coordinate = park.midCoordinate
//    }
//}

class PVParkMapOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var mapImageOverlay: MapImageOverlays

    init(mapImageOverlay: MapImageOverlays) {
        self.mapImageOverlay = mapImageOverlay
        
        let topLeft = MKMapPoint(mapImageOverlay.overlayTopLeftCoord!.toCoordinate())
        let topRight = MKMapPoint(mapImageOverlay.overlayTopRightCoord!.toCoordinate())
        let bottomLeft = MKMapPoint(mapImageOverlay.overlayBottomLeftCoord!.toCoordinate())
        let mapRect = MKMapRect(origin: MKMapPoint(x: topLeft.x, y: topLeft.y), size: MKMapSize(width: fabs(topLeft.x - topRight.x), height: fabs(topLeft.y - bottomLeft.y)))
      
        boundingMapRect = .world //mapRect
        coordinate = mapImageOverlay.coordinates?.toCoordinate() ?? kCLLocationCoordinate2DInvalid
    }
}
