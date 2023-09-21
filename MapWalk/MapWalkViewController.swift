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

enum DrawingType {
    case EncirclingArea
    case TracingStreet
    case None
}

class MapWalkViewController: UIViewController, UIGestureRecognizerDelegate, CustomMenuDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnMapType: UIButton!
    
    @IBOutlet weak var viewAvoid: UIView!
    @IBOutlet weak var viewPretty: UIView!
    @IBOutlet weak var viewShop: UIView!
    
    @IBOutlet weak var btnAvoid: CustomButton!
    @IBOutlet weak var btnPretty: CustomButton!
    @IBOutlet weak var btnShop: CustomButton!
    
    @IBOutlet weak var imgAvoidPen: UIImageView!
    @IBOutlet weak var imgPrettyPen: UIImageView!
    @IBOutlet weak var imgShopPen: UIImageView!
    
    let blueColor = UIColor(red: 41.0/255.0, green: 74.0/255.0, blue: 241.0/255.0, alpha: 1.0)
    let redColor = UIColor(red: 245.0/255.0, green: 85.0/255.0, blue: 70.0/255.0, alpha: 1.0)
    let greenColor = UIColor(red: 46.0/255.0, green: 197.0/255.0, blue: 25.0/255.0, alpha: 1.0)
    let grayColor = UIColor(red: 142.0/255.0, green: 141.0/255.0, blue: 146.0/255.0, alpha: 1.0)
    
    var selectedPencilType = PencilType.None
    var drawingType = DrawingType.TracingStreet
        
    var currentMapType: MKMapType = .standard {
        didSet {
            // Update the map type
            mapView.mapType = currentMapType
            
            // Update the button image based on the map type
            if currentMapType == .standard {
                btnMapType.setImage(UIImage(systemName: "map.fill"), for: .normal)
                lblMapWalk.textColor = .black
            } else {
                btnMapType.setImage(UIImage(systemName: "globe"), for: .normal)
                lblMapWalk.textColor = .white
            }
        }
    }
    
    private var coordinates: [CLLocationCoordinate2D] = []
    
    private var isDrawingPolygon: Bool = false
    private var canvasView: CanvasView!
    var currentMap: Map?
    var currentLocation: CLLocation?
    @IBOutlet weak var lblMapWalk: UILabel!
    var customMenu: CustomMenuView?
    var overlayView: CustomMenuOverlayView?
    
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
            self?.currentLocation = location
            self?.updateMap(with: location)
        }
        
        self.loadOverlaysOnMap()
        self.setupDrawTypeSelectionMenu(sender: self.btnAvoid)
        self.setupDrawTypeSelectionMenu(sender: self.btnPretty)
        self.setupDrawTypeSelectionMenu(sender: self.btnShop)
    }
    
    func updateMap(with location: CLLocation) {
        // Update map view with the location data
        self.addCurrentLocationAnnotation(with: location)
        
        // Optionally, you can set the map's region to focus on the updated location.
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }
    
    func addCurrentLocationAnnotation(with location: CLLocation) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        
        // Optionally, you can set a title and subtitle for the annotation.
        annotation.title = "Current Location"
        
        // Clear existing annotations and add the new one.
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotation(annotation)
    }

    func loadOverlaysOnMap() {
        // Load saved overlays of current map
        var overlays = CoreDataManager.shared.getOverlays()
        overlays = overlays.filter({$0.overlaysMap?.mapID == self.currentMap?.mapID})
        if overlays.count > 0 {
            for overlay in overlays {
                
                print("overlay ID: \(overlay.overlayID)")
                
                let coordinatesArray = self.convertJSONStringToCoordinates(jsonString: overlay.coordinates ?? "")
                
                let numberOfPoints = coordinatesArray.count
                
                if numberOfPoints > 2 {
                    var points: [CLLocationCoordinate2D] = []
                    for i in 0..<numberOfPoints {
                        points.append(coordinatesArray[i])
                    }
                    
                    if overlay.isLine == true {
                        let polyLine = MapPolyline(coordinates: &points, count: numberOfPoints)
                        polyLine.overlay = overlay
                        DispatchQueue.main.async(execute: {
                            self.mapView.addOverlay(polyLine)
                        })
                    }
                    else {
                        let polygon = MapPolygon(coordinates: &points, count: numberOfPoints)
                        polygon.overlay = overlay
                        DispatchQueue.main.async(execute: {
                            self.mapView.addOverlay(polygon)
                        })
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.addGestureRecognizerToOverlay()
            }
        }
    }
    
    @IBAction func btnMapTypeAction(_ sender: Any) {
        DispatchQueue.main.async {
            self.btnMapType.isEnabled = false
            self.mapView.removeAnnotations(self.mapView.annotations)
            for overlay in self.mapView.overlays {
                self.mapView.removeOverlay(overlay)
            }
            
            if self.currentMapType == .standard {
                self.currentMapType = .satellite
            } else {
                self.currentMapType = .standard
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let location = self.currentLocation {
                self.loadOverlaysOnMap()
                self.btnMapType.isEnabled = true
                self.addCurrentLocationAnnotation(with: location)
            }
        }
    }

    func setupDrawTypeSelectionMenu(sender: CustomButton) {
        let encirclingArea = UIAction(title: "Encircling an area", image: nil) { _ in
            self.resetCanvasView()
            if sender.tag == 1 {
                self.selectedPencilType = .Avoid
            }
            else if sender.tag == 2 {
                self.selectedPencilType = .Pretty
            }
            else {
                self.selectedPencilType = .Shop
            }
            self.drawingType = .EncirclingArea
            self.startEndDragging()
        }
        
        let tracingStreet = UIAction(title: "Tracing a street", image: nil) { _ in
            self.resetCanvasView()
            if sender.tag == 1 {
                self.selectedPencilType = .Avoid
            }
            else if sender.tag == 2 {
                self.selectedPencilType = .Pretty
            }
            else {
                self.selectedPencilType = .Shop
            }
            self.drawingType = .TracingStreet
            self.startEndDragging()
        }

        sender.onContextMenuDismissed = { [weak self] in
            if self?.drawingType == .None {
                self?.setImageTintColor()
                self?.startEndDragging()
            }
        }
        sender.overrideUserInterfaceStyle = .dark
        sender.showsMenuAsPrimaryAction = true
        sender.menu = UIMenu(title: "", children: [tracingStreet, encirclingArea])
    }
    
    @IBAction func btnAvoidAction(_ sender: Any) {
        self.selectedPencilType = .Avoid
    }
    
    @IBAction func btnPrettyAction(_ sender: Any) {
        self.selectedPencilType = .Pretty
        //self.startEndDragging()
    }
    
    @IBAction func btnShopAction(_ sender: Any) {
        self.selectedPencilType = .Shop
        //self.startEndDragging()
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
            canvasView.drawingType = self.drawingType
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
                
                let savedOverlay = CoreDataManager.shared.saveOverlay(color: color, note: "", coordinates: self.convertCoordinatesToJSONString(coordinates: self.coordinates), overlaysMap: self.currentMap!, isLine: self.drawingType == .EncirclingArea ? false : true)
                
                if self.drawingType == .EncirclingArea {
                    let polygon = MapPolygon(coordinates: &points, count: numberOfPoints)
                    polygon.overlay = savedOverlay
                    DispatchQueue.main.async(execute: {
                        self.mapView.addOverlay(polygon)
                    })
                }
                else {
                    let polyLine = MapPolyline(coordinates: &points, count: numberOfPoints)
                    polyLine.overlay = savedOverlay
                    DispatchQueue.main.async(execute: {
                        self.mapView.addOverlay(polyLine)
                    })
                }
                
                self.addGestureRecognizerToOverlay()
            }
            
            self.resetCanvasView()
        }
        self.setImageTintColor()
    }
    
    func resetCanvasView() {
        self.isDrawingPolygon = false
        self.selectedPencilType = .None
        self.drawingType = .None
        if canvasView != nil {
            canvasView.image = nil
            canvasView.removeFromSuperview()
        }
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
        self.viewAvoid.backgroundColor = self.selectedPencilType == .Avoid ? .white : .clear
        self.viewPretty.backgroundColor = self.selectedPencilType == .Pretty ? .white : .clear
        self.viewShop.backgroundColor = self.selectedPencilType == .Shop ? .white : .clear
        
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
            
            //let overlayPathView = MKPolygonRenderer(polygon: polygon)
            let overlayPathView = ConstantWidthPolygonRenderer(polygon: polygon)
            
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
            overlayPathView.lineWidth = 30
            return overlayPathView
        }
        else if let polyline = overlay as? MapPolyline {
            //let overlayPathView = MKPolylineRenderer(polyline: polyline)
            let overlayPathView = ConstantWidthPolylineRenderer(polyline: polyline)

            if polyline.overlay?.color == "red" {
                overlayPathView.strokeColor = self.redColor.withAlphaComponent(0.7)
            }
            else if polyline.overlay?.color == "pretty" {
                overlayPathView.strokeColor = self.blueColor.withAlphaComponent(0.7)
            }
            else if polyline.overlay?.color == "green" {
                overlayPathView.strokeColor = self.greenColor.withAlphaComponent(0.7)
            }
            else {
                overlayPathView.strokeColor = UIColor.blue.withAlphaComponent(0.7)
            }
            overlayPathView.lineWidth = 80
            return overlayPathView
        }
        
        return MKOverlayRenderer()
    }
    
    func addGestureRecognizerToOverlay() {
        print("addGestureRecognizerToOverlay()")
        for overlay in mapView.overlays {
            if overlay is MapPolygon {
                let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
                //let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
                mapView.addGestureRecognizer(tapGesture)
            }
            else if overlay is MapPolyline {
                let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
                mapView.addGestureRecognizer(tapGesture)
            }
        }
    }
    
    /*@objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        if gesture.state == .began {
            
            for overlay in mapView.overlays {
                if let polygon = overlay as? MapPolygon {
                    if isCoordinateInsidePolygon(coordinate, polygon: polygon) {
                        // Handle tap on the specific overlay here
                        print("Long press on the overlay")
                        break
                    }
                }
            }
        }
        else {
            return
        }
    }*/
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            // Iterate through your overlays to check if the long press is inside any of them
            for overlay in mapView.overlays {
                if overlay is MapPolygon { // You can check for other overlay types too
                    if let polygonRenderer = mapView.renderer(for: overlay) as? MKPolygonRenderer {
                        let mapPoint = MKMapPoint(coordinate)
                        let polygonViewPoint = polygonRenderer.point(for: mapPoint)
                        
                        if polygonRenderer.path.contains(polygonViewPoint) {
                            // Long press is inside this overlay
                            self.showCustomMenu(at: touchPoint, polygonOverlay: overlay as? MapPolygon, polylineOverlay: nil)
                            break
                        }
                    }
                }
                else if overlay is MapPolyline { // You can check for other overlay types too
                    if let polygonRenderer = mapView.renderer(for: overlay) as? MKPolylineRenderer {
                        let mapPoint = MKMapPoint(coordinate)
                        let polygonViewPoint = polygonRenderer.point(for: mapPoint)
                        
                        if polygonRenderer.path.contains(polygonViewPoint) {
                            // Long press is inside this overlay
                            self.showCustomMenu(at: touchPoint, polygonOverlay: nil, polylineOverlay: overlay as? MapPolyline)
                            break
                        }
                    }
                }
            }
        }
    }
    
    // Handle the Add action
    func didSelectAdd(polygonOverlay: MapPolygon?, polyLineOverlay: MapPolyline?) {
        dismissCustomMenu()
    }
    
    func didSelectDelete(polygonOverlay: MapPolygon?, polyLineOverlay: MapPolyline?) {
        dismissCustomMenu()
        
        if polygonOverlay != nil {
            CoreDataManager.shared.deleteOverlay(overlayID: polygonOverlay?.overlay?.overlayID ?? 0)
            
            DispatchQueue.main.async {
                // Remove the last drawn shape's coordinates
                for overlay in self.mapView.overlays {
                    if let ov = overlay as? MapPolygon, ov.overlay?.overlayID == polygonOverlay?.overlay?.overlayID {
                        self.mapView.removeOverlay(overlay)
                    }
                }
            }
        }
        else if polyLineOverlay != nil {
            CoreDataManager.shared.deleteOverlay(overlayID: polyLineOverlay?.overlay?.overlayID ?? 0)
            DispatchQueue.main.async {
                // Remove the last drawn shape's coordinates
                for overlay in self.mapView.overlays {
                    if let ov = overlay as? MapPolyline, ov.overlay?.overlayID == polyLineOverlay?.overlay?.overlayID {
                        self.mapView.removeOverlay(overlay)
                    }
                }
            }
        }
        else {
            //Nothing
        }
        
        
    }
    
    func showCustomMenu(at point: CGPoint, polygonOverlay: MapPolygon?, polylineOverlay: MapPolyline?) {
        if customMenu == nil {
            // Add the overlay view
            overlayView = CustomMenuOverlayView(frame: mapView.bounds)
            overlayView?.dismissAction = {
                self.dismissCustomMenu()
            }
            mapView.addSubview(overlayView!)
            
            let menuWidth: CGFloat = 160
            let menuHeight: CGFloat = 81
            
            let initialFrame = CGRect(x: point.x, y: point.y, width: 0, height: 0)
            let expandedFrame = CGRect(x: initialFrame.origin.x, y: initialFrame.origin.y, width: menuWidth, height: menuHeight)

            if polygonOverlay != nil {
                customMenu = CustomMenuView(frame: initialFrame, delegate: self, polygonOverlay: polygonOverlay, polyLineOverlay: nil)
            }
            else if polylineOverlay != nil {
                customMenu = CustomMenuView(frame: initialFrame, delegate: self, polygonOverlay: nil, polyLineOverlay: polylineOverlay)
            }
            
            mapView.addSubview(customMenu!)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.customMenu?.frame = expandedFrame
            }) { _ in
                // Animation completion block
                self.customMenu?.showButtons()
            }
        }
    }
    
    // Function to dismiss the custom menu
    func dismissCustomMenu() {
        customMenu?.removeFromSuperview()
        customMenu = nil
        
        overlayView?.removeFromSuperview()
        overlayView = nil
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
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            return nil
        }
    
    func mapView(_ mapView: MKMapView, contextMenuInteraction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
}


class ConstantWidthPolygonRenderer: MKPolygonRenderer {
    override func applyStrokeProperties(to context: CGContext, atZoomScale zoomScale: MKZoomScale) {
        super.applyStrokeProperties(to: context, atZoomScale: zoomScale)
        context.setLineWidth(self.lineWidth)
    }
}

class ConstantWidthPolylineRenderer: MKPolylineRenderer {
    override func applyStrokeProperties(to context: CGContext, atZoomScale zoomScale: MKZoomScale) {
        super.applyStrokeProperties(to: context, atZoomScale: zoomScale)
        context.setLineWidth(self.lineWidth)
    }
}
