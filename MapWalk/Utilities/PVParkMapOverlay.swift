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

    init(mapImageOverlay: MapImageOverlays) {
        let bottomLeftCord = mapImageOverlay.overlayBottomLeftCoord!.toCoordinate().latitude
        let TopRightCord = mapImageOverlay.overlayTopRightCoord!.toCoordinate().latitude
        let topLeft = MKMapPoint(mapImageOverlay.overlayTopLeftCoord!.toCoordinate())
        let topRight = MKMapPoint(mapImageOverlay.overlayTopRightCoord!.toCoordinate())
        let bottomLeft = MKMapPoint(mapImageOverlay.overlayBottomLeftCoord!.toCoordinate())
        
        boundingMapRect = MKMapRect(origin: MKMapPoint(x: topLeft.x, y: topLeft.y),
                                    size: MKMapSize(width: fabs(topLeft.x - topRight.x), height: fabs(topLeft.y - bottomLeft.y)))
        coordinate = mapImageOverlay.midCoord?.toCoordinate() ?? kCLLocationCoordinate2DInvalid
    }
}
