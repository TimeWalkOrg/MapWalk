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

class MapWalkViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnMapType: UIButton!
    
    @IBOutlet weak var viewAvoid: UIView!
    @IBOutlet weak var viewPretty: UIView!
    @IBOutlet weak var viewShop: UIView!
    @IBOutlet weak var viewTopButton: UIView!
    @IBOutlet weak var btnMenu: UIButton!
    
    @IBOutlet weak var viewBottomContainer: UIView!
    @IBOutlet weak var btnAvoid: CustomButton!
    @IBOutlet weak var btnPretty: CustomButton!
    @IBOutlet weak var btnShop: CustomButton!
    
    @IBOutlet weak var imgAvoidPen: UIImageView!
    @IBOutlet weak var imgPrettyPen: UIImageView!
    @IBOutlet weak var imgShopPen: UIImageView!
    
    
    var selectedPencilType = PencilType.None
    var drawingType = DrawingType.TracingStreet
    
    var currentMapType: MKMapType = .standard {
        didSet {
            // Update the map type
            mapView.mapType = currentMapType
            
            // Update the button image based on the map type
            let largeConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .unspecified, scale: .large)
            if currentMapType == .standard {
                btnMapType.setImage(UIImage(systemName: "map.fill", withConfiguration: largeConfig), for: .normal)
                lblMapWalk.textColor = .black
            } else {
                btnMapType.setImage(UIImage(systemName: "globe.americas.fill", withConfiguration: largeConfig), for: .normal)
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
    
    //MARK: - Live cycle method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    //MARK: - Functions
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
        
        self.btnMenu.layer.cornerRadius = 10
        self.btnMenu.layer.masksToBounds = true
        self.setupMenuOptions()
        
        self.viewTopButton.layer.cornerRadius = 10
        self.viewTopButton.layer.shadowColor = UIColor.black.cgColor
        self.viewTopButton.layer.shadowRadius = 1.5
        self.viewTopButton.layer.shadowOpacity = 0.3
        self.viewTopButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        self.viewBottomContainer.roundCorners([.topLeft, .topRight], radius: 10)
    }
    
    func setupMenuOptions() {
        let exportKml = UIAction(title: "Export KML", image: UIImage(systemName: "square.and.arrow.up")) { _ in
            let kmlContent = KMLExporter.generateKML(from: self.mapView.overlays, mapView: self.mapView)
            
            if let kmlData = kmlContent.data(using: .utf8) {
                // Define the file URL with the .kml extension
                let kmlFileName = "map_overlay.kml"
                let kmlURL = FileManager.default.temporaryDirectory.appendingPathComponent(kmlFileName)
                
                do {
                    // Write the KML data to the file URL
                    try kmlData.write(to: kmlURL)
                    
                    // Create an activity view controller to share the file
                    let activityViewController = UIActivityViewController(activityItems: [kmlURL], applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.view
                    
                    // Present the activity view controller
                    self.present(activityViewController, animated: true, completion: nil)
                } catch {
                    // Handle any errors that occur during file writing
                    print("Error writing KML file: \(error.localizedDescription)")
                }
            }
        }
        
        let option1 = UIAction(title: "Option 1", image: nil) { _ in
            
        }
        
        let option2 = UIAction(title: "Option 2", image: nil) { _ in
            
        }
        
        self.btnMenu.overrideUserInterfaceStyle = .dark
        self.btnMenu.showsMenuAsPrimaryAction = true
        self.btnMenu.menu = UIMenu(title: "", children: [exportKml, option1, option2])
    }
    
    func updateMap(with location: CLLocation) {
        mapView.showsUserLocation = true
        
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
                        if overlay.color == "red" {
                            polyLine.strokeColor = AppColors.redColor.withAlphaComponent(0.7)
                        }
                        else if overlay.color == "blue" {
                            polyLine.strokeColor = AppColors.blueColor.withAlphaComponent(0.7)

                        }
                        else if overlay.color == "green" {
                            polyLine.strokeColor = AppColors.greenColor.withAlphaComponent(0.7)
                        }
                        DispatchQueue.main.async(execute: {
                            self.mapView.addOverlay(polyLine)
                        })
                    }
                    else {
                        let polygon = MapPolygon(coordinates: &points, count: numberOfPoints)
                        polygon.overlay = overlay
                        if overlay.color == "red" {
                            polygon.fillColor = AppColors.redColor.withAlphaComponent(0.2)
                            polygon.strokeColor = AppColors.redColor.withAlphaComponent(0.7)

                        }
                        else if overlay.color == "blue" {
                            polygon.fillColor = AppColors.blueColor.withAlphaComponent(0.2)
                            polygon.strokeColor = AppColors.blueColor.withAlphaComponent(0.7)

                        }
                        else if overlay.color == "green" {
                            polygon.fillColor = AppColors.greenColor.withAlphaComponent(0.2)
                            polygon.strokeColor = AppColors.greenColor.withAlphaComponent(0.7)
                        }
                        DispatchQueue.main.async(execute: {
                            self.mapView.addOverlay(polygon)
                        })
                    }
                    
                    if overlay.note != "" {
                        self.addBubbleAnnotation(coordinatesArray: coordinatesArray, title: overlay.note ?? "", overlayID: overlay.overlayID)
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.addLongGestureRecognizerToOverlay()
                self.addTapGestureRecognizerToOverlay()
            }
        }
    }
    
    func addBubbleAnnotation(coordinatesArray: [CLLocationCoordinate2D], title: String, overlayID: Int32) {
        // Calculate the centroid of the polygon
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude
        
        for coordinate in coordinatesArray {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
                
        let centroidCoordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)

        // Add a pin annotation at the center of the polygon
        let annotation = MapPointAnnotation()
        annotation.identifier = overlayID
        annotation.coordinate = centroidCoordinate
        annotation.title = nil
        annotation.subtitle = title
        mapView.addAnnotation(annotation)
        
        //mapView.showAnnotations([annotation], animated: true)
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
    
    func startEndDragging() {
        if isDrawingPolygon == false {
            isDrawingPolygon = true
            coordinates.removeAll()
            canvasView = CanvasView(frame: mapView.frame)
            if self.selectedPencilType == .Avoid {
                canvasView.selectedColor = AppColors.redColor
            }
            else if self.selectedPencilType == .Pretty {
                canvasView.selectedColor = AppColors.blueColor
            }
            else if self.selectedPencilType == .Shop {
                canvasView.selectedColor = AppColors.greenColor
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
                    if color == "red" {
                        polygon.fillColor = AppColors.redColor.withAlphaComponent(0.2)
                        polygon.strokeColor = AppColors.redColor.withAlphaComponent(0.7)
                    }
                    else if color == "blue" {
                        polygon.fillColor = AppColors.blueColor.withAlphaComponent(0.2)
                        polygon.strokeColor = AppColors.blueColor.withAlphaComponent(0.7)

                    }
                    else if color == "green" {
                        polygon.fillColor = AppColors.greenColor.withAlphaComponent(0.2)
                        polygon.strokeColor = AppColors.greenColor.withAlphaComponent(0.7)
                    }

                    DispatchQueue.main.async(execute: {
                        self.mapView.addOverlay(polygon)
                    })
                }
                else {
                    let polyLine = MapPolyline(coordinates: &points, count: numberOfPoints)
                    polyLine.overlay = savedOverlay
                    if color == "red" {
                        polyLine.strokeColor = AppColors.redColor.withAlphaComponent(0.7)
                    }
                    else if color == "blue" {
                        polyLine.strokeColor = AppColors.blueColor.withAlphaComponent(0.7)
                    }
                    else if color == "green" {
                        polyLine.strokeColor = AppColors.greenColor.withAlphaComponent(0.7)
                    }
                    DispatchQueue.main.async(execute: {
                        self.mapView.addOverlay(polyLine)
                    })
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.addLongGestureRecognizerToOverlay()
                    self.addTapGestureRecognizerToOverlay()
                }
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
    
    func setImageTintColor() {
        self.viewAvoid.backgroundColor = self.selectedPencilType == .Avoid ? .white : AppColors.buttonBGColor
        self.viewPretty.backgroundColor = self.selectedPencilType == .Pretty ? .white : AppColors.buttonBGColor
        self.viewShop.backgroundColor = self.selectedPencilType == .Shop ? .white : AppColors.buttonBGColor
        
        self.imgAvoidPen.tintColor = self.selectedPencilType == .Avoid ? AppColors.redColor : AppColors.grayColor
        self.imgPrettyPen.tintColor = self.selectedPencilType == .Pretty ? AppColors.blueColor : AppColors.grayColor
        self.imgShopPen.tintColor = self.selectedPencilType == .Shop ? AppColors.greenColor : AppColors.grayColor
    }
    
    //MARK: - Button actions
    
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
            if self.currentLocation != nil {
                self.loadOverlaysOnMap()
                self.btnMapType.isEnabled = true
            }
        }
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
        
        DispatchQueue.main.async {
            // Remove the last drawn shape's coordinates
            if let lastOverlay = self.mapView.overlays.last {
                self.mapView.removeOverlay(lastOverlay)
            }
            
            // Remove the last annotation
            for annotation in self.mapView.annotations {
                if let annot = annotation as? MapPointAnnotation {
                    if annot.identifier == overlayToDelete?.overlayID {
                        self.mapView.removeAnnotation(annot)
                    }
                }
            }
            
            CoreDataManager.shared.deleteOverlay(overlayID: overlayToDelete?.overlayID ?? 0)
        }
    }
    
    @IBAction func btnCurrentLocationAction(_ sender: Any) {
        LocationManager.shared.hasReceivedInitialLocation = false
        LocationManager.shared.startUpdatingLocation()
    }
    
    @IBAction func btnMenuAction(_ sender: Any) {
        
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
        
        if coordinates.count > 0 && self.drawingType == .EncirclingArea {
            let firstCoord = coordinates[0]
            coordinates.append(firstCoord)
        }
        self.startEndDragging()
    }
    
    //MARK: - Add Gesture recognizer
    
    func addLongGestureRecognizerToOverlay() {
        print("addLongGestureRecognizerToOverlay()")
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
    
    func addTapGestureRecognizerToOverlay() {
        print("addTapGestureRecognizerToOverlay()")
        for overlay in mapView.overlays {
            if overlay is MapPolygon {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
                mapView.addGestureRecognizer(tapGesture)
            }
            else if overlay is MapPolyline {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
                mapView.addGestureRecognizer(tapGesture)
            }
        }
    }
    
    @objc func handleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        // Iterate through your overlays to check if the long press is inside any of them
        for overlay in mapView.overlays {
            if overlay is MapPolygon { // You can check for other overlay types too
                if let polygonRenderer = mapView.renderer(for: overlay) as? MKPolygonRenderer {
                    let mapPoint = MKMapPoint(coordinate)
                    let polygonViewPoint = polygonRenderer.point(for: mapPoint)
                    
                    if polygonRenderer.path.contains(polygonViewPoint) {
                        // Tap is inside this overlay
                        if let ol = overlay as? MapPolygon {
                            print(ol.overlay?.note ?? "")
                        }
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
    
    func showCustomMenu(at point: CGPoint, polygonOverlay: MapPolygon?, polylineOverlay: MapPolyline?) {
        if customMenu == nil {
            
            var hasNote = false
            if polygonOverlay != nil && polygonOverlay?.overlay?.note != "" {
                hasNote = true
            }
            if polygonOverlay != nil && polygonOverlay?.overlay?.note != "" {
                hasNote = true
            }
            
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
                customMenu = CustomMenuView(frame: initialFrame, delegate: self, polygonOverlay: polygonOverlay, polyLineOverlay: nil, addButtonTitle: hasNote ? "Update label" : "Add label")
            }
            else if polylineOverlay != nil {
                customMenu = CustomMenuView(frame: initialFrame, delegate: self, polygonOverlay: nil, polyLineOverlay: polylineOverlay, addButtonTitle: hasNote ? "Update label" : "Add label")
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
}

//MARK: - MKMapViewDelegate

extension MapWalkViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygon = overlay as? MapPolygon {
            
            //let overlayPathView = MKPolygonRenderer(polygon: polygon)
            let overlayPathView = ConstantWidthPolygonRenderer(polygon: polygon)
            
            if polygon.overlay?.color == "red" {
                overlayPathView.fillColor = AppColors.redColor.withAlphaComponent(0.2)
                overlayPathView.strokeColor = AppColors.redColor.withAlphaComponent(0.7)
            }
            else if polygon.overlay?.color == "blue" {
                overlayPathView.fillColor = AppColors.blueColor.withAlphaComponent(0.2)
                overlayPathView.strokeColor = AppColors.blueColor.withAlphaComponent(0.7)
            }
            else if polygon.overlay?.color == "green" {
                overlayPathView.fillColor = AppColors.greenColor.withAlphaComponent(0.2)
                overlayPathView.strokeColor = AppColors.greenColor.withAlphaComponent(0.7)
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
                overlayPathView.strokeColor = AppColors.redColor.withAlphaComponent(0.7)
            }
            else if polyline.overlay?.color == "blue" {
                overlayPathView.strokeColor = AppColors.blueColor.withAlphaComponent(0.7)
            }
            else if polyline.overlay?.color == "green" {
                overlayPathView.strokeColor = AppColors.greenColor.withAlphaComponent(0.7)
            }
            else {
                overlayPathView.strokeColor = UIColor.blue.withAlphaComponent(0.7)
            }
            overlayPathView.lineWidth = 80
            return overlayPathView
        }
        
        return MKOverlayRenderer()
    }
    
    // MKMapViewDelegate method to customize annotation view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if !(annotation is MapPointAnnotation) {
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView!.canShowCallout = true
            annotationView!.loadCustomLines(customLines: ["\(annotation.subtitle! ?? "")"])
        }
        else {
            annotationView!.annotation = annotation
        }
        
        let pinImage = UIImage(systemName: "bubble.left.fill")?.withRenderingMode(.alwaysTemplate)
        annotationView!.image = pinImage
        annotationView?.tintColor = .white
        
        return annotationView
    }
    
    // MKMapViewDelegate method to handle tap on annotation's callout
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            // Handle the tap on the callout button (detail disclosure button)
            if let title = view.annotation?.title, let subtitle = view.annotation?.subtitle {
                let alertController = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alertController, animated: true, completion: nil)
            }
        }
    }
}

