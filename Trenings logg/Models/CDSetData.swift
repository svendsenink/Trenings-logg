import Foundation
import CoreData

@objc(CDSetData)
public class CDSetData: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var weight: String?
    @NSManaged public var reps: String?
    @NSManaged public var duration: String?
    @NSManaged public var distance: String?
    @NSManaged public var restPeriod: String?
    @NSManaged public var incline: String?
    @NSManaged public var exercise: CDExercise?
}

extension CDSetData {
    static func fetchRequest(_ predicate: NSPredicate) -> NSFetchRequest<CDSetData> {
        let request = NSFetchRequest<CDSetData>(entityName: "CDSetData")
        request.sortDescriptors = []
        request.predicate = predicate
        return request
    }
} 