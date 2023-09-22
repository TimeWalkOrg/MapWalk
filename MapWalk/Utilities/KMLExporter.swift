//
//  KMLExporter.swift
//  MapWalk
//
//  Created by MyMac on 22/09/23.
//

import Foundation
import MapKit

class KMLExporter {
    static func generateKML(from overlays: [MKOverlay]) -> String {
        var kmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
        <Document>
        """
        
        for overlay in overlays {
            if let polyline = overlay as? MKPolyline {
                kmlString += """
                <Placemark>
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
            } else if let polygon = overlay as? MKPolygon {
                kmlString += """
                <Placemark>
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