extension MapWalkViewController: CustomMenuDelegate {
    // Handle the Add action
    func didSelectAdd(polygonOverlay: MapPolygon?, polyLineOverlay: MapPolyline?) {
        
        var hasNote = false
        var labelText = ""
        if polygonOverlay != nil && polygonOverlay?.overlay?.note != "" {
            hasNote = true
            labelText = polygonOverlay?.overlay?.note ?? ""
        }
        if polyLineOverlay != nil && polyLineOverlay?.overlay?.note != "" {
            hasNote = true
            labelText = polyLineOverlay?.overlay?.note ?? ""
        }
        
        // Create an alert controller
        let alertController = UIAlertController(title: hasNote ? "Update label" : "Add label", message: nil, preferredStyle: .alert)

        // Add a text field to the alert controller
        alertController.addTextField { (textField) in
            textField.placeholder = "Type a label text"
            textField.textAlignment = .left
            textField.delegate = self
            textField.clearButtonMode = .whileEditing
            if hasNote {
                textField.text = labelText
            }
        }

        // Add a cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        // Add an OK action
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            // Access the text entered by the user
            if let textField = alertController.textFields?.first {
                if let enteredText = textField.text {
                    print("Entered text: \(enteredText)")
                    
                    var stringCoordinate = ""
                    var overlayID: Int32?
                    if polygonOverlay != nil {
                        CoreDataManager.shared.addUpdateNote(overlayID: polygonOverlay?.overlay?.overlayID ?? 0, note: enteredText)
                        stringCoordinate = polygonOverlay?.overlay?.coordinates ?? ""
                        overlayID = polygonOverlay?.overlay?.overlayID ?? 0
                    }
                    else {
                        CoreDataManager.shared.addUpdateNote(overlayID: polyLineOverlay?.overlay?.overlayID ?? 0, note: enteredText)
                        stringCoordinate = polyLineOverlay?.overlay?.coordinates ?? ""
                        overlayID = polyLineOverlay?.overlay?.overlayID ?? 0
                    }
                    
                    let coordinatesArray = self.convertJSONStringToCoordinates(jsonString: stringCoordinate)
                    
                    self.addBubbleAnnotation(coordinatesArray: coordinatesArray, title: enteredText, overlayID: overlayID ?? 0)
                }
            }
        }
        alertController.addAction(okAction)

