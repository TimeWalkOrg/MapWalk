//
//  CoreDataManager.swift
//  VideoWatcher
//
//  Created by MyMac on 04/08/23.
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MapWalk")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - CRUD Functions Map
    func saveMap(mapName: String, isMyMap: Bool) {
        let map = Map(context: context)
        map.mapName = mapName
        map.mapID = getMapID()
        map.isMyMap = isMyMap
        
        do {
            try context.save()
        } catch {
            print("Error saving map: \(error)")
        }
    }
    
    func getMapID() -> Int32 {
        var mapID: Int32 = 0
        let maps = self.getMap()
        if maps.count > 0 {
            if let lastMap = maps.max(by: { ($0.mapID) < ($1.mapID) }) {
                mapID = lastMap.mapID
            }
            //let mostRecentMap = maps.last
            //mapID = mostRecentMap?.mapID ?? 0
        }
        mapID += 1
        return Int32(mapID)
    }
    
    func getMap() -> [Map] {
        let fetchRequest: NSFetchRequest<Map> = Map.fetchRequest()
        do {
            let map = try context.fetch(fetchRequest)
            return map
        } catch {
            print("Error fetching Map: \(error)")
            return []
        }
    }
    
    func renameMap(mapID: Int32, newName: String) {
        let fetchRequest: NSFetchRequest<Map> = Map.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mapID == %d", mapID)

        do {
            if let map = try context.fetch(fetchRequest).first {
                map.mapName = newName
                try context.save()
            }
        } catch {
            print("Error rename map: \(error)")
        }
    }
    
    // MARK: - CRUD Functions Overlays on map
    func saveOverlay(color: String, note: String, coordinates: String, overlaysMap: Map, isLine: Bool) -> Overlays {
        let overlay = Overlays(context: context)
        overlay.overlayID = self.getOverlayID()
        overlay.color = color
        overlay.note = note
        overlay.coordinates = coordinates
        overlay.overlaysMap = overlaysMap
        overlay.isLine = isLine
        
        do {
            try context.save()
        } catch {
            print("Error saving map: \(error)")
        }
        
        return overlay
    }
    
    func addUpdateNote(overlayID: Int32, note: String) {
        let fetchRequest: NSFetchRequest<Overlays> = Overlays.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "overlayID == %d", overlayID)

        do {
            if let overlay = try context.fetch(fetchRequest).first {
                overlay.note = note
                try context.save()
            }
        } catch {
            print("Error add/update overlay: \(error)")
        }
    }
    
    func getOverlayID() -> Int32 {
        var overlayID: Int32 = 0
        let overlays = self.getOverlays()
        if overlays.count > 0 {
            if let lastOverlay = overlays.max(by: { ($0.overlayID) < ($1.overlayID) }) {
                overlayID = lastOverlay.overlayID
            }
        }
        overlayID += 1
        print("saved overlayID: \(overlayID)")
        return Int32(overlayID)
    }
    
    func getOverlays() -> [Overlays] {
        let fetchRequest: NSFetchRequest<Overlays> = Overlays.fetchRequest()
        do {
            let overlay = try context.fetch(fetchRequest)
            return overlay
        } catch {
            print("Error fetching overlay: \(error)")
            return []
        }
    }
    
    func deleteOverlay(overlayID: Int32) {
        let fetchRequest: NSFetchRequest<Overlays> = Overlays.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "overlayID == %d", overlayID)

        do {
            if let video = try context.fetch(fetchRequest).first {
                context.delete(video)
                try context.save()
            }
        } catch {
            print("Error deleting overlay: \(error)")
        }
    }
    
    func getMapImageOverlays() -> [MapImageOverlays] {
        let fetchRequest: NSFetchRequest<MapImageOverlays> = MapImageOverlays.fetchRequest()
        do {
            let overlay = try context.fetch(fetchRequest)
            return overlay
        } catch {
            print("Error fetching Map overlay: \(error)")
            return []
        }
    }
    
    func getMapImageOverlayID() -> Int32 {
        var overlayID: Int32 = 0
        let overlays = self.getMapImageOverlays()
        if overlays.count > 0 {
            if let lastOverlay = overlays.max(by: { ($0.overlayID) < ($1.overlayID) }) {
                overlayID = lastOverlay.overlayID
            }
        }
        overlayID += 1
        print("saved Map overlayID: \(overlayID)")
        return Int32(overlayID)
    }
    
    func fetchMapImageOverlays() -> [MapImageOverlays] {
        let fetchRequest: NSFetchRequest<MapImageOverlays> = MapImageOverlays.fetchRequest()
        
        do {
            let overlays = try context.fetch(fetchRequest)
            if overlays.isEmpty {
                return saveMapImageOverlays()
            }
            return overlays
        } catch {
            print("Error fetching MapImageOverlays: \(error)")
            return []
        }
        
    }
    
    func saveMapImageOverlays() -> [MapImageOverlays] {
        let locationOptions: [(name: String, coordinate: CLLocationCoordinate2D, image: UIImage?, icon: UIImage?)] = [
            (name: "None", coordinate: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), image: nil, icon: nil),
            (name: "Castello - 1660", coordinate: CLLocationCoordinate2D(latitude: 40.7804442, longitude: -73.9767702), UIImage(named: "groundOverlay"),
             icon: UIImage(named: "1660-Castello_ic")),
            (name: "Holland - 1776", coordinate: CLLocationCoordinate2D(latitude: 40.7804442, longitude: -73.9767702), UIImage(named: "1776-Hollanddowntown"),
             icon: UIImage(named: "1776-Hollanddowntown_ic")),
            (name: "GreatFire - 1776", coordinate: CLLocationCoordinate2D(latitude: 40.7804442, longitude: -73.9767702), UIImage(named: "1776-GreatFire"),
             icon: UIImage(named: "1776-GreatFire_ic"))
        ]
        
        var arrMapImageOverlays: [MapImageOverlays] = []
        for location in locationOptions {
            let overlay = saveMapImageOverlay(
                name: location.name,
                image: location.image?.pngData(),
                coordinates: "{\(location.coordinate.latitude),\(location.coordinate.longitude)}",
                midCoord: "{40.70524,-74.01091}",
                overlayTopLeftCoord: "{40.71077,-74.01834}",
                overlayTopRightCoord: "{40.71077,-74.00409}",
                overlayBottomLeftCoord: "{40.69918,-74.0183}",
                icon: location.icon?.pngData()
            )
            
            arrMapImageOverlays.append(overlay)
        }
        
        return arrMapImageOverlays
    }
    
    func saveMapImageOverlay(name: String, image: Data?, coordinates: String, midCoord: String, overlayTopLeftCoord: String, overlayTopRightCoord: String, overlayBottomLeftCoord: String, icon: Data?) -> MapImageOverlays {
        let overlay = MapImageOverlays(context: context)
        overlay.overlayID = self.getMapImageOverlayID()
        overlay.image = image
        overlay.name = name
        overlay.coordinates = coordinates
        overlay.midCoord = midCoord
        overlay.overlayTopLeftCoord = overlayTopLeftCoord
        overlay.overlayTopRightCoord = overlayTopRightCoord
        overlay.overlayBottomLeftCoord = overlayBottomLeftCoord
        overlay.transform = "\(CGAffineTransform.identity)"
        overlay.icon = icon
        
        do {
            try context.save()
        } catch {
            print("Error saving map: \(error)")
        }
        
        return overlay
    }
    
    func updateMapImageOverlayTransform(_ transform: CGAffineTransform, mapImageOverlays: MapImageOverlays) -> MapImageOverlays  {
        mapImageOverlays.transform = "\(transform)"

        do {
            try context.save()
        } catch {
            print("Failed to save overlay transform: \(error)")
        }
        
        return mapImageOverlays
    }
    
    func updateMapImageOverlayCordinates(cordinates: Coordinates, mapImageOverlays: MapImageOverlays) -> MapImageOverlays {
        
        mapImageOverlays.overlayTopLeftCoord = "{\(cordinates.topLeft.latitude), \(cordinates.topLeft.longitude)}"
        mapImageOverlays.overlayTopRightCoord = "{\(cordinates.topRight.latitude), \(cordinates.topRight.longitude)}"
        mapImageOverlays.overlayBottomLeftCoord = "{\(cordinates.bottomLeft.latitude), \(cordinates.bottomLeft.longitude)}"
        mapImageOverlays.midCoord = "{\(cordinates.center.latitude), \(cordinates.center.longitude)}"
        
        do {
            try context.save()
        } catch {
            print("Failed to save overlay transform: \(error)")
        }
        
        return mapImageOverlays
    }
    
    func deleteMapImageOverlay(overlayID: Int32) {
        let fetchRequest: NSFetchRequest<MapImageOverlays> = MapImageOverlays.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "overlayID == %d", overlayID)
        
        do {
            let overlays = try context.fetch(fetchRequest)
            if let overlayToDelete = overlays.first {
                context.delete(overlayToDelete)
                try context.save()
            } else {
                print("Can't find overlay from Id: \(overlayID)")
            }
        } catch {
            print("Error deleting overlay: \(error)")
        }
    }
    
    func deleteAllMapImageOverlays() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = MapImageOverlays.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            print("Deleted \(result?.result ?? 0) MapImageOverlays objects.")
            
            // To ensure the deleted objects are removed from the context:
            try context.save()
        } catch {
            print("Error deleting MapImageOverlays: \(error)")
        }
    }
}
