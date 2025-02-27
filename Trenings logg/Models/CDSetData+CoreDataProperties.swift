//
//  CDSetData+CoreDataProperties.swift
//  Trenings logg
//
//  Created by Didrik Svendsen on 27/02/2025.
//
//

import Foundation
import CoreData


extension CDSetData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSetData> {
        return NSFetchRequest<CDSetData>(entityName: "CDSetData")
    }

    @NSManaged public var distance: String?
    @NSManaged public var duration: String?
    @NSManaged public var id: UUID?
    @NSManaged public var incline: String?
    @NSManaged public var reps: String?
    @NSManaged public var restPeriod: String?
    @NSManaged public var weight: String?
    @NSManaged public var order: Int16
    @NSManaged public var exercise: CDExercise?

}

extension CDSetData : Identifiable {

}
