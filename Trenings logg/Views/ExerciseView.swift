import SwiftUI

struct ExerciseView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @Binding var exercise: Exercise
    let selectedCategory: WorkoutCategory
    let selectedLayout: WorkoutLayout
    
    @State private var sets: [SetData] = []
    @State private var showingDeleteAlert = false
    @State private var isLoading = true
    
    @FocusState private var focusedField: String?
    @State private var isEditing: Set<String> = []
    @State private var previousValues: [String: String] = [:]
    @State private var justGotFocus: Set<String> = []
    
    private func addSet() {
        let newSet = SetData(
            id: UUID().uuidString,
            weight: "",
            reps: "",
            duration: "",
            distance: "",
            incline: "",
            restPeriod: "",
            order: sets.count
        )
        sets.append(newSet)
        
        Task {
            do {
                try await cloudKitManager.saveSet(newSet, for: exercise.id)
            } catch {
                print("Error saving set: \(error)")
            }
        }
    }
    
    private func deleteSet(_ setToDelete: SetData) {
        if let index = sets.firstIndex(where: { $0.id == setToDelete.id }) {
            sets.remove(at: index)
            // Oppdater rekkefølgen for gjenværende sett
            for i in index..<sets.count {
                sets[i].order = i
                
                Task {
                    do {
                        try await cloudKitManager.saveSet(sets[i], for: exercise.id)
                    } catch {
                        print("Error updating set order: \(error)")
                    }
                }
            }
        }
    }
    
    private func loadSets() async {
        do {
            let loadedSets = try await cloudKitManager.fetchSets(for: exercise.id)
            sets = loadedSets.sorted(by: { $0.order < $1.order })
            isLoading = false
        } catch {
            print("Error loading sets: \(error)")
            isLoading = false
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                
                Spacer()
                
                Toggle("Øk neste gang", isOn: $exercise.increaseNextTime)
                    .labelsHidden()
                    .tint(.blue)
            }
            
            if isLoading {
                ProgressView()
            } else {
                ForEach($sets) { $set in
                    switch selectedLayout {
                    case .strength:
                        HStack {
                            TextField("Vekt", text: Binding(
                                get: { set.weight ?? "" },
                                set: { set.weight = $0 }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            
                            TextField("Reps", text: Binding(
                                get: { set.reps ?? "" },
                                set: { set.reps = $0 }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            
                            Spacer()
                            
                            Button(action: { deleteSet(set) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        
                    case .endurance:
                        VStack {
                            HStack {
                                TextField("Tid", text: Binding(
                                    get: { set.duration ?? "" },
                                    set: { set.duration = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                
                                TextField("Distanse", text: Binding(
                                    get: { set.distance ?? "" },
                                    set: { set.distance = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                            }
                            
                            HStack {
                                TextField("Stigning", text: Binding(
                                    get: { set.incline ?? "" },
                                    set: { set.incline = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                
                                TextField("Fart", text: Binding(
                                    get: { set.reps ?? "" },
                                    set: { set.reps = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                
                                Button(action: { deleteSet(set) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                    case .basic:
                        HStack {
                            TextField("Tid", text: Binding(
                                get: { set.duration ?? "" },
                                set: { set.duration = $0 }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            
                            Spacer()
                            
                            Button(action: { deleteSet(set) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Button(action: addSet) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Legg til sett")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .task {
            await loadSets()
        }
    }
}

#Preview {
    ExerciseView(
        exercise: .constant(Exercise(name: "Benkpress", layout: .strength, increaseNextTime: false)),
        selectedCategory: .strength,
        selectedLayout: .strength
    )
    .environmentObject(CloudKitManager.shared)
} 