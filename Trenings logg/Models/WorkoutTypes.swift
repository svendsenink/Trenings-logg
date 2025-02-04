import Foundation

enum WorkoutCategory: String, CaseIterable, Identifiable {
    case strength = "Strength"
    case endurance = "Endurance"
    case other = "Other training"
    
    var id: String { rawValue }
    
    var defaultLayout: WorkoutLayout {
        switch self {
        case .strength:
            return .strength
        case .endurance:
            return .endurance
        case .other:
            return .basic
        }
    }
}

enum WorkoutLayout: String, CaseIterable, Identifiable {
    case strength = "Strength (Weight/Reps)"
    case endurance = "Endurance (Time/Dist)"
    case basic = "Basic (Time only)"
    
    var id: String { rawValue }
} 