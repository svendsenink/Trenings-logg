import CoreData

extension CDExerciseTemplate {
    static func fetchRequest(_ predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchRequest<CDExerciseTemplate> {
        let request = NSFetchRequest<CDExerciseTemplate>(entityName: "CDExerciseTemplate")
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
} 