//
//  MapWalkViewController+Overlays.swift
//  MapWalk
//
//  Created by iMac on 09/09/24.
//

import UIKit

extension MapWalkViewController {
    
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
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let renderer = selectedPVOverlaView else { return }
        let scale = gesture.scale
        
        if gesture.state == .began || gesture.state == .changed {
            // Get the current center of the overlay
            let currentCenterX = renderer.currentBoundingMapRect.midX
            let currentCenterY = renderer.currentBoundingMapRect.midY
            
            // Calculate the new size after scaling
            let newWidth = renderer.currentBoundingMapRect.size.width * scale
            let newHeight = renderer.currentBoundingMapRect.size.height * scale
            
            // Calculate the new origin to maintain the center
            let newOriginX = currentCenterX - (newWidth / 2)
            let newOriginY = currentCenterY - (newHeight / 2)
            
            // Update the currentBoundingMapRect with the new size and origin
            renderer.currentBoundingMapRect = MKMapRect(origin: MKMapPoint(x: newOriginX, y: newOriginY), size: MKMapSize(width: newWidth, height: newHeight))
            
            // Reset the scale to 1 to prevent compounding scales
            gesture.scale = 1
        }
        
        // Trigger a redraw of the overlay
        renderer.setNeedsDisplay()
        mapView.setNeedsDisplay()
        
        if gesture.state == .ended, let selectedLocation = self.selectedLocation {
            let coordinates = renderer.getCoordinates()
            _ = CoreDataManager.shared.updateMapImageOverlayCordinates(cordinates: coordinates, mapImageOverlays: selectedLocation)
        }
    }

    @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
        guard let renderer = selectedPVOverlaView else { return }
        let rotation = gesture.rotation
        let rotationTransform = CGAffineTransform(rotationAngle: rotation)
        let finalTransform = renderer.imageTransform.concatenating(rotationTransform)
        
        if gesture.state == .began || gesture.state == .changed {
            renderer.imageTransform = finalTransform
            gesture.rotation = 0
            print(renderer.imageTransform)
        }

        renderer.setNeedsDisplay()
        mapView.setNeedsDisplay()
        
        if gesture.state == .ended, let selectedLocation = self.selectedLocation {
            _ = CoreDataManager.shared.updateMapImageOverlayTransform(finalTransform, mapImageOverlays: selectedLocation)
        }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let renderer = selectedPVOverlaView else { return }
        
        if gesture.state == .began || gesture.state == .changed {
            let translation = gesture.velocity(in: mapView)
            renderer.currentBoundingMapRect.origin.x += translation.x
            renderer.currentBoundingMapRect.origin.y += translation.y
        }
        
        renderer.setNeedsDisplay()
        mapView.setNeedsDisplay()
        
        if gesture.state == .ended, let selectedLocation = self.selectedLocation {
            let coordinates = renderer.getCoordinates()
            _ = CoreDataManager.shared.updateMapImageOverlayCordinates(cordinates: coordinates, mapImageOverlays: selectedLocation)
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
        viewSlider.isHidden = true
        btnAlpha.isSelected = false
        
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
        else if self.kmlParser != nil {
            return kmlParser?.renderer(for: overlay) ?? MKOverlayRenderer()
        }
        
        if overlay is PVParkMapOverlay {
            let data = self.selectedLocation?.image ?? Data()
            if let magicMountainImage = UIImage(data: data) {
                let overlayView = PVParkMapOverlayView(overlay: overlay, overlayImage: magicMountainImage)
                if let selectedLocation = self.selectedLocation, let transform = selectedLocation.transform?.toCGAffineTransform() {
                    overlayView.applyTransform(transform)
                }
                self.selectedPVOverlaView = overlayView
                return overlayView
            }
        }
        /*else if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            //renderer.fillColor = UIColor.yellow.withAlphaComponent(0.5)
            
            renderer.strokeColor = .red
            renderer.lineWidth = 2
            /*renderer.lineDashPattern = [20 as NSNumber,   // Long dash
                                        10 as NSNumber,   // Space
                                         5 as NSNumber,   // Shorter dash
                                        10 as NSNumber,   // Space
                                         1 as NSNumber,   // Dot
                                        10 as NSNumber]   // Space*/
            
            renderer.lineDashPattern = [5 as NSNumber,   // Long dash
                                        5 as NSNumber,   // Space
                                         5 as NSNumber,   // Shorter dash
                                        5 as NSNumber,   // Space
                                         1 as NSNumber,   // Dot
                                        5 as NSNumber]   // Space
            return renderer
        }*/
        
        return MKOverlayRenderer()
    }
    
    // MKMapViewDelegate method to customize annotation view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if self.kmlParser != nil {
            return kmlParser?.view(for: annotation) ?? nil
        }
            
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


// MARK: - MapOverlayPopupVCDelegate
extension MapWalkViewController: MapOverlayPopupVCDelegate {
    func didSelectLocation(_ location: MapImageOverlays) {
        DispatchQueue.main.async {
            // Remove the map overlayview
            for overlay in self.mapView.overlays {
                if overlay is PVParkMapOverlay {
                    self.mapView.removeOverlay(overlay)
                }
            }
            
            
            self.selectLocationOption(location, isForNewMap: true)
            self.btnMaps.isSelected = false
            self.btnMaps.tintColor = UIColor(hexString: "C0C0C0")
            self.btnMaps.backgroundColor = UIColor(hexString: "282828")
            
            if location.name == "None" {
                self.btnEdit.isSelected = true
                self.btnEditAction(self.btnEdit)
                self.btnAdjustMapOverlayAction(self.btnAdjustMapOverlay)
            }
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
