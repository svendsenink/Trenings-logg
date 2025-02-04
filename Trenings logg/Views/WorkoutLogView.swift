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
    @State private var selectedTemplate: CDWorkoutTemplate?
    @State private var showingTemplateOptions = false
    @State private var showingTemplateManager = false
    
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
        
        // For "Other training", bruk malnavnet
        if selectedCategory == .other {
            if let template = selectedTemplate {
                workout.type = "\(selectedCategory.rawValue) (\(template.name ?? ""))"
            } else {
                workout.type = "\(selectedCategory.rawValue) (\(selectedLayout.rawValue))"
            }
        } else {
            workout.type = selectedCategory.rawValue
        }
        
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
            
            // Spør om å lagre som mal hvis:
            // 1. Det er endringer i en eksisterende mal, eller
            // 2. Det er en ny økt med øvelser og ingen mal er valgt
            if hasTemplateChanges() || (selectedTemplate == nil && !exercises.isEmpty) {
                showingSaveTemplateAlert = true
                newTemplateName = selectedTemplate?.name ?? ""
            } else {
                dismiss()
            }
        } catch {
            print("Error saving workout: \(error)")
        }
    }
    
    private func saveTemplate() {
        // Sjekk om navnet allerede eksisterer for denne treningstypen
        if templates.contains(where: { 
            $0.name?.lowercased() == newTemplateName.lowercased() && 
            $0.type == selectedCategory.rawValue 
        }) {
            showingTemplateOptions = true
            return
        }
        
        createNewTemplate()
    }
    
    private func createNewTemplate() {
        let template = CDWorkoutTemplate(context: viewContext)
        template.id = UUID()
        template.name = newTemplateName
        template.type = selectedCategory.rawValue
        template.layout = selectedLayout.rawValue  // Lagre valgt layout
        
        saveExercisesToTemplate(template)
    }
    
    // Ny funksjon for å oppdatere eksisterende mal
    private func updateExistingTemplate() {
        guard let existingTemplate = templates.first(where: { $0.name == newTemplateName }) else { return }
        
        // Slett eksisterende øvelser
        for exercise in existingTemplate.exerciseArray {
            viewContext.delete(exercise)
        }
        
        saveExercisesToTemplate(existingTemplate)
    }
    
    // Helper funksjon for å lagre øvelser til mal
    private func saveExercisesToTemplate(_ template: CDWorkoutTemplate) {
        for exercise in exercises {
            let templateExercise = CDExerciseTemplate(context: viewContext)
            templateExercise.id = UUID()
            templateExercise.name = exercise.name
            templateExercise.defaultSets = Int16(exercise.setArray.count)
            templateExercise.increaseNextTime = exercise.increaseNextTime
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
        guard let template = selectedTemplate else { return false }
        
        // Sjekk om antall øvelser er endret
        if template.exerciseArray.count != exercises.count {
            return true
        }
        
        // For hver øvelse, sjekk om antall sett er endret
        for (index, exercise) in exercises.enumerated() {
            let templateExercise = template.exerciseArray[index]
            
            // Sjekk om øvelsesnavnet er endret
            if exercise.name != templateExercise.name {
                return true
            }
            
            // Sjekk om antall sett er endret
            if exercise.setArray.count != Int(templateExercise.defaultSets) {
                return true
            }
        }
        
        // Ingen strukturelle endringer funnet
        return false
    }
    
    private func addNewExercise() {
        let exercise = CDExercise(context: viewContext)
        exercise.id = UUID()
        exercise.name = newExerciseName
        
        // Legg til standard sett basert på valgt layout
        if selectedCategory == .other {
            switch selectedLayout {
            case .strength:
                // For styrke - legg til sett med vekt og reps
                let set = CDSetData(context: viewContext)
                set.id = UUID()
                set.exercise = exercise
                set.weight = ""
                set.reps = ""
            case .endurance:
                // For utholdenhet - legg til sett med tid og distanse
                let set = CDSetData(context: viewContext)
                set.id = UUID()
                set.exercise = exercise
                set.duration = ""
                set.distance = ""
                set.incline = ""
                set.reps = "" // for speed
            case .basic:
                // For basic - legg til bare tid
                let set = CDSetData(context: viewContext)
                set.id = UUID()
                set.exercise = exercise
                set.duration = ""
            }
        }
        
        exercises.append(exercise)
        newExerciseName = ""
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving exercise: \(error)")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Type økt
                VStack(alignment: .leading) {
                    Text("Workout type:")
                        .fontWeight(.medium)
                    TextField("", text: .constant(selectedCategory.rawValue))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(true)
                }
                
                // Velg mal
                if !templates.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Select template:")
                                .fontWeight(.medium)
                            Spacer()
                            Button(action: {
                                showingTemplateManager = true
                            }) {
                                Image(systemName: "gear")
                            }
                        }
                        Picker("Select template", selection: $selectedTemplate) {
                            Text("No template").tag(nil as CDWorkoutTemplate?)
                            ForEach(templates) { template in
                                Text(template.name ?? "").tag(template as CDWorkoutTemplate?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedTemplate) { _, template in
                            if let template = template {
                                loadTemplate(template)
                            }
                        }
                    }
                }
                
                // Øvelser
                ForEach(exercises.indices, id: \.self) { index in
                    ExerciseView(
                        exercise: $exercises[index],
                        selectedCategory: selectedCategory,
                        selectedLayout: selectedLayout
                    )
                }
                
                // Legg til øvelse knapp
                Button(action: {
                    showingAddExercise = true
                }) {
                    Label("Add exercise", systemImage: "plus.circle.fill")
                }
                
                // Noter
                VStack(alignment: .leading) {
                    Text("Notes:")
                        .fontWeight(.medium)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.2))
                }
                
                // Kalorier og kroppsvekt
                HStack {
                    VStack(alignment: .leading) {
                        Text("Calories:")
                            .fontWeight(.medium)
                        TextField("kcal", text: $calories)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Body weight:")
                            .fontWeight(.medium)
                        TextField("kg", text: $bodyWeight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("New workout")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveWorkout()
                }
            }
        }
        .alert("Update template", isPresented: $showingSaveTemplateAlert) {
            if let templateName = selectedTemplate?.name {
                Text("Would you like to update the template '\(templateName)' with these changes?")
                Button("Cancel", role: .cancel) {
                    showingSaveTemplateAlert = false
                    dismiss()
                }
                Button("Update", role: .destructive) {
                    updateExistingTemplate()
                }
            } else {
                TextField("Template name", text: $newTemplateName)
                Button("Cancel", role: .cancel) {
                    showingSaveTemplateAlert = false
                    dismiss()
                }
                Button("Save") {
                    saveTemplate()
                }
            }
        }
        .alert("Template exists", isPresented: $showingTemplateOptions) {
            Button("Cancel", role: .cancel) {
                showingTemplateOptions = false
                newTemplateName = ""
            }
            Button("Update existing", role: .destructive) {
                updateExistingTemplate()
            }
            Button("Create new with different name") {
                showingTemplateOptions = false
            }
        } message: {
            Text("A template with this name already exists. Do you want to update the existing template or create a new one with a different name?")
        }
        .sheet(isPresented: $showingAddExercise) {
            NavigationStack {
                AddExerciseView(
                    newExerciseName: $newExerciseName,
                    selectedLayout: $selectedLayout,
                    isFirstExercise: exercises.isEmpty,  // Vis layout-velger kun hvis ingen øvelser
                    onAdd: {
                        addNewExercise()
                        showingAddExercise = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingTemplateManager) {
            TemplateManagerView()
        }
    }
    
    // Oppdater loadTemplate funksjonen
    private func loadTemplate(_ template: CDWorkoutTemplate) {
        // Last inn layout hvis det er "other" kategori
        if selectedCategory == .other, 
           let layoutString = template.layout,
           let layout = WorkoutLayout.allCases.first(where: { $0.rawValue == layoutString }) {
            selectedLayout = layout
        }
        
        // Først, hent siste økt med samme mal
        let request = CDWorkoutSession.fetchRequest(NSPredicate(format: "type CONTAINS %@", selectedCategory.rawValue))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWorkoutSession.date, ascending: false)]
        request.fetchLimit = 1
        
        // Fjern eksisterende øvelser
        for exercise in exercises {
            viewContext.delete(exercise)
        }
        exercises = []
        
        // Legg til øvelser fra malen
        for templateExercise in template.exerciseArray {
            let exercise = CDExercise(context: viewContext)
            exercise.id = UUID()
            exercise.name = templateExercise.name
            exercise.increaseNextTime = templateExercise.increaseNextTime
            
            // Finn matching øvelse fra siste økt
            if let lastSession = try? viewContext.fetch(request).first,
               let lastExercise = lastSession.exerciseArray.first(where: { $0.name == templateExercise.name }) {
                // Kopier sett fra siste økt
                for lastSet in lastExercise.setArray {
                    let set = CDSetData(context: viewContext)
                    set.id = UUID()
                    set.exercise = exercise
                    
                    // Kopier verdiene direkte
                    set.weight = lastSet.weight
                    set.reps = lastSet.reps
                    set.duration = lastSet.duration
                    set.distance = lastSet.distance
                    set.incline = lastSet.incline
                    set.restPeriod = lastSet.restPeriod
                }
            } else {
                // Hvis ingen tidligere økt, legg til tomme sett
                for _ in 0..<templateExercise.defaultSets {
                    let set = CDSetData(context: viewContext)
                    set.id = UUID()
                    set.exercise = exercise
                }
            }
            
            exercises.append(exercise)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error loading template: \(error)")
        }
    }
}

struct WorkoutLogView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutLogView(selectedDate: .constant(Date()), selectedCategory: .strength)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 