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
