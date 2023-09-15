//
//  UserdefaultManager.swift
//  HapticAudioPlayer
//
//  Created by MyMac on 05/01/23.
//

import Foundation
import CoreLocation

class UserDefaultManager {
    static let shared = UserDefaultManager()
    
    private let coordinatesKey = "coordinatesKey"
    
    private init() {}
    
//    // Store the allCoordinates array in UserDefaults
//    func saveCoordinates(_ coordinates: [[CLLocationCoordinate2D]]) {
//        let coordinateDictionaries = coordinates.map { coordinateArray in
//            coordinateArray.map { coordinate in
//                [
//                    "latitude": coordinate.latitude,
//                    "longitude": coordinate.longitude
//                ]
//            }
//        }
//        
//        UserDefaults.standard.set(coordinateDictionaries, forKey: coordinatesKey)
//        UserDefaults.standard.synchronize()
//    }
//    
//    // Retrieve the allCoordinates array from UserDefaults
//    func loadCoordinates() -> [[CLLocationCoordinate2D]]? {
//        if let coordinateDictionaries = UserDefaults.standard.array(forKey: coordinatesKey) as? [[[String: Double]]] {
//            let coordinates = coordinateDictionaries.map { coordinateArray in
//                coordinateArray.map { coordinateDict in
//                    guard let latitude = coordinateDict["latitude"],
//                          let longitude = coordinateDict["longitude"] else {
//                        return CLLocationCoordinate2D()
//                    }
//                    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//                }
//            }
//            return coordinates
//        }
//        return nil
//    }
}
