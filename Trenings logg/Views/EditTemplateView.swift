import SwiftUI

struct EditTemplateView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @Environment(\.dismiss) private var dismiss
    
    let template: WorkoutTemplate
    @State private var exercises: [ExerciseTemplate]
    @State private var isLoading = true
    @State private var showingAddExercise = false
    @State private var newExerciseName = ""
    @State private var newExerciseSets = 3
    
    init(template: WorkoutTemplate) {
        self.template = template
        self._exercises = State(initialValue: template.exercises ?? [])
    }
    
    private func addExercise() {
        let newExercise = ExerciseTemplate(
            name: newExerciseName,
            layout: .basic,
            defaultSets: newExerciseSets
        )
        exercises.append(newExercise)
        
        // Oppdater malen
        var updatedTemplate = template
        updatedTemplate.exercises = exercises
        
        Task {
            do {
                try await cloudKitManager.saveTemplate(updatedTemplate)
                newExerciseName = ""
                showingAddExercise = false
            } catch {
                print("Error saving template: \(error)")
            }
        }
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        
        // Oppdater malen
        var updatedTemplate = template
        updatedTemplate.exercises = exercises
        
        Task {
            do {
                try await cloudKitManager.saveTemplate(updatedTemplate)
            } catch {
                print("Error saving template: \(error)")
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(exercises.indices, id: \.self) { index in
                HStack {
                    Text(exercises[index].name)
                    Spacer()
                    Text("\(exercises[index].defaultSets) sett")
                        .foregroundColor(.gray)
                }
            }
            .onDelete(perform: deleteExercise)
            
            Button(action: { showingAddExercise = true }) {
                Label("Legg til øvelse", systemImage: "plus")
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Legg til øvelse", isPresented: $showingAddExercise) {
            VStack {
                TextField("Navn på øvelse", text: $newExerciseName)
                Stepper("Antall sett: \(newExerciseSets)", value: $newExerciseSets, in: 1...10)
            }
            Button("Avbryt", role: .cancel) { }
            Button("Legg til") {
                addExercise()
            }
        }
    }
}

#Preview {
    NavigationView {
        EditTemplateView(
            template: WorkoutTemplate(
                name: "Overkropp",
                type: "Styrke",
                exercises: [
                    ExerciseTemplate(name: "Benkpress", defaultSets: 3),
                    ExerciseTemplate(name: "Skulderpress", defaultSets: 3)
                ]
            )
        )
        .environmentObject(CloudKitManager.shared)
    }
} 