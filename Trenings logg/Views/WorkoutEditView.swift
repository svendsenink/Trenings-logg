import SwiftUI

struct WorkoutEditView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @Environment(\.dismiss) private var dismiss
    
    let session: WorkoutSession
    @State private var notes: String
    @State private var calories: String
    @State private var bodyWeight: String
    @State private var exercises: [Exercise] = []
    @State private var isLoading = true
    
    init(session: WorkoutSession) {
        self.session = session
        self._notes = State(initialValue: session.notes ?? "")
        self._calories = State(initialValue: session.calories.map(String.init) ?? "")
        self._bodyWeight = State(initialValue: session.bodyWeight ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(exercises) { exercise in
                        ExerciseEditView(exercise: exercise)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Noter:")
                            .font(.headline)
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .border(Color.gray.opacity(0.2))
                    }
                    .padding()
                    
                    VStack(alignment: .leading) {
                        Text("Kalorier:")
                            .font(.headline)
                        TextField("Kalorier", text: $calories)
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    
                    VStack(alignment: .leading) {
                        Text("Kroppsvekt:")
                            .font(.headline)
                        TextField("Kroppsvekt", text: $bodyWeight)
                            .keyboardType(.decimalPad)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Rediger treningsøkt")
        .navigationBarItems(
            trailing: Button("Lagre") {
                saveWorkout()
            }
        )
        .task {
            await loadExercises()
        }
    }
    
    private func loadExercises() async {
        isLoading = true
        do {
            exercises = try await cloudKitManager.fetchExercises(for: session.id)
        } catch {
            print("Error loading exercises: \(error)")
        }
        isLoading = false
    }
    
    private func saveWorkout() {
        Task {
            do {
                let updatedSession = WorkoutSession(
                    id: session.id,
                    date: session.date,
                    type: session.type,
                    notes: notes.isEmpty ? nil : notes,
                    bodyWeight: bodyWeight.isEmpty ? nil : bodyWeight,
                    calories: calories.isEmpty ? nil : Int(calories),
                    healthKitId: session.healthKitId
                )
                try await cloudKitManager.saveWorkoutSession(updatedSession)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error saving workout: \(error)")
            }
        }
    }
}

struct ExerciseEditView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @State private var sets: [SetData] = []
    @State private var isLoading = true
    
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.name)
                .font(.headline)
            
            if isLoading {
                ProgressView()
            } else {
                ForEach(sets) { set in
                    SetEditView(set: set, layout: exercise.layout, exerciseId: exercise.id)
                }
            }
        }
        .padding()
        .task {
            await loadSets()
        }
    }
    
    private func loadSets() async {
        isLoading = true
        do {
            sets = try await cloudKitManager.fetchSets(for: exercise.id)
        } catch {
            print("Error loading sets: \(error)")
        }
        isLoading = false
    }
}

struct SetEditView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @State private var weight: String
    @State private var reps: String
    @State private var duration: String
    @State private var distance: String
    @State private var incline: String
    @State private var restPeriod: String
    
    let set: SetData
    let layout: WorkoutLayout
    let exerciseId: String
    
    init(set: SetData, layout: WorkoutLayout, exerciseId: String) {
        self.set = set
        self.layout = layout
        self.exerciseId = exerciseId
        self._weight = State(initialValue: set.weight ?? "")
        self._reps = State(initialValue: set.reps ?? "")
        self._duration = State(initialValue: set.duration ?? "")
        self._distance = State(initialValue: set.distance ?? "")
        self._incline = State(initialValue: set.incline ?? "")
        self._restPeriod = State(initialValue: set.restPeriod ?? "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch layout {
            case .strength:
                HStack {
                    TextField("Vekt", text: $weight)
                        .keyboardType(.decimalPad)
                    Text("kg")
                    TextField("Reps", text: $reps)
                        .keyboardType(.numberPad)
                    Text("reps")
                }
            case .endurance:
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        TextField("Varighet", text: $duration)
                            .keyboardType(.numberPad)
                        Text("min")
                        TextField("Distanse", text: $distance)
                            .keyboardType(.decimalPad)
                        Text("km")
                    }
                    HStack {
                        TextField("Hastighet", text: $reps)
                            .keyboardType(.decimalPad)
                        Text("km/h")
                        TextField("Stigning", text: $incline)
                            .keyboardType(.decimalPad)
                        Text("°")
                    }
                    HStack {
                        TextField("Hvileperiode", text: $restPeriod)
                            .keyboardType(.numberPad)
                        Text("min")
                    }
                }
            case .basic:
                HStack {
                    TextField("Varighet", text: $duration)
                        .keyboardType(.numberPad)
                    Text("min")
                }
            }
        }
        .onChange(of: weight) { oldValue, newValue in
            Task { await MainActor.run { saveSet() } }
        }
        .onChange(of: reps) { oldValue, newValue in
            Task { await MainActor.run { saveSet() } }
        }
        .onChange(of: duration) { oldValue, newValue in
            Task { await MainActor.run { saveSet() } }
        }
        .onChange(of: distance) { oldValue, newValue in
            Task { await MainActor.run { saveSet() } }
        }
        .onChange(of: incline) { oldValue, newValue in
            Task { await MainActor.run { saveSet() } }
        }
        .onChange(of: restPeriod) { oldValue, newValue in
            Task { await MainActor.run { saveSet() } }
        }
    }
    
    private func saveSet() {
        Task {
            do {
                let updatedSet = SetData(
                    id: set.id,
                    weight: weight,
                    reps: reps,
                    duration: duration,
                    distance: distance,
                    incline: incline,
                    restPeriod: restPeriod,
                    order: set.order
                )
                try await cloudKitManager.saveSet(updatedSet, for: exerciseId)
            } catch {
                print("Error saving set: \(error)")
            }
        }
    }
}

#Preview {
    NavigationView {
        WorkoutEditView(
            session: WorkoutSession(
                date: Date(),
                type: "Strength",
                notes: "Test notes",
                bodyWeight: "80",
                calories: 500
            )
        )
        .environmentObject(CloudKitManager.shared)
    }
} 