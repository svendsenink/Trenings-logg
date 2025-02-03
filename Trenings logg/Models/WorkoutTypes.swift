import Foundation

enum WorkoutLayout: String, CaseIterable {
    case strength = "Styrke (Vekt/Reps)"
    case endurance = "Utholdenhet (Tid/Distanse)"
    case basic = "Enkel (Kun tid)"
}

enum WorkoutCategory: String, CaseIterable {
    case strength = "Styrke"
    case endurance = "Utholdenhetstrening"
    case other = "Annen trening"
    
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