        // Present the alert controller
        self.present(alertController, animated: true, completion: nil)

        dismissCustomMenu()
    }
    
    func didSelectDelete(polygonOverlay: MapPolygon?, polyLineOverlay: MapPolyline?) {
        dismissCustomMenu()
        
        if polygonOverlay != nil {
            
            DispatchQueue.main.async {
                // Remove the last drawn shape's coordinates
                for overlay in self.mapView.overlays {
                    if let ov = overlay as? MapPolygon, ov.overlay?.overlayID == polygonOverlay?.overlay?.overlayID {
                        self.mapView.removeOverlay(overlay)
                    }
                }
                
                // Remove the last annotation
                for annotation in self.mapView.annotations {
                    if let annot = annotation as? MapPointAnnotation {
                        if annot.identifier == polygonOverlay?.overlay?.overlayID {
                            self.mapView.removeAnnotation(annot)
                        }
                    }
                }
                
                CoreDataManager.shared.deleteOverlay(overlayID: polygonOverlay?.overlay?.overlayID ?? 0)
            }
        }
        else if polyLineOverlay != nil {
            
            DispatchQueue.main.async {
                // Remove the last drawn shape's coordinates
                for overlay in self.mapView.overlays {
                    if let ov = overlay as? MapPolyline, ov.overlay?.overlayID == polyLineOverlay?.overlay?.overlayID {
                        self.mapView.removeOverlay(overlay)
                    }
                }
                for annotation in self.mapView.annotations {
                    if let annot = annotation as? MapPointAnnotation {
                        if annot.identifier == polyLineOverlay?.overlay?.overlayID {
                            self.mapView.removeAnnotation(annot)
                        }
                    }
                }
                CoreDataManager.shared.deleteOverlay(overlayID: polyLineOverlay?.overlay?.overlayID ?? 0)
            }
        }
        else {
            //Nothing
        }
    }
}

//MARK: - UITextFieldDelegate
extension MapWalkViewController: UITextFieldDelegate {
    // UITextFieldDelegate method to limit character count
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        // Check if the new text length exceeds 140 characters
        return newText.count <= 140
    }
    
    // Selector method to handle text field changes
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, text.count > 140 {
            textField.text = String(text.prefix(140))
        }
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
