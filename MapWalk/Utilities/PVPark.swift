//
//  PVPark.swift
//  TimeWalk
//
//  Created by MyMac on 23/10/23.
//

import Foundation
import MapKit

class PVPark {
    var boundary: UnsafeMutablePointer<CLLocationCoordinate2D>?
    var boundaryPointsCount: Int = 0
    var midCoordinate: CLLocationCoordinate2D
    var overlayTopLeftCoordinate: CLLocationCoordinate2D
    var overlayTopRightCoordinate: CLLocationCoordinate2D
    var overlayBottomLeftCoordinate: CLLocationCoordinate2D

    var name: String?

    init(filename: String) {
        if let filePath = Bundle.main.path(forResource: filename, ofType: "plist"),
           let properties = NSDictionary(contentsOfFile: filePath) as? [String: Any] {
            if let midPoint = properties["midCoord"] as? String {
                let midPointNew = NSCoder.cgPoint(for: midPoint)
                midCoordinate = CLLocationCoordinate2DMake(CLLocationDegrees(midPointNew.x), CLLocationDegrees(midPointNew.y))
            } else {
                midCoordinate = kCLLocationCoordinate2DInvalid
            }

            if let overlayTopLeftPoint = properties["overlayTopLeftCoord"] as? String {
                let overlayTopLeftPointNew = NSCoder.cgPoint(for: overlayTopLeftPoint)
                overlayTopLeftCoordinate = CLLocationCoordinate2DMake(CLLocationDegrees(overlayTopLeftPointNew.x), CLLocationDegrees(overlayTopLeftPointNew.y))
            } else {
                overlayTopLeftCoordinate = kCLLocationCoordinate2DInvalid
            }

            if let overlayTopRightPoint = properties["overlayTopRightCoord"] as? String {
                let overlayTopRightPointNew = NSCoder.cgPoint(for: overlayTopRightPoint)
                overlayTopRightCoordinate = CLLocationCoordinate2DMake(CLLocationDegrees(overlayTopRightPointNew.x), CLLocationDegrees(overlayTopRightPointNew.y))
            } else {
                overlayTopRightCoordinate = kCLLocationCoordinate2DInvalid
            }

            if let overlayBottomLeftPoint = properties["overlayBottomLeftCoord"] as? String {
                let overlayBottomLeftPointNew = NSCoder.cgPoint(for: overlayBottomLeftPoint)
                overlayBottomLeftCoordinate = CLLocationCoordinate2DMake(CLLocationDegrees(overlayBottomLeftPointNew.x), CLLocationDegrees(overlayBottomLeftPointNew.y))
            } else {
                overlayBottomLeftCoordinate = kCLLocationCoordinate2DInvalid
            }

            /*if let boundaryPoints = properties["boundary"] as? [String] {
                boundaryPointsCount = boundaryPoints.count
                boundary = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: boundaryPointsCount)
                
                for i in 0..<boundaryPointsCount {
                    let pointString = boundaryPoints[i]
                    let point = NSCoder.cgPoint(for: pointString)
                    boundary![i] = CLLocationCoordinate2DMake(CLLocationDegrees(point.x), CLLocationDegrees(point.y))
                }
            } else {
                boundary = nil
            }*/
        } else {
            midCoordinate = kCLLocationCoordinate2DInvalid
            overlayTopLeftCoordinate = kCLLocationCoordinate2DInvalid
            overlayTopRightCoordinate = kCLLocationCoordinate2DInvalid
            overlayBottomLeftCoordinate = kCLLocationCoordinate2DInvalid
        }
    }

    deinit {
        boundary?.deallocate()
    }
    
    var overlayBottomRightCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: overlayBottomLeftCoordinate.latitude, longitude: overlayTopRightCoordinate.longitude)
    }
    
//    var boundingMapRect: MKMapRect {
//        let topLeftPoint = MKMapPoint(boundingGridRect.origin.locationCoordinate)
//        let bottomRightPoint = MKMapPoint(boundingGridRect.extent.locationCoordinate)
//          
//        let size = MKMapSize(width: bottomRightPoint.x - topLeftPoint.x, height: bottomRightPoint.y - topLeftPoint.y)
//        let rect = MKMapRect(origin: topLeftPoint, size: size)
//        return rect
//    }
    
    var overlayBoundingMapRect: MKMapRect {
        let topLeft = MKMapPoint(overlayTopLeftCoordinate)
        let topRight = MKMapPoint(overlayTopRightCoordinate)
        let bottomLeft = MKMapPoint(overlayBottomLeftCoordinate)

        return MKMapRect(origin: MKMapPoint(x: topLeft.x, y: topLeft.y),
                         size: MKMapSize(width: fabs(topLeft.x - topRight.x), height: fabs(topLeft.y - bottomLeft.y)))
    }
}
