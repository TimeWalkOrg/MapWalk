//
//  MapWalkViewController+KML.swift
//  MapWalk
//
//  Created by iMac on 09/09/24.
//

import Foundation
import UniformTypeIdentifiers

extension MapWalkViewController {
    func exportKML(sender: UIButton) {
        let kmlContent = KMLExporter.generateKML(from: self.mapView.overlays, mapView: self.mapView)
        
        if let kmlData = kmlContent.data(using: .utf8) {
            // Define the file URL with the .kml extension
            let kmlFileName = "\(self.currentMap?.mapName ?? "Ted's Map").kml"
            let kmlURL = FileManager.default.temporaryDirectory.appendingPathComponent(kmlFileName)
            
            do {
                // Write the KML data to the file URL
                try kmlData.write(to: kmlURL)
                
                // Create an activity view controller to share the file
                let activityViewController = UIActivityViewController(activityItems: [kmlURL], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.view
                
                // Check if the device is iPad
                if let popoverPresentationController = activityViewController.popoverPresentationController {
                    popoverPresentationController.sourceView = sender
                    popoverPresentationController.sourceRect = sender.bounds
                }
                // Present the activity view controller
                self.present(activityViewController, animated: true, completion: nil)
            } catch {
                // Handle any errors that occur during file writing
                print("Error writing KML file: \(error.localizedDescription)")
            }
        }
    }
    
    func importKMLFrom(url: URL) {
        do {
            if let directoryURL = Utility.getDirectoryPath(folderName: DirectoryName.ImportedKMLFile) {
                
                let destinationURL = directoryURL.appendingPathComponent(url.lastPathComponent)
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    showAlert(title: "This KML file is already exit", message: "do you want to overwrite it?", okActionTitle: "Overwrite") { value in
                        if value == true {
                            do {
                                try FileManager.default.removeItem(at: destinationURL)
                                try FileManager.default.copyItem(at: url, to: destinationURL)
                                //Copy KML from Files or iCloud drive to app's document directory
                                self.openedMapURL = url
                                self.openKMLFileFromURL(url: destinationURL)
                                print("destinationURL: \(destinationURL)")
                            }
                            catch let error {
                                print(error.localizedDescription)
                            }
                        }
                    }
                }
                else {
                    try FileManager.default.copyItem(at: url, to: destinationURL) //Copy KML from Files or iCloud drive to app's document directory
                    self.openKMLFileFromURL(url: destinationURL)
                    print("destinationURL: \(destinationURL)")
                }
            }
        }
        catch {
            print("Error copying video: \(error)")
        }
    }
    
    @objc func handleReceivedURL(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let url = userInfo["url"] as? URL {
            // Handle the URL here
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.openKMLFileFromURL(url: url)
            }
        }
    }
    
    func openKMLFileFromURL(url: URL) {
        
        self.clearMap()
        self.setupMenuOptions()
        
        //self.viewBottomHeight.constant = 0
        self.disableMenuOptions(isHidden: true)

        
        kmlParser = KMLParser(url: url)
        kmlParser?.parseKML()
        
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
}

extension MapWalkViewController: SharedMapDelegate {
    func showCurrentMap() {
        self.moveToMyCurrentMap()
    }
    
    func showSelectedMapFromURL(url: URL) {
        self.openedMapURL = url
        self.openKMLFileFromURL(url: url)
    }
}
