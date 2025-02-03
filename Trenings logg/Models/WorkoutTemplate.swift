import Foundation

struct WorkoutTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: String
    var exercises: [ExerciseTemplate]
    
    init(id: UUID = UUID(), name: String, type: String, exercises: [ExerciseTemplate]) {
        self.id = id
        self.name = name
        self.type = type
        self.exercises = exercises
    }
}

struct ExerciseTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var defaultSets: Int
    
    init(id: UUID = UUID(), name: String, defaultSets: Int = 3) {
        self.id = id
        self.name = name
        self.defaultSets = defaultSets
    }
} 