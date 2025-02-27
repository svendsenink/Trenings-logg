import Foundation
import HealthKit
import SwiftUI

enum WorkoutCategory: String, CaseIterable, Identifiable, Codable {
    case strength = "Strength"
    case endurance = "Endurance"
    case other = "Other"
    
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
    
    var iconName: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .endurance: return "figure.run"
        case .other: return "figure.mixed.cardio"
        }
    }
    
    var workoutTypes: [HKWorkoutActivityType] {
        switch self {
        case .strength:
            return [.traditionalStrengthTraining, .functionalStrengthTraining]
        case .endurance:
            return [.running, .cycling, .swimming, .walking, .rowing]
        case .other:
            return [.hiking, .crossTraining, .yoga, .pilates, .boxing, .other]
        }
    }
    
    // Konverter til HKWorkoutActivityType
    var healthKitType: HKWorkoutActivityType {
        switch self {
        case .strength:
            return .traditionalStrengthTraining
        case .endurance:
            return .running  // Default endurance type
        case .other:
            return .other
        }
    }
    
    // Konverter fra HKWorkoutActivityType
    static func from(healthKitType: HKWorkoutActivityType) -> WorkoutCategory {
        switch healthKitType {
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return .strength
        case .running, .walking, .cycling, .swimming, .hiking, .rowing:
            return .endurance
        default:
            return .other
        }
    }
    
    // Alle tilgjengelige HealthKit aktivitetstyper
    static var allHealthKitTypes: [HKWorkoutActivityType] {
        [
            .traditionalStrengthTraining,
            .functionalStrengthTraining,
            .running,
            .walking,
            .cycling,
            .swimming,
            .hiking,
            .rowing,
            .crossTraining,
            .yoga,
            .pilates,
            .boxing,
            .other
        ]
    }
    
    // Hent lesbar tekst for HKWorkoutActivityType
    static func name(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Training"
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .rowing: return "Rowing"
        case .crossTraining: return "Cross Training"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .boxing: return "Boxing"
        case .other: return "Other"
        default: return "Unknown"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .strength:
            return .red
        case .endurance:
            return .green
        case .other:
            return .yellow
        }
    }
    
    var defaultIcon: String {
        switch self {
        case .strength:
            return "figure.strengthtraining.traditional"
        case .endurance:
            return "figure.run"  // Dette blir bare brukt for nye utholdenhetstreningstyper
        case .other:
            return "figure.mixed.cardio"
        }
    }
}

enum WorkoutLayout: String, CaseIterable, Identifiable {
    case strength = "Strength (Weight/Reps)"
    case endurance = "Endurance (Time/Dist)"
    case basic = "Basic (Time only)"
    
    var id: String { rawValue }
} 