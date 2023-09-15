//
//  Overlays+CoreDataProperties.swift
//  MapWalk
//
//  Created by MyMac on 15/09/23.
//
//

import Foundation
import CoreData


extension Overlays {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Overlays> {
        return NSFetchRequest<Overlays>(entityName: "Overlays")
    }

    @NSManaged public var overlayID: Int32
    @NSManaged public var color: String?
    @NSManaged public var note: String?
    @NSManaged public var coordinates: String?
    @NSManaged public var overlaysMap: Map?

}

extension Overlays : Identifiable {

}
