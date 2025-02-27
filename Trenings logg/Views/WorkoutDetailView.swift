import SwiftUI

struct WorkoutDetailView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    let workout: WorkoutSession
    
    @State private var exercises: [Exercise] = []
    @State private var sets: [String: [SetData]] = [:]
    @State private var isLoading = true
    
    private func loadExercises() async {
        do {
            exercises = try await cloudKitManager.fetchExercises(for: workout.id)
            
            // Last inn sett for hver øvelse
            for exercise in exercises {
                let exerciseSets = try await cloudKitManager.fetchSets(for: exercise.id)
                sets[exercise.id] = exerciseSets.sorted(by: { $0.order < $1.order })
            }
            
            isLoading = false
        } catch {
            print("Error loading exercises: \(error)")
            isLoading = false
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Detaljer")) {
                if let notes = workout.notes, !notes.isEmpty {
                    Text("Noter: \(notes)")
                }
                
                if let calories = workout.calories {
                    Text("Kalorier: \(calories)")
                }
                
                if let bodyWeight = workout.bodyWeight, !bodyWeight.isEmpty {
                    Text("Kroppsvekt: \(bodyWeight) kg")
                }
            }
            
            if isLoading {
                Section {
                    ProgressView()
                }
            } else {
                ForEach(exercises) { exercise in
                    Section(header: Text(exercise.name)) {
                        if let exerciseSets = sets[exercise.id] {
                            ForEach(exerciseSets) { set in
                                switch exercise.layout {
                                case .strength:
                                    if let weight = set.weight, let reps = set.reps {
                                        Text("\(weight) kg x \(reps) reps")
                                    }
                                    
                                case .endurance:
                                    VStack(alignment: .leading) {
                                        if let duration = set.duration {
                                            Text("Tid: \(duration) min")
                                        }
                                        if let distance = set.distance {
                                            Text("Distanse: \(distance) km")
                                        }
                                        if let speed = set.reps {
                                            Text("Fart: \(speed) km/t")
                                        }
                                        if let incline = set.incline {
                                            Text("Stigning: \(incline)°")
                                        }
                                    }
                                    
                                case .basic:
                                    if let duration = set.duration {
                                        Text("\(duration) min")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(workout.type)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadExercises()
        }
    }
}

#Preview {
    NavigationView {
        WorkoutDetailView(
            workout: WorkoutSession(
                date: Date(),
                type: "Styrke",
                notes: "God økt!",
                bodyWeight: "80",
                calories: 300
            )
        )
        .environmentObject(CloudKitManager.shared)
    }
} 