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
}
