//
//  LocationManager.swift
//  MapWalkSwift
//
//  Created by MyMac on 12/09/23.
//

import Foundation
import CoreLocation
import UIKit

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private var locationManager = CLLocationManager()

    // Define a closure to notify the map screen of location updates
    var locationUpdateHandler: ((CLLocation) -> Void)?
    var hasReceivedInitialLocation = false
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.startUpdatingLocation()
            } else {
                // Location services are not enabled, show an alert with a button to go to settings.
                self.showLocationSettingsAlert()
            }
        }
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate Methods

    /*func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            // Notify the map screen of location updates
            locationUpdateHandler?(location)
        }
    }*/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            // Notify the map screen of the initial location if it hasn't been received yet
            if !hasReceivedInitialLocation {
                self.locationUpdateHandler?(location)
                hasReceivedInitialLocation = true
                stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            // Location permission denied, show an alert with a button to go to settings.
            showLocationSettingsAlert()
        case .notDetermined:
            break // Do nothing
        @unknown default:
            break
        }
    }

    // Helper method to show an alert with a button to go to the app's settings for location permissions.
    private func showLocationSettingsAlert() {
        let alertController = UIAlertController(
            title: "Location Access Denied",
            message: "Please allow location access in Settings to use this feature.",
            preferredStyle: .alert
        )

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in
            self.showLocationSettingsAlert()
        })

        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)

        // Present the alert on the topmost view controller
        if let topViewController = UIApplication.shared.topViewController() {
            topViewController.present(alertController, animated: true, completion: nil)
        }
    }
}
