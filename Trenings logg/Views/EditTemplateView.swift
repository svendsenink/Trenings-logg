import SwiftUI
import CoreData

struct EditTemplateView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let template: CDWorkoutTemplate
    @State private var name: String
    @FetchRequest private var exercises: FetchedResults<CDExerciseTemplate>
    
    init(template: CDWorkoutTemplate) {
        self.template = template
        _name = State(initialValue: template.name ?? "")
        
        let predicate = NSPredicate(format: "template == %@", template)
        let sortDescriptor = NSSortDescriptor(keyPath: \CDExerciseTemplate.order, ascending: true)
        
        _exercises = FetchRequest(
            fetchRequest: CDExerciseTemplate.fetchRequest(predicate, sortDescriptors: [sortDescriptor]),
            animation: .default
        )
    }
    
    var body: some View {
        Form {
            Section(header: Text("Template Name")) {
                TextField("Name", text: $name)
            }
            
            Section(header: Text("Exercises")) {
                ForEach(exercises) { exercise in
                    HStack {
                        Text(exercise.name ?? "")
                        Spacer()
                        Text("\(exercise.defaultSets) sets")
                            .foregroundColor(.gray)
                    }
                }
                .onMove(perform: moveExercise)
                .onDelete(perform: deleteExercise)
            }
        }
        .navigationTitle("Edit Template")
        .navigationBarItems(
            trailing: Button("Save") {
                saveTemplate()
            }
        )
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        var updatedExercises = exercises.map { $0 }
        updatedExercises.move(fromOffsets: source, toOffset: destination)
        
        // Oppdater rekkefølgen i Core Data
        for (index, exercise) in updatedExercises.enumerated() {
            exercise.order = Int16(index)
        }
        
        try? viewContext.save()
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        withAnimation {
            offsets.map { exercises[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
    
    private func saveTemplate() {
        template.name = name
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving template: \(error)")
        }
    }
} 