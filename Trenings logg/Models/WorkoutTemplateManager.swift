import Foundation

// Flytt WorkoutCategory ut av klassen så den er tilgjengelig overalt
public enum WorkoutCategory: String, CaseIterable {
    case strength = "Styrke"
    case endurance = "Utholdenhetstrening"
    case other = "Annen trening"  // Endret fra climbing og yoga til en mer generell kategori
}

class WorkoutTemplateManager: ObservableObject {
    @Published var templates: [WorkoutTemplate] = [] {
        didSet {
            saveTemplates()  // Automatisk lagring når templates endres
        }
    }
    
    static let defaultTemplates: [WorkoutTemplate] = [
        // Styrke-maler
        WorkoutTemplate(
            name: "Overkropp",
            type: WorkoutCategory.strength.rawValue,
            exercises: [
                ExerciseTemplate(name: "Benkpress", defaultSets: 4),
                ExerciseTemplate(name: "Skulderpress", defaultSets: 3),
                ExerciseTemplate(name: "Triceps Extensions", defaultSets: 3),
                ExerciseTemplate(name: "Biceps Curl", defaultSets: 3)
            ]
        ),
        WorkoutTemplate(
            name: "Underkropp",
            type: "Styrke",
            exercises: [
                ExerciseTemplate(name: "Knebøy", defaultSets: 4),
                ExerciseTemplate(name: "Markløft", defaultSets: 4),
                ExerciseTemplate(name: "Leg Press", defaultSets: 3),
                ExerciseTemplate(name: "Calf Raises", defaultSets: 3)
            ]
        ),
        
        // Utholdenhetstrening-maler
        WorkoutTemplate(
            name: "Løping Intervall",
            type: WorkoutCategory.endurance.rawValue,
            exercises: [
                ExerciseTemplate(name: "Oppvarming (10 min)", defaultSets: 1),
                ExerciseTemplate(name: "4x4 Intervaller", defaultSets: 4),
                ExerciseTemplate(name: "Nedkjøling (5 min)", defaultSets: 1)
            ]
        ),
        WorkoutTemplate(
            name: "Sykling",
            type: "Utholdenhetstrening",
            exercises: [
                ExerciseTemplate(name: "Distanse/Tid", defaultSets: 1)
            ]
        ),
        
        // Annen trening-maler
        WorkoutTemplate(
            name: "Klatring",
            type: WorkoutCategory.other.rawValue,
            exercises: [
                ExerciseTemplate(name: "Klatring", defaultSets: 1)
            ]
        ),
        WorkoutTemplate(
            name: "Yoga",
            type: WorkoutCategory.other.rawValue,
            exercises: [
                ExerciseTemplate(name: "Yoga", defaultSets: 1)
            ]
        )
    ]
    
    init() {
        loadTemplates()
    }
    
    func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: "WorkoutTemplates"),
           let decoded = try? JSONDecoder().decode([WorkoutTemplate].self, from: data) {
            // Sorter malene når de lastes
            templates = decoded.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            // Sorter standardmalene
            templates = Self.defaultTemplates.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
    
    func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: "WorkoutTemplates")
        }
    }
} 