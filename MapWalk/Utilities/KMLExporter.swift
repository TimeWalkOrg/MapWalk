//
//  KMLExporter.swift
//  MapWalk
//
//  Created by MyMac on 22/09/23.
//

import Foundation
import MapKit

class KMLExporter {
    static func generateKML(from overlays: [MKOverlay], mapView: MKMapView) -> String {
        var kmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
        """
        
        for overlay in overlays {
            if let polyline = overlay as? MapPolyline {
                let overlayPathView = mapView.renderer(for: polyline) as? MKPolylineRenderer
                //let strokeWidth = overlayPathView?.lineWidth ?? 1.0
                var strokeColor = ""
                if polyline.overlay?.color == "red" {
                    //strokeColor = AppColors.redColor.withAlphaComponent(0.7).hexString()
                    strokeColor = "fff14a29"
                }
                else if polyline.overlay?.color == "blue" {
                    strokeColor = "ff4655f5"
                    //strokeColor = AppColors.blueColor.withAlphaComponent(0.7).hexString()
                }
                else if polyline.overlay?.color == "green" {
                    strokeColor = "ff19c52d"
                    //strokeColor = AppColors.greenColor.withAlphaComponent(0.7).hexString()
                }
                else {
                    strokeColor = UIColor.blue.withAlphaComponent(0.7).hexString()
                }
                
                kmlString += """
                <Placemark>
                    <Style>
                        <LineStyle>
                            <color>\(strokeColor)</color>
                            <width>6</width>
                        </LineStyle>
                    </Style>
                    <LineString>
                        <coordinates>
                """
                
                for i in 0..<polyline.pointCount {
                    let point = polyline.points()[i]
                    kmlString += "\(point.coordinate.longitude),\(point.coordinate.latitude),0 "
                }
                
                kmlString += """
                        </coordinates>
                    </LineString>
                </Placemark>
                """
            } else if let polygon = overlay as? MapPolygon {
                let overlayPathView = mapView.renderer(for: polygon) as? MKPolygonRenderer
                //let strokeWidth = overlayPathView?.lineWidth ?? 1.0
                var strokeColor = ""
                var fillColor = ""
                if polygon.overlay?.color == "red" {
                    strokeColor = "fff14a29"//AppColors.redColor.withAlphaComponent(0.2).hexString()
                    fillColor = "40f14a29"//AppColors.redColor.withAlphaComponent(0.7).hexString()
                }
                else if polygon.overlay?.color == "blue" {
                    strokeColor = "ff4655f5"//AppColors.blueColor.withAlphaComponent(0.2).hexString()
                    fillColor = "404655f5"//AppColors.blueColor.withAlphaComponent(0.7).hexString()
                }
                else if polygon.overlay?.color == "green" {
                    strokeColor = "ff19c52d"
                    fillColor = "4019c52d"
                    //strokeColor = AppColors.greenColor.withAlphaComponent(0.2).hexString()
                    //fillColor = AppColors.greenColor.withAlphaComponent(0.7).hexString()
                }
                else {
                    fillColor = UIColor.cyan.withAlphaComponent(0.2).hexString()
                    strokeColor = UIColor.blue.withAlphaComponent(0.7).hexString()
                }
                
                kmlString += """
                <Placemark>
                    <Style>
                        <LineStyle>
                            <color>\(strokeColor)</color>
                            <width>4</width>
                        </LineStyle>
                        <PolyStyle>
                            <color>\(fillColor)</color>
                        </PolyStyle>
                    </Style>
                    <Polygon>
                        <outerBoundaryIs>
                            <LinearRing>
                                <coordinates>
                """
                
                for i in 0..<polygon.pointCount {
                    let point = polygon.points()[i]
                    kmlString += "\(point.coordinate.longitude),\(point.coordinate.latitude),0 "
                }
                
                kmlString += """
                                </coordinates>
                            </LinearRing>
                        </outerBoundaryIs>
                    </Polygon>
                </Placemark>
                """
            }
        }
        
        kmlString += """
        </Document>
        </kml>
        """
        
        return kmlString
    }
}

extension UIColor {
    func hexString() -> String {
        guard let components = self.cgColor.components else {
            return ""
        }
        
        let red = Int(components[0] * 255.0)
        let green = Int(components[1] * 255.0)
        let blue = Int(components[2] * 255.0)
        let alpha = Int(components[3] * 255.0)
        
        return String(format: "%02X%02X%02X%02X", alpha, red, green, blue)
    }
}
