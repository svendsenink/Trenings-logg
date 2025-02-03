import Foundation

struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: String
    var exercises: [Exercise]
    var notes: String
    var calories: String
    var bodyWeight: String  // Ny property for kroppsvekt
    
    init(id: UUID = UUID(), date: Date, type: String, exercises: [Exercise], notes: String, calories: String = "", bodyWeight: String = "") {
        self.id = id
        self.date = date
        self.type = type
        self.exercises = exercises
        self.notes = notes
        self.calories = calories
        self.bodyWeight = bodyWeight
    }
}

struct Exercise: Identifiable, Codable {
    let id: UUID
    var name: String
    var sets: [SetData]
    var increaseNextTime: Bool
    
    init(id: UUID = UUID(), name: String, sets: [SetData], increaseNextTime: Bool = false) {
        self.id = id
        self.name = name
        self.sets = sets
        self.increaseNextTime = increaseNextTime
    }
}

struct SetData: Identifiable, Codable {
    let id: UUID
    var reps: String        // For styrke: reps, For utholdenhet: fart
    var weight: String      // For styrke: vekt, For utholdenhet: stigning
    var duration: String?   // For utholdenhet: varighet
    var distance: String?   // For utholdenhet: distanse
    var restPeriod: String? // Ny: For pause mellom sett
    
    init(id: UUID = UUID(), reps: String = "", weight: String = "", 
         duration: String? = nil, distance: String? = nil, restPeriod: String? = nil) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.distance = distance
        self.restPeriod = restPeriod
    }
} 