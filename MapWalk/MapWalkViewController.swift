//
//  MapWalkViewController.swift
//  MapWalkSwift
//
//  Created by MyMac on 12/09/23.
//

import UIKit
import CoreLocation
import MapKit

enum PencilType {
    case Avoid
    case Pretty
    case Shop
    case None
}

class MapWalkViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnMapType: UIButton!
    @IBOutlet weak var btnAvoid: UIButton!
    
    @IBOutlet weak var imgAvoidPen: UIImageView!
    @IBOutlet weak var imgPrettyPen: UIImageView!
    @IBOutlet weak var imgShopPen: UIImageView!
    
    let blueColor = UIColor(red: 41.0/255.0, green: 74.0/255.0, blue: 241.0/255.0, alpha: 1.0)
    let redColor = UIColor(red: 245.0/255.0, green: 85.0/255.0, blue: 70.0/255.0, alpha: 1.0)
    let greenColor = UIColor(red: 46.0/255.0, green: 197.0/255.0, blue: 25.0/255.0, alpha: 1.0)
    let grayColor = UIColor(red: 142.0/255.0, green: 141.0/255.0, blue: 146.0/255.0, alpha: 1.0)
    
    var selectedPencilType = PencilType.None
    
    var currentMapType: MKMapType = .standard {
        didSet {
            // Update the map type
            mapView.mapType = currentMapType
            
            // Update the button image based on the map type
            if currentMapType == .standard {
                btnMapType.setImage(UIImage(systemName: "map.fill"), for: .normal)
            } else {
                btnMapType.setImage(UIImage(systemName: "globe"), for: .normal)
            }
        }
    }
    
    private var coordinates: [CLLocationCoordinate2D] = []
    private var isDrawingPolygon: Bool = false
    private var canvasView: CanvasView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        self.currentMapType = .satellite
        // Request location permission if needed
        LocationManager.shared.requestLocationPermission()
        
        // Set up location updates handler
        LocationManager.shared.locationUpdateHandler = { [weak self] location in
            // Use the updated location for your map
            self?.updateMap(with: location)
        }
    }
    
    func updateMap(with location: CLLocation) {
        // Update your map view with the location data
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        
        // Optionally, you can set a title and subtitle for the annotation.
        annotation.title = "Current Location"
        
        // Clear existing annotations and add the new one.
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        
        // Optionally, you can set the map's region to focus on the updated location.
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }

    @IBAction func btnMapTypeAction(_ sender: Any) {
        // Toggle between map types when the button is tapped
        if currentMapType == .standard {
            currentMapType = .satellite
        } else {
            currentMapType = .standard
        }
    }
    
    @IBAction func btnAvoidAction(_ sender: Any) {
        self.selectedPencilType = .Avoid
        self.startEndDragging()
    }
    
    @IBAction func btnPrettyAction(_ sender: Any) {
        self.selectedPencilType = .Pretty
        self.startEndDragging()
    }
    
    @IBAction func btnShopAction(_ sender: Any) {
        self.selectedPencilType = .Shop
        self.startEndDragging()
    }
    
    func startEndDragging() {
        if isDrawingPolygon == false {
            isDrawingPolygon = true
            coordinates.removeAll()
            canvasView = CanvasView(frame: mapView.frame)
            if self.selectedPencilType == .Avoid {
                canvasView.selectedColor = self.redColor
            }
            else if self.selectedPencilType == .Pretty {
                canvasView.selectedColor = self.blueColor
            }
            else if self.selectedPencilType == .Shop {
                canvasView.selectedColor = self.greenColor
            }
            canvasView.isUserInteractionEnabled = true
            canvasView.delegate = self
            view.addSubview(canvasView)
        } else {
            let numberOfPoints = coordinates.count

            if numberOfPoints > 2 {
                var points: [CLLocationCoordinate2D] = []
                for i in 0..<numberOfPoints {
                    points.append(coordinates[i])
                }
                mapView.addOverlay(MKPolygon(coordinates: &points, count: numberOfPoints))
            }

            isDrawingPolygon = false
            canvasView.image = nil
            canvasView.removeFromSuperview()
            self.selectedPencilType = .None
        }
        self.setImageTintColor()
    }
    
    @IBAction func btnCurrentLocationAction(_ sender: Any) {
        LocationManager.shared.hasReceivedInitialLocation = false
        LocationManager.shared.startUpdatingLocation()
    }
    
    func setImageTintColor() {
        self.imgAvoidPen.tintColor = self.selectedPencilType == .Avoid ? self.redColor : self.grayColor
        self.imgPrettyPen.tintColor = self.selectedPencilType == .Pretty ? self.blueColor : self.grayColor
        self.imgShopPen.tintColor = self.selectedPencilType == .Shop ? self.greenColor : self.grayColor
    }
    
    //MARK: - Touch methods
    func touchesBegan(_ touch: UITouch) {
        let location = touch.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        coordinates.append(coordinate)
    }

    func touchesMoved(_ touch: UITouch) {
        let location = touch.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        coordinates.append(coordinate)
    }

    func touchesEnded(_ touch: UITouch) {
        let location = touch.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        coordinates.append(coordinate)
        self.startEndDragging()
    }
}

extension MapWalkViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygon = overlay as? MKPolygon {
            let overlayPathView = MKPolygonRenderer(polygon: polygon)
            if self.selectedPencilType == .Avoid {
                overlayPathView.fillColor = self.redColor.withAlphaComponent(0.2)
                overlayPathView.strokeColor = self.redColor.withAlphaComponent(0.7)
            }
            else if self.selectedPencilType == .Pretty {
                overlayPathView.fillColor = self.blueColor.withAlphaComponent(0.2)
                overlayPathView.strokeColor = self.blueColor.withAlphaComponent(0.7)
            }
            else if self.selectedPencilType == .Shop {
                overlayPathView.fillColor = self.greenColor.withAlphaComponent(0.2)
                overlayPathView.strokeColor = self.greenColor.withAlphaComponent(0.7)
            }
            else {
                overlayPathView.fillColor = UIColor.cyan.withAlphaComponent(0.2)
                overlayPathView.strokeColor = UIColor.blue.withAlphaComponent(0.7)
            }
            overlayPathView.lineWidth = 2.5
            return overlayPathView
        }
        else if let polyline = overlay as? MKPolyline {
            let overlayPathView = MKPolylineRenderer(polyline: polyline)
            overlayPathView.strokeColor = UIColor.blue.withAlphaComponent(0.7)
            overlayPathView.lineWidth = 2.5
            return overlayPathView
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return nil
        /*if annotation is MKUserLocation {
            return nil
        }

        let annotationIdentifier = "CustomAnnotation"

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)

        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.image = UIImage(systemName: "location.north.circle.fill")
            annotationView?.alpha = 1
        } else {
            annotationView?.annotation = annotation
        }

        annotationView?.canShowCallout = true
        
        return annotationView*/
    }
}
