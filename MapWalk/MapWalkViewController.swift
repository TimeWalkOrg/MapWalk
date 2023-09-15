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
    var allCoordinates: [[CLLocationCoordinate2D]] = []
    
    private var isDrawingPolygon: Bool = false
    private var canvasView: CanvasView!
    var currentMap: Map?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    func setupView() {
        let map = CoreDataManager.shared.getMap()
        if map.count == 0 {
            CoreDataManager.shared.saveMap(mapName: "MyMap", isMyMap: true)
            let myMaps = CoreDataManager.shared.getMap()
            self.currentMap = myMaps.last!
        }
        else {
            for myMap in map {
                if myMap.isMyMap == true {
                    self.currentMap = myMap
                    break
                }
            }
        }
        
        self.mapView.delegate = self
        
        // Request location permission if needed
        LocationManager.shared.requestLocationPermission()
        
        // Set up location updates handler
        LocationManager.shared.locationUpdateHandler = { [weak self] location in
            // Use the updated location for your map
            self?.updateMap(with: location)
        }
        
        self.loadOverlaysOnMap()
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

    func loadOverlaysOnMap() {
        // Load saved overlays of current map
        var overlays = CoreDataManager.shared.getOverlays()
        overlays = overlays.filter({$0.overlaysMap?.mapID == self.currentMap?.mapID})
        if overlays.count > 0 {
            for overlay in overlays {
                let coordinatesArray = self.convertJSONStringToCoordinates(jsonString: overlay.coordinates ?? "")
                
                let numberOfPoints = coordinatesArray.count
                
                if numberOfPoints > 2 {
                    var points: [CLLocationCoordinate2D] = []
                    for i in 0..<numberOfPoints {
                        points.append(coordinatesArray[i])
                    }
                    let polygon = MapPolygon(coordinates: &points, count: numberOfPoints)
                    polygon.overlay = overlay
                    mapView.addOverlay(polygon)
                }
            }
        }
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
        
    @IBAction func btnUndoAction(_ sender: Any) {
        var overlays = CoreDataManager.shared.getOverlays()
        overlays = overlays.filter({$0.overlaysMap?.mapID == self.currentMap?.mapID}).sorted(by: {$0.overlayID < $1.overlayID})
        
        if overlays.isEmpty {
            return
        }
        
        let overlayToDelete = overlays.last
        CoreDataManager.shared.deleteOverlay(overlayID: overlayToDelete?.overlayID ?? 0)
        
        DispatchQueue.main.async {
            // Remove the last drawn shape's coordinates
            if let lastOverlay = self.mapView.overlays.last {
                self.mapView.removeOverlay(lastOverlay)
            }
        }
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
                
                var color = ""
                if self.selectedPencilType == .Avoid {
                    color = "red"
                }
                else if self.selectedPencilType == .Pretty {
                    color = "blue"
                }
                else if self.selectedPencilType == .Shop {
                    color = "green"
                }
                
                let savedOverlay = CoreDataManager.shared.saveOverlay(color: color, note: "", coordinates: self.convertCoordinatesToJSONString(coordinates: self.coordinates), overlaysMap: self.currentMap!)
                
                let polygon = MapPolygon(coordinates: &points, count: numberOfPoints)
                polygon.overlay = savedOverlay
                mapView.addOverlay(polygon)
            }

            self.allCoordinates.append(self.coordinates)
            
            //UserDefaultManager.shared.saveCoordinates(self.allCoordinates)

            print("calling2: \(self.allCoordinates.count)")
            addGestureRecognizerToOverlay()
            isDrawingPolygon = false
            canvasView.image = nil
            canvasView.removeFromSuperview()
            self.selectedPencilType = .None
        }
        self.setImageTintColor()
    }
    
    func convertCoordinatesToJSONString(coordinates: [CLLocationCoordinate2D]) -> String {
        var arrayCord: [[String: Any]] = []
        for cord in coordinates {
            let dic: [String: Any] = ["latitude": cord.latitude, "longitude": cord.longitude]
            arrayCord.append(dic)
        }
        var coordString: String = ""
        if let data = try? JSONSerialization.data(withJSONObject: arrayCord, options: []) {
            coordString = String(data: data, encoding: String.Encoding.utf8) ?? ""
        }
        return coordString
    }
    
    func convertJSONStringToCoordinates(jsonString: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        
        if let data = jsonString.data(using: .utf8) {
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    for jsonCoordinate in jsonArray {
                        if let latitude = jsonCoordinate["latitude"] as? CLLocationDegrees,
                            let longitude = jsonCoordinate["longitude"] as? CLLocationDegrees {
                            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            coordinates.append(coordinate)
                        }
                    }
                }
            } catch {
                print("Error decoding JSON string to coordinates: \(error)")
            }
        }
        
        return coordinates
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
        if let polygon = overlay as? MapPolygon {
            let overlayPathView = MKPolygonRenderer(polygon: polygon)
            if polygon.overlay?.color == "red" {
                overlayPathView.fillColor = self.redColor.withAlphaComponent(0.2)
                overlayPathView.strokeColor = self.redColor.withAlphaComponent(0.7)
            }
            else if polygon.overlay?.color == "pretty" {
                overlayPathView.fillColor = self.blueColor.withAlphaComponent(0.2)
                overlayPathView.strokeColor = self.blueColor.withAlphaComponent(0.7)
            }
            else if polygon.overlay?.color == "green" {
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
    
    func addGestureRecognizerToOverlay() {
        for overlay in mapView.overlays {
            if overlay is MapPolygon {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
                mapView.addGestureRecognizer(tapGesture)
            }
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

        for overlay in mapView.overlays {
            if let polygon = overlay as? MapPolygon {
                if isCoordinateInsidePolygon(coordinate, polygon: polygon) {
                    // Handle tap on the specific overlay here
                    print("Tapped on the overlay")
                    break
                }
            }
        }
    }
    
    func isCoordinateInsidePolygon(_ coordinate: CLLocationCoordinate2D, polygon: MKPolygon) -> Bool {
        let polygonPath = CGMutablePath()
        let points = polygon.points()
        
        for i in 0..<polygon.pointCount {
            let polygonCoordinate = points[i]
            if i == 0 {
                polygonPath.move(to: CGPoint(x: polygonCoordinate.x, y: polygonCoordinate.y))
            } else {
                polygonPath.addLine(to: CGPoint(x: polygonCoordinate.x, y: polygonCoordinate.y))
            }
        }
        
        let mapPoint = MKMapPoint(coordinate)
        let boundingBox = polygonPath.boundingBox
        let mapRect = MKMapRect(x: Double(boundingBox.minX), y: Double(boundingBox.minY), width: Double(boundingBox.width), height: Double(boundingBox.height))
        
        return mapRect.contains(mapPoint)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return nil
    }
}
