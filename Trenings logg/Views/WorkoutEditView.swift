import SwiftUI
import CoreData

struct WorkoutEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let session: CDWorkoutSession
    @State private var notes: String
    @State private var calories: String
    @State private var bodyWeight: String
    @State private var exercises: [CDExercise]
    
    init(session: CDWorkoutSession) {
        self.session = session
        self._notes = State(initialValue: session.notes ?? "")
        self._calories = State(initialValue: session.calories ?? "")
        self._bodyWeight = State(initialValue: session.bodyWeight ?? "")
        self._exercises = State(initialValue: session.exerciseArray)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach($exercises) { $exercise in
                    ExerciseView(
                        exercise: $exercise,
                        selectedCategory: WorkoutCategory.from(healthKitType: .other),
                        selectedLayout: WorkoutLayout(rawValue: exercise.layout ?? "") ?? .basic
                    )
                }
                
                VStack(alignment: .leading) {
                    Text("Noter:")
                        .font(.headline)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.2))
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Kalorier:")
                            .font(.headline)
                        TextField("kcal", text: $calories)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Kroppsvekt:")
                            .font(.headline)
                        TextField("kg", text: $bodyWeight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Rediger økt")
        .navigationBarItems(
            leading: Button("Avbryt") { dismiss() },
            trailing: Button("Lagre") { saveChanges() }
        )
    }
    
    private func saveChanges() {
        session.notes = notes
        session.calories = calories
        session.bodyWeight = bodyWeight
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
} 