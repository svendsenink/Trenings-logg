import SwiftUI
import CoreData

struct WorkoutEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let session: CDWorkoutSession
    @State private var notes: String
    @State private var calories: String
    @State private var bodyWeight: String
    
    init(session: CDWorkoutSession) {
        self.session = session
        self._notes = State(initialValue: session.notes ?? "")
        self._calories = State(initialValue: session.calories ?? "")
        self._bodyWeight = State(initialValue: session.bodyWeight ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(session.exerciseArray) { exercise in
                    VStack(alignment: .leading) {
                        Text(exercise.name ?? "")
                            .font(.headline)
                        
                        ForEach(exercise.setArray) { set in
                            HStack {
                                if let reps = set.reps {
                                    TextField("Reps", text: Binding(
                                        get: { reps },
                                        set: { set.reps = $0 }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                if let weight = set.weight {
                                    TextField("Kg", text: Binding(
                                        get: { weight },
                                        set: { set.weight = $0 }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                    }
                    Divider()
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
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Kroppsvekt:")
                            .font(.headline)
                        TextField("kg", text: $bodyWeight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Button("Lagre endringer") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Rediger økt")
        .navigationBarItems(trailing: Button("Avbryt") { dismiss() })
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