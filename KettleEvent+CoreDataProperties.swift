//
//  KettleEvent+CoreDataProperties.swift
//  KettleCompanion
//
//  Created by Blake Drayson on 22/05/2022.
//
//

import Foundation
import CoreData


extension KettleEvent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KettleEvent> {
        return NSFetchRequest<KettleEvent>(entityName: "KettleEvent")
    }

    @NSManaged public var hexcolor: String
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
}

extension KettleEvent : Identifiable {

}
