import SwiftUI
import CoreData

struct WorkoutLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedDate: Date
    let selectedCategory: WorkoutCategory
    
    @State private var selectedLayout: WorkoutLayout
    @State private var exercises: [CDExercise] = []
    @State private var notes = ""
    @State private var calories = ""
    @State private var bodyWeight = ""
    @State private var showingSaveTemplateAlert = false
    @State private var newTemplateName = ""
    @State private var showingAddExercise = false
    @State private var newExerciseName = ""
    
    @FetchRequest private var templates: FetchedResults<CDWorkoutTemplate>
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    init(selectedDate: Binding<Date>, selectedCategory: WorkoutCategory) {
        self._selectedDate = selectedDate
        self.selectedCategory = selectedCategory
        self._selectedLayout = State(initialValue: selectedCategory.defaultLayout)
        
        let predicate = NSPredicate(format: "type == %@", selectedCategory.rawValue)
        _templates = FetchRequest(
            fetchRequest: CDWorkoutTemplate.fetchRequest(predicate),
            animation: .default
        )
    }
    
    private func saveWorkout() {
        let context = viewContext
        
        // Opprett ny treningsøkt
        let workout = CDWorkoutSession(context: context)
        workout.id = UUID()
        workout.date = selectedDate
        workout.type = selectedCategory == .other ? 
            "\(selectedCategory.rawValue) (\(selectedLayout.rawValue))" : 
            selectedCategory.rawValue
        workout.notes = notes
        workout.calories = calories
        workout.bodyWeight = bodyWeight
        
        // Lagre øvelser
        for exercise in exercises {
            exercise.session = workout
        }
        
        // Lagre endringer
        do {
            try context.save()
            if hasTemplateChanges() {
                showingSaveTemplateAlert = true
            } else {
                dismiss()
            }
        } catch {
            print("Error saving workout: \(error)")
        }
    }
    
    private func saveTemplate() {
        let template = CDWorkoutTemplate(context: viewContext)
        template.id = UUID()
        template.name = newTemplateName
        template.type = selectedCategory.rawValue
        
        // Lagre øvelsesmaler
        for exercise in exercises {
            let templateExercise = CDExerciseTemplate(context: viewContext)
            templateExercise.id = UUID()
            templateExercise.name = exercise.name
            templateExercise.defaultSets = Int16(exercise.setArray.count)
            templateExercise.template = template
        }
        
        do {
            try viewContext.save()
            showingSaveTemplateAlert = false
            newTemplateName = ""
            dismiss()
        } catch {
            print("Error saving template: \(error)")
        }
    }
    
    private func hasTemplateChanges() -> Bool {
        // Sjekk om det finnes en eksisterende mal for denne treningstypen
        let existingTemplate = templates.first { $0.type == selectedCategory.rawValue }
        
        // Hvis det ikke finnes en mal, og vi har øvelser, foreslå å lagre som mal
        if existingTemplate == nil && !exercises.isEmpty {
            return true
        }
        
        // Hvis det finnes en mal, sjekk om øvelsene er forskjellige
        if let template = existingTemplate {
            let templateExercises = Set(template.exerciseArray.map { $0.name ?? "" })
            let currentExercises = Set(exercises.map { $0.name ?? "" })
            
            return templateExercises != currentExercises
        }
        
        return false
    }
    
    private func addNewExercise() {
        let exercise = CDExercise(context: viewContext)
        exercise.id = UUID()
        exercise.name = newExerciseName
        
        // Legg til standard sett basert på type
        let set = CDSetData(context: viewContext)
        set.id = UUID()
        set.exercise = exercise
        
        exercises.append(exercise)
        newExerciseName = ""
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Type økt
                VStack(alignment: .leading) {
                    Text("Type økt:")
                        .fontWeight(.medium)
                    TextField("", text: .constant(selectedCategory.rawValue))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(true)
                }
                
                // Vis layout-velger kun for "Annen trening"
                if selectedCategory == .other {
                    VStack(alignment: .leading) {
                        Text("Velg oppsett:")
                            .fontWeight(.medium)
                        Picker("Oppsett", selection: $selectedLayout) {
                            ForEach(WorkoutLayout.allCases, id: \.self) { layout in
                                Text(layout.rawValue).tag(layout)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                // Øvelser
                ForEach(exercises.indices, id: \.self) { index in
                    ExerciseView(exercise: $exercises[index])
                }
                
                // Legg til øvelse knapp
                Button(action: {
                    showingAddExercise = true
                }) {
                    Label("Legg til øvelse", systemImage: "plus.circle.fill")
                }
                
                // Noter
                VStack(alignment: .leading) {
                    Text("Noter:")
                        .fontWeight(.medium)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.2))
                }
                
                // Kalorier og kroppsvekt
                HStack {
                    VStack(alignment: .leading) {
                        Text("Kalorier:")
                            .fontWeight(.medium)
                        TextField("kcal", text: $calories)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Kroppsvekt:")
                            .fontWeight(.medium)
                        TextField("kg", text: $bodyWeight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Ny økt")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Lagre") {
                    saveWorkout()
                }
            }
        }
        .alert("Lagre som mal", isPresented: $showingSaveTemplateAlert) {
            TextField("Malnavn", text: $newTemplateName)
            Button("Avbryt", role: .cancel) {
                showingSaveTemplateAlert = false
            }
            Button("Lagre") {
                saveTemplate()
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(newExerciseName: $newExerciseName)
        }
    }
}

struct WorkoutLogView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutLogView(selectedDate: .constant(Date()), selectedCategory: .strength)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 