import Foundation

enum WorkoutLayout: String, CaseIterable, Identifiable, Codable {
    case basic = "Basic"
    case strength = "Strength"
    case endurance = "Endurance"
    
    var id: String { rawValue }
} 