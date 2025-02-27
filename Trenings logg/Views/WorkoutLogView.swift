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
    @State private var selectedTime = Date()
    
    @FetchRequest private var templates: FetchedResults<CDWorkoutTemplate>
    
    @State private var autoSaveTimer: Timer?
    
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
        
        // Kombiner valgt dato med valgt tid
        let calendar = Calendar.current
        let selectedComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        dateComponents.hour = selectedComponents.hour
        dateComponents.minute = selectedComponents.minute
        workout.date = calendar.date(from: dateComponents)
        
        // Legg til malnavn i type hvis en mal er valgt
        if let template = selectedTemplate {
            workout.type = "\(selectedCategory.rawValue) - \(template.name ?? "")"
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
            templateExercise.template = template
            templateExercise.increaseNextTime = exercise.increaseNextTime
            templateExercise.defaultSets = Int16(exercise.setArray.count)
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
        exercise.layout = selectedLayout.rawValue  // Lagre layout for denne øvelsen
        
        // Legg til standard sett basert på valgt layout
        let set = CDSetData(context: viewContext)
        set.id = UUID()
        set.exercise = exercise
        
        switch selectedLayout {
        case .strength:
            set.weight = ""
            set.reps = ""
        case .endurance:
            set.duration = ""
            set.distance = ""
            set.incline = ""
            set.reps = "" // for speed
        case .basic:
            set.duration = ""
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
                // Velg mal
                HStack {
                    Text("Select template:")
                        .fontWeight(.medium)
                    Spacer()
                    Button(action: {
                        showingTemplateManager = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                    }
                }
                
                Picker("Template", selection: $selectedTemplate) {
                    Text("No template")
                        .tag(nil as CDWorkoutTemplate?)
                    
                    if !templates.isEmpty {
                        Divider()
                        ForEach(templates) { template in
                            Text(template.name ?? "")
                                .tag(template as CDWorkoutTemplate?)
                        }
                    }
                }
                .pickerStyle(.menu)
                .tint(.blue)
                
                // Øvelser
                ForEach($exercises) { $exercise in
                    ExerciseView(
                        exercise: $exercise,
                        selectedCategory: selectedCategory,
                        selectedLayout: selectedLayout
                    )
                }
                
                Button(action: {
                    showingAddExercise = true
                }) {
                    Label("Add exercise", systemImage: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
                
                // Noter
                VStack(alignment: .leading) {
                    Text("Notes:")
                        .fontWeight(.medium)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
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
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading) {
                        Text("Body weight:")
                            .fontWeight(.medium)
                        TextField("kg", text: $bodyWeight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle(selectedCategory.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveWorkout()
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            NavigationView {
                AddExerciseView(
                    newExerciseName: $newExerciseName,
                    selectedLayout: $selectedLayout,
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
        .alert("Save as template?", isPresented: $showingSaveTemplateAlert) {
            TextField("Template name", text: $newTemplateName)
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            Button(selectedTemplate != nil ? "Update" : "Save") {
                if selectedTemplate != nil {
                    updateExistingTemplate()
                } else {
                    saveTemplate()
                }
            }
        } message: {
            if selectedTemplate != nil {
                Text("Do you want to update the existing template with these changes?")
            } else {
                Text("Would you like to save this workout as a template for future use?")
            }
        }
        .onAppear {
            selectedTime = Date()
            if let template = selectedTemplate {
                loadTemplate(template)
            }
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
            print("Loading exercise: \(templateExercise.name ?? ""), defaultSets: \(templateExercise.defaultSets)")
            let exercise = CDExercise(context: viewContext)
            exercise.id = UUID()
            exercise.name = templateExercise.name
            exercise.increaseNextTime = templateExercise.increaseNextTime
            exercise.layout = template.layout  // Sett layout fra malen
            
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
                // Hvis ingen tidligere økt finnes, legg til standard antall sett fra malen
                for _ in 0..<templateExercise.defaultSets {
                    let set = CDSetData(context: viewContext)
                    set.id = UUID()
                    set.exercise = exercise
                    
                    // Initialiser tomme felt basert på layout
                    switch WorkoutLayout(rawValue: template.layout ?? "") {
                    case .strength:
                        set.weight = ""
                        set.reps = ""
                    case .endurance:
                        set.duration = ""
                        set.distance = ""
                        set.incline = ""
                        set.reps = "" // for speed
                    case .basic:
                        set.duration = ""
                    case .none:
                        break
                    }
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