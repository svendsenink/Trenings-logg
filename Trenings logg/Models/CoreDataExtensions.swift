import Foundation
import CoreData

// MARK: - CDWorkoutSession
extension CDWorkoutSession {
    static func fetchRequest(_ predicate: NSPredicate?) -> NSFetchRequest<CDWorkoutSession> {
        let request = NSFetchRequest<CDWorkoutSession>(entityName: "CDWorkoutSession")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWorkoutSession.date, ascending: false)]
        request.predicate = predicate
        return request
    }
    
    var exerciseArray: [CDExercise] {
        let set = exercises as? Set<CDExercise> ?? []
        return Array(set).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
}

// MARK: - CDExercise
extension CDExercise {
    var setArray: [CDSetData] {
        let set = sets as? Set<CDSetData> ?? []
        return set.sorted { first, second in
            first.order < second.order
        }
    }
}

// MARK: - CDWorkoutTemplate
extension CDWorkoutTemplate {
    static func fetchRequest(_ predicate: NSPredicate?) -> NSFetchRequest<CDWorkoutTemplate> {
        let request = NSFetchRequest<CDWorkoutTemplate>(entityName: "CDWorkoutTemplate")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWorkoutTemplate.name, ascending: true)]
        request.predicate = predicate
        return request
    }
    
    var exerciseArray: [CDExerciseTemplate] {
        let set = exercises as? Set<CDExerciseTemplate> ?? []
        return set.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
}

// MARK: - Date Helpers
extension Date {
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
} 