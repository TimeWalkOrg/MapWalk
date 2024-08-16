//
//  Map+CoreDataProperties.swift
//  MapWalk
//
//  Created by MyMac on 15/09/23.
//
//

import Foundation
import CoreData


extension Map {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Map> {
        return NSFetchRequest<Map>(entityName: "Map")
    }

    @NSManaged public var mapID: Int32
    @NSManaged public var mapName: String?
    @NSManaged public var isMyMap: Bool
    @NSManaged public var mapOverlays: NSSet?
    @NSManaged public var mapImageOverlays: NSSet?
}

extension MapImageOverlays {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MapImageOverlays> {
        return NSFetchRequest<MapImageOverlays>(entityName: "MapImageOverlays")
    }

    @NSManaged public var overlayID: Int32
    @NSManaged public var image: Data?
    @NSManaged public var icon: Data?
    @NSManaged public var name: String?

    @NSManaged public var coordinates: String?
    @NSManaged public var midCoord: String?
    @NSManaged public var overlayBottomLeftCoord: String?
    @NSManaged public var overlayTopLeftCoord: String?
    @NSManaged public var overlayTopRightCoord: String?
    @NSManaged public var transform: String?
}


// MARK: Generated accessors for mapOverlays
extension Map {

    @objc(addMapOverlaysObject:)
    @NSManaged public func addToMapOverlays(_ value: Overlays)

    @objc(removeMapOverlaysObject:)
    @NSManaged public func removeFromMapOverlays(_ value: Overlays)

    @objc(addMapOverlays:)
    @NSManaged public func addToMapOverlays(_ values: NSSet)

    @objc(removeMapOverlays:)
    @NSManaged public func removeFromMapOverlays(_ values: NSSet)

}

extension Map : Identifiable {

}
