//
//  PVParkMapOverlay.swift
//  TimeWalk
//
//  Created by MyMac on 23/10/23.
//

import UIKit
import MapKit

class PVParkMapOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect

    init(park: PVPark) {
        boundingMapRect = park.overlayBoundingMapRect
        coordinate = park.midCoordinate
    }
}
