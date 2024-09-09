//
//  MapWalkViewController.swift
//  MapWalkSwift
//
//  Created by MyMac on 12/09/23.
//

import UIKit
import CoreLocation
import MapKit
import Photos
import PanModal

enum PencilType {
    case Avoid
    case Pretty
    case Shop
    case None
}

enum DrawingType {
    case EncirclingArea
    case TracingStreet
}

class MapWalkViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnMapType: UIButton!
    
    @IBOutlet weak var viewPenOptionAction: UIView!
    @IBOutlet weak var viewAvoid: UIView!
    @IBOutlet weak var viewPretty: UIView!
    @IBOutlet weak var viewSlider: UIView!
    @IBOutlet weak var stackSlider: UIStackView!
    @IBOutlet weak var stackOption: UIStackView!
    
    @IBOutlet weak var viewShop: UIView!
    @IBOutlet weak var viewButtonContainer: UIView!
    @IBOutlet weak var btnMenu: UIButton!
    @IBOutlet weak var btnAlpha: UIButton!
    
    @IBOutlet weak var viewBottomContainer: UIView!
    @IBOutlet weak var btnAvoid: CustomButton!
    @IBOutlet weak var btnPretty: CustomButton!
    @IBOutlet weak var btnShop: CustomButton!
    @IBOutlet weak var viewBottomHeight: NSLayoutConstraint!
    
    @IBOutlet weak var sliderAlpha: UISlider!
    @IBOutlet weak var imgShape: UIImageView!
    @IBOutlet weak var imgAvoidPen: UIImageView!
    @IBOutlet weak var imgPrettyPen: UIImageView!
    @IBOutlet weak var imgShopPen: UIImageView!
    @IBOutlet weak var btnEdit: UIButton!
    @IBOutlet weak var btnMaps: UIButton!
    @IBOutlet weak var btnAdjustMapOverlay: UIButton!
    @IBOutlet weak var btnAR: UIButton!
    
    var selectedPencilType = PencilType.None
    
    //var drawingType = DrawingType.TracingStreet
    
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
    
    var drawingType = DrawingType.EncirclingArea {
        didSet {
            // Update the button image based on the map type
            //let largeConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .unspecified, scale: .large)
            if drawingType == .EncirclingArea {
                imgShape.image = UIImage(systemName: "hexagon")
            } else {
                imgShape.image = UIImage(systemName: "line.diagonal")
            }
        }
    }
    
    var coordinates: [CLLocationCoordinate2D] = []
    
    var isDrawingPolygon: Bool = false
    var canvasView: CanvasView!
    var currentMap: Map?
    var currentLocation: CLLocation?
    @IBOutlet weak var lblMapWalk: UILabel!
    var customMenu: CustomMenuView?
    var overlayView: CustomMenuOverlayView?
    var kmlParser: KMLParser?
    var openedMapURL: URL?
    
    let regionRadius: CLLocationDistance = 1000
    var park: PVPark?
    var selectedPVOverlaView: PVParkMapOverlayView?
    //var selectedLocation = ""
    /*var locationOptions: [(name: String, coordinate: CLLocationCoordinate2D)] = [
        (name: "1776 Manhattan", coordinate: CLLocationCoordinate2D(latitude: 40.7804442, longitude: -73.9767702)),
        (name: "1660 Castello Plan", coordinate: CLLocationCoordinate2D(latitude: 40.7804442, longitude: -73.9767702)),
        (name: "1776 - Holland downtown", coordinate: CLLocationCoordinate2D(latitude: 40.7804442, longitude: -73.9767702)),
        (name: "1776 - Great Fire", coordinate: CLLocationCoordinate2D(latitude: 40.7804442, longitude: -73.9767702))
    ]*/
    
    /*var locationOptions: [(name: String, coordinate: CLLocationCoordinate2D, image: UIImage?)] = [
        (name: "None", coordinate: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), image: nil),
        (name: "1660 - Castello Plan", coordinate: CLLocationCoordinate2D(latitude: 40.7804442, longitude: -73.9767702),
         UIImage(named: "1660-Castello_ic")),
        (name: "1776 - Holland", coordinate: CLLocationCoordinate2D(latitude: 40.7804442, longitude: -73.9767702),
         UIImage(named: "1776-Hollanddowntown_ic")),
        (name: "1776 - Great Fire", coordinate: CLLocationCoordinate2D(latitude: 40.7804442, longitude: -73.9767702),
         UIImage(named: "1776-GreatFire_ic"))
    ]*/
    
    var selectedLocation: MapImageOverlays?
    var locationOptions: [MapImageOverlays] {
        return CoreDataManager.shared.fetchMapImageOverlays()
    }
    
    private var lastScale: CGFloat = 1.0
    private var lastRotation: CGFloat = 0.0
    private var lastTranslation: CGPoint = .zero
    private var mapViewZoomScale: CGFloat {
        guard let visibleRect = mapView?.visibleMapRect else { return 1.0 }
        let mapRectWidth = visibleRect.width
        let mapViewWidth = mapView?.bounds.width ?? 1.0
        return mapRectWidth / mapViewWidth
    }

        
    //MARK: - Live cycle method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    //MARK: - Functions
    func setupView() {
        self.loadMyMap()
        //self.locationOptions = CoreDataManager.shared.fetchMapImageOverlays()
        self.mapView.delegate = self
        
        // Request location permission if needed
        LocationManager.shared.requestLocationPermission()
        
        // Set up location updates handler
        LocationManager.shared.locationUpdateHandler = { [weak self] location in
            // Use the updated location for your map
            self?.currentLocation = location
            self?.updateMap(with: location)
        }
        
        //self.loadOverlaysOnMap()
        
        self.btnMenu.roundCorners([.topLeft, .topRight], radius: 10)
        //self.btnAdjustMapOverlay.roundCorners([.bottomLeft, .bottomRight], radius: 10)
        self.setupMenuOptions()
        
        self.btnAR.CornerRadius = 10
        
        self.viewButtonContainer.layer.shadowColor = UIColor.black.cgColor
        self.viewButtonContainer.layer.shadowRadius = 1.5
        self.viewButtonContainer.layer.shadowOpacity = 0.3
        self.viewButtonContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            //self.setMapCenter(self.locationOptions[0].coordinates, name: self.locationOptions[0].name)
            self.viewBottomContainer.roundCorners([.topLeft, .topRight], radius: 10)
            self.viewBottomHeight.constant = 0
            self.setupGestures()
            
            if let location = self.locationOptions.first {
                self.selectLocationOption(location)
                self.loadOverlaysOnMap()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleReceivedURL(_:)), name: Notification.Name("ReceivedURL"), object: nil)
    }
    
    private func setupGestures() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        
        mapView.addGestureRecognizer(pinchGesture)
        mapView.addGestureRecognizer(rotateGesture)
        mapView.addGestureRecognizer(panGesture)
    }
    
    func loadMyMap() {
        let map = CoreDataManager.shared.getMap()
        if map.count == 0 {
            CoreDataManager.shared.saveMap(mapName: "Ted's Map", isMyMap: true)
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
        
        let arrExcludingCategory: [MKPointOfInterestCategory] = [
            .airport,
            .amusementPark,
            .aquarium,
            .atm,
            .bakery,
            .bank,
            .brewery,
            .cafe,
            .campground,
            .carRental,
            .evCharger,
            .fireStation,
            .fitnessCenter,
            .foodMarket,
            .gasStation,
            .hospital,
            .hotel,
            .laundry,
            .marina,
            .museum,
            .movieTheater,
            .nationalPark,
            .nightlife,
            .parking,
            .pharmacy,
            .police,
            .postOffice,
            .publicTransport,
            .restaurant,
            .restroom,
            .school,
            .stadium,
            .store,
            .theater,
            .campground,
            .university,
            .winery,
            .zoo,
        ]
        self.mapView.pointOfInterestFilter = MKPointOfInterestFilter(excluding: arrExcludingCategory)
    }
    
    func disableMenuOptions(isHidden: Bool) {
        self.btnEdit.isSelected = true
        self.btnAlpha.isSelected = true
        self.stackSlider.isHidden = isHidden
        self.stackOption.isHidden = isHidden
        
        self.btnEditAction(btnEdit)
        self.btnAlphaAction(btnAlpha)
    }
    
    func moveToMyCurrentMap() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.openedMapURL = nil
            self.clearMap()
            self.loadMyMap()
            self.disableMenuOptions(isHidden: false)
            LocationManager.shared.hasReceivedInitialLocation = false
            LocationManager.shared.startUpdatingLocation()
            self.loadOverlaysOnMap()
        }
    }
    
    func setupMenuOptions() {
        
        let option1 = UIAction(title: "Name Current Map", image: nil) { _ in
            if self.currentMap != nil {
                self.showAlertToRenameMyMap()
            }
            else {
                self.moveToMyCurrentMap()
            }
        }
        //option1.state = .off
        
        let option2 = UIAction(title: "Share Current Map", image: UIImage(systemName: "square.and.arrow.up")) { _ in
            if self.currentMap == nil {
                return
            }
            self.exportKML(sender: self.btnMenu)
        }
        
        let option3 = UIAction(title: "Shared Maps", image: nil) { _ in
            self.moveToSharedMapVC()
        }
        
        let option4 = UIAction(title: "Import A Map (or KML)", image: nil) { _ in
            self.presentFilePicker()
            
        }
        
        self.btnMenu.overrideUserInterfaceStyle = .dark
        self.btnMenu.showsMenuAsPrimaryAction = true
        self.btnMenu.menu = UIMenu(title: "", children: [option1, option2, option3, option4])
    }
    
    func selectLocationOption(_ location: MapImageOverlays, isForNewMap: Bool = false) {
        if let coordinates = location.midCoord?.toCoordinate() {
            self.selectedLocation = location
            
            if isForNewMap == false {
                loadSelectedOptions()
                let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
                mapView.setRegion(region, animated: true)
            } else {
                addOverlay()
            }
        }
    }
    
    func loadSelectedOptions() {
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.removeOverlays(self.mapView.overlays)
        self.addOverlay()
    }
    
    func addOverlay() {
        //Original image
        let overlay = PVParkMapOverlay(mapImageOverlay: selectedLocation!)
        self.mapView.addOverlay(overlay)
        
        
        // Coordinates
        let topLeft = selectedLocation!.overlayTopLeftCoord?.toCoordinate() ?? kCLLocationCoordinate2DInvalid
        let topRight = selectedLocation!.overlayTopRightCoord?.toCoordinate() ?? kCLLocationCoordinate2DInvalid
        let bottomLeft = selectedLocation!.overlayBottomLeftCoord?.toCoordinate() ?? kCLLocationCoordinate2DInvalid
        let bottomRight = self.calculateBottomRight(topLeft: topLeft, topRight: topRight, bottomLeft: bottomLeft)
        
        let coordinates = [topLeft, topRight, bottomRight, bottomLeft]

        let overlays = MKPolygon(coordinates: coordinates, count: coordinates.count)

        // Add the overlay to your map
        mapView.addOverlay(overlays)
    }
    
    func calculateBottomRight(topLeft: CLLocationCoordinate2D, topRight: CLLocationCoordinate2D, bottomLeft: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // Calculate the missing bottom right corner
        let latitude = bottomLeft.latitude + (topRight.latitude - topLeft.latitude)
        let longitude = bottomLeft.longitude + (topRight.longitude - topLeft.longitude)
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func moveToSharedMapVC() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SharedMapViewController") as! SharedMapViewController
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .overCurrentContext
        navController.modalTransitionStyle = .crossDissolve
        navController.navigationBar.isHidden = true
        vc.delegate = self
        vc.openedMapURL = self.openedMapURL
        self.present(navController, animated: true)
    }
    
    func showAlertToRenameMyMap() {
        let alertController = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)

        // Add a text field to the alert controller
        alertController.addTextField { (textField) in
            textField.placeholder = "Type a name"
            textField.text = self.currentMap?.mapName ?? ""
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
                    CoreDataManager.shared.renameMap(mapID: self.currentMap?.mapID ?? 0, newName: enteredText)
                    self.currentMap?.mapName = enteredText
                }
            }
        }
        alertController.addAction(okAction)

        // Present the alert controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    func updateMap(with location: CLLocation) {
        mapView.showsUserLocation = true
        
        // Optionally, you can set the map's region to focus on the updated location.
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }
    
    func clearMap() {
        self.currentMap = nil
        self.kmlParser = nil
        for overlay in self.mapView.overlays {
            self.mapView.removeOverlay(overlay)
        }
        
        for annotation in self.mapView.annotations {
            self.mapView.removeAnnotation(annotation)
        }
    }
    
    private func presentFilePicker() {
        let supportedTypes: [UTType] = [UTType.data]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self.present(documentPicker, animated: true, completion: nil)
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
    @IBAction func btnShowOptionAction(_ sender: UIButton) {
        sender.isSelected.toggle()
        let selected = sender.isSelected
        let bgColor = UIColor(hexString: "C0C0C0")
        let tintColor = UIColor(hexString: "282828")
        
        sender.backgroundColor = selected ? bgColor : tintColor
        sender.tintColor = selected ? tintColor : bgColor
        
        UIView.animate(withDuration: 0.3) {
            self.viewButtonContainer.isHidden = !selected
            self.viewButtonContainer.alpha = !selected ? 0 : 1
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func btnARAction(_ sender: UIButton) {
        let arViewContoller = storyboard?.instantiateViewController(withIdentifier: "ARViewContoller") as! ARViewContoller
        arViewContoller.modalPresentationStyle = .fullScreen
        self.present(arViewContoller, animated: true)
    }
    
    @IBAction func btnAlphaAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        UIView.animate(withDuration: 0.3) {
            if let overlayView = self.selectedPVOverlaView, self.selectedLocation?.name != "None" {
                self.sliderAlpha.value = Float(overlayView.alpha)
                self.viewSlider.isHidden = !sender.isSelected
            } else {
                self.viewSlider.isHidden = true
                sender.isSelected = false
            }
        }
    }
    
    @IBAction func sliderAlphaAction(_ sender: UISlider) {
        if let overlayView = self.selectedPVOverlaView {
            overlayView.alpha = CGFloat(sender.value)
            overlayView.setNeedsDisplay()
            self.mapView.setNeedsLayout()
        }
    }
    
    @IBAction func btnShapeTypeAction(_ sender: Any) {
        if self.drawingType == .EncirclingArea {
            self.drawingType = .TracingStreet
        } else {
            self.drawingType = .EncirclingArea
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
            if self.currentLocation != nil {
                self.loadOverlaysOnMap()
                self.btnMapType.isEnabled = true
            }
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
        
        DispatchQueue.main.async {
            // Remove the last drawn shape's coordinates
            if let lastOverlay = self.mapView.overlays.last, !(lastOverlay is PVParkMapOverlay) {
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
        if self.kmlParser == nil {
            LocationManager.shared.hasReceivedInitialLocation = false
            LocationManager.shared.startUpdatingLocation()
        }
        else {
            self.moveToMyCurrentMap()
        }
    }
    
    @IBAction func btnMenuAction(_ sender: UIButton) {
        
    }
    
    @IBAction func btnEditAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            sender.backgroundColor = UIColor(hexString: "C0C0C0")
            sender.tintColor = UIColor(hexString: "282828")
        } else {
            sender.tintColor = UIColor(hexString: "C0C0C0")
            sender.backgroundColor = UIColor(hexString: "282828")
        }
        
        self.viewBottomContainer.isHidden = false
        UIView.animate(withDuration: 0.5) {
            self.viewBottomHeight.constant = sender.isSelected ? 120 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func btnMapsAction(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            sender.backgroundColor = UIColor(hexString: "C0C0C0")
            sender.tintColor = UIColor(hexString: "282828")
            
            let mapOverlayPopupVC = storyboard?.instantiateViewController(withIdentifier: "MapOverlayPopupVC") as! MapOverlayPopupVC
            mapOverlayPopupVC.locationOptions = self.locationOptions
            mapOverlayPopupVC.selectedLocation = self.selectedLocation?.name ?? "None" //self.selectedLocation
            mapOverlayPopupVC.delegate = self
            self.presentPanModal(mapOverlayPopupVC)
        } else {
            sender.tintColor = UIColor(hexString: "C0C0C0")
            sender.backgroundColor = UIColor(hexString: "282828")
            sender.isSelected = false
        }
    }
    
    @IBAction func btnAdjustMapOverlayAction(_ sender: UIButton) {
        sender.isSelected.toggle()
        
        if selectedPVOverlaView != nil && selectedLocation?.name != "None" {
            let isEnabled = !sender.isSelected
            mapView.isScrollEnabled = isEnabled
            mapView.isZoomEnabled = isEnabled
            mapView.isPitchEnabled = isEnabled
            mapView.isRotateEnabled = isEnabled
            
            if sender.isSelected {
                sender.backgroundColor = UIColor(hexString: "C0C0C0")
                sender.tintColor = UIColor(hexString: "282828")
            } else {
                sender.tintColor = UIColor(hexString: "C0C0C0")
                sender.backgroundColor = UIColor(hexString: "282828")
            }
        } else {
            sender.tintColor = UIColor(hexString: "C0C0C0")
            sender.backgroundColor = UIColor(hexString: "282828")
            sender.isSelected = false
            mapView.isScrollEnabled = true
            mapView.isZoomEnabled = true
            mapView.isPitchEnabled = true
            mapView.isRotateEnabled = true
        }
    }
}

extension MapWalkViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pickedURL = urls.first else {
            return
        }
        
        let _ = pickedURL.startAccessingSecurityScopedResource()
        // Get the file extension from the URL
        let fileExtension = pickedURL.pathExtension.lowercased()
        
        // Check the file extension or type
        if fileExtension == "kml" {
            // It's a KML file
            print("Picked KML file.")
            self.importKMLFrom(url: urls.first!)
        } else {
            // It's another type of file
            print("Picked a file with extension: \(fileExtension)")
            showAlert(title: "Invalid file", message: "Please import KML file", okActionTitle: "Ok") { result in }
        }
        
        pickedURL.stopAccessingSecurityScopedResource()
        controller.dismiss(animated: true, completion: {})
    }
        
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        //self.gotoVideoWatcherController()
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
