//
//  ActionViewController.swift
//  MapWalkActionExtension
//
//  Created by MyMac on 06/10/23.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import MapKit

class ActionViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var kmlParser: KMLParser?
    var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.overrideUserInterfaceStyle = .light
        
        if let items = self.extensionContext!.inputItems as? [NSExtensionItem] {
            let item = items.first
            let provider = item?.attachments!.first
            if provider!.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider?.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil, completionHandler: { (fileURL, error) in
                    
                    DispatchQueue.main.async {
                        if let url = fileURL as? URL, url.pathExtension == "kml" {
                            // This is an KML. We'll load it, then place it in our map view.
                            
                            if let fileURL = fileURL as? URL {
                                print("fileURL: \(fileURL)")
                                self.fileURL = fileURL
                                self.openKMLFileFromURL(url: fileURL)
                            }
                        }
                        else {
                            self.presentAlertWith(title: "Invalid file", message: "Please choose KML file")
                        }
                    }
                })
            }
        }
    }
    
    func openKMLFileFromURL(url: URL) {
        
        kmlParser = KMLParser(url: url)
        kmlParser?.parseKML()
        mapView.delegate = self
        // Add all of the MKOverlay objects parsed from the KML file to the map.
        if let overlays = kmlParser?.overlays, overlays.count > 0 {
            
            mapView.addOverlays(overlays as! [any MKOverlay])
            
            // Add all of the MKAnnotation objects parsed from the KML file to the map.
            let annotations = kmlParser?.points
            mapView.addAnnotations(annotations as! [any MKAnnotation])
            
            // Walk the list of overlays and annotations and create a MKMapRect that
            // bounds all of them and store it into flyTo.
            var flyTo = MKMapRect.null
            for overlay in overlays {
                if flyTo.isNull {
                    flyTo = (overlay as AnyObject).boundingMapRect
                } else {
                    flyTo = flyTo.union((overlay as AnyObject).boundingMapRect)
                }
            }
            
            for annotation in annotations! {
                let annotationPoint = MKMapPoint((annotation as AnyObject).coordinate)
                let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0, height: 0)
                if flyTo.isNull {
                    flyTo = pointRect
                } else {
                    flyTo = flyTo.union(pointRect)
                }
            }
            
            // Position the map so that all overlays and annotations are visible on screen.
            mapView.setVisibleMapRect(flyTo, animated: true)
        }
    }
    
    func openParentApp(url: URL) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                let application = try self.sharedApplication()
                guard let url = url as URL? else {
                    return
                }
                if application.canOpenURL(url) {
                    application.open(url, options: [:]) { (success) in
                        if success {
                            print("Successfully opened the URL.")
                            // Finish the action extension
                            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                        } else {
                            print("Failed to open the URL.")
                        }
                    }
                    
                }
            }
            catch {
                
            }
        }
    }
    
    func presentAlertWith(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in
                self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnOpenInMapWalkAction() {
        let stringURL = "mapwalk://open?url=\(self.fileURL?.absoluteString ?? "")"
        self.openParentApp(url: URL(string: stringURL)!)
    }
    
    @IBAction func btnCloseAction(_ sender: Any) {
        self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
}

extension ActionViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if self.kmlParser != nil {
            return kmlParser?.renderer(for: overlay) ?? MKOverlayRenderer()
        }
        
        return MKOverlayRenderer()
    }
    
    // MKMapViewDelegate method to customize annotation view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if self.kmlParser != nil {
            return kmlParser?.view(for: annotation) ?? nil
        }
        
        return nil
    }
}

public extension UIViewController {
    
    func openURL(url: NSURL) -> Bool {
        do {
            let application = try self.sharedApplication()
            guard let url = url as URL? else {
                return false
            }
            if application.canOpenURL(url) {
                application.open(url, options: [:]) { (success) in
                    if success {
                        print("Successfully opened the URL.")
                    } else {
                        print("Failed to open the URL.")
                    }
                }
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
    func sharedApplication() throws -> UIApplication {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application
            }
            
            responder = responder?.next
        }
        
        throw NSError(domain: "UIInputViewController+sharedApplication.swift", code: 1, userInfo: nil)
    }
}
