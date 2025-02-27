import SwiftUI

struct WorkoutLogView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedDate: Date
    let selectedCategory: WorkoutCategory
    
    @State private var selectedLayout: WorkoutLayout
    @State private var exercises: [Exercise] = []
    @State private var notes = ""
    @State private var calories = ""
    @State private var bodyWeight = ""
    @State private var showingSaveTemplateAlert = false
    @State private var newTemplateName = ""
    @State private var showingAddExercise = false
    @State private var newExerciseName = ""
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showingTemplateOptions = false
    @State private var showingTemplateManager = false
    @State private var selectedTime = Date()
    @State private var templates: [WorkoutTemplate] = []
    @State private var isLoading = true
    
    init(selectedDate: Binding<Date>, selectedCategory: WorkoutCategory) {
        self._selectedDate = selectedDate
        self.selectedCategory = selectedCategory
        self._selectedLayout = State(initialValue: selectedCategory.defaultLayout)
    }
    
    private func saveWorkout() {
        Task {
            do {
                // Opprett ny treningsøkt
                let workout = WorkoutSession(
                    id: UUID().uuidString,
                    date: selectedDate,
                    type: selectedTemplate != nil ? "\(selectedCategory.rawValue) - \(selectedTemplate!.name)" : selectedCategory.rawValue,
                    notes: notes.isEmpty ? nil : notes,
                    bodyWeight: bodyWeight.isEmpty ? nil : bodyWeight,
                    calories: calories.isEmpty ? nil : Int(calories),
                    healthKitId: nil
                )
                
                try await cloudKitManager.saveWorkoutSession(workout)
                
                // Lagre øvelser
                for exercise in exercises {
                    try await cloudKitManager.saveExercise(exercise, for: workout.id)
                }
                
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
    }
    
    private func hasTemplateChanges() -> Bool {
        guard let template = selectedTemplate else { return false }
        
        // Sjekk om antall øvelser er endret
        if template.exercises?.count != exercises.count {
            return true
        }
        
        // For hver øvelse, sjekk om navnet er endret
        for (index, exercise) in exercises.enumerated() {
            if let templateExercises = template.exercises,
               index < templateExercises.count,
               exercise.name != templateExercises[index].name {
                return true
            }
        }
        
        return false
    }
    
    private func addNewExercise() {
        let exercise = Exercise(
            name: newExerciseName,
            layout: selectedLayout,
            increaseNextTime: false
        )
        exercises.append(exercise)
        newExerciseName = ""
        showingAddExercise = false
    }
    
    private func loadTemplates() async {
        do {
            templates = try await cloudKitManager.fetchTemplates()
        } catch {
            print("Error loading templates: \(error)")
        }
    }
    
    private func loadTemplate(_ template: WorkoutTemplate) {
        selectedTemplate = template
        
        // Last inn layout hvis det er "other" kategori
        if selectedCategory == .other, let layout = template.layout {
            selectedLayout = layout
        }
        
        // Fjern eksisterende øvelser
        exercises = []
        
        // Legg til øvelser fra malen
        if let templateExercises = template.exercises {
            exercises = templateExercises.map { Exercise(id: UUID().uuidString, name: $0.name, layout: selectedLayout) }
        }
    }
    
    var body: some View {
        Form {
            if selectedCategory == .other {
                Picker("Layout", selection: $selectedLayout) {
                    ForEach(WorkoutLayout.allCases) { layout in
                        Text(layout.rawValue).tag(layout)
                    }
                }
            }
            
            Section(header: Text("Mal")) {
                Button(action: { showingTemplateOptions = true }) {
                    HStack {
                        Text(selectedTemplate?.name ?? "Velg mal")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                
                if selectedTemplate != nil {
                    Button("Fjern mal") {
                        selectedTemplate = nil
                    }
                    .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Øvelser")) {
                ForEach(exercises) { exercise in
                    ExerciseView(
                        exercise: .constant(exercise),
                        selectedCategory: selectedCategory,
                        selectedLayout: selectedLayout
                    )
                }
                
                Button(action: { showingAddExercise = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Legg til øvelse")
                    }
                }
            }
            
            Section(header: Text("Noter")) {
                TextEditor(text: $notes)
                    .frame(height: 100)
            }
            
            Section(header: Text("Ekstra")) {
                TextField("Kalorier", text: $calories)
                    .keyboardType(.numberPad)
                TextField("Kroppsvekt", text: $bodyWeight)
                    .keyboardType(.decimalPad)
            }
        }
        .navigationTitle("Ny treningsøkt")
        .navigationBarItems(
            trailing: Button("Lagre") {
                saveWorkout()
            }
        )
        .sheet(isPresented: $showingTemplateOptions) {
            NavigationView {
                List {
                    Section {
                        Button("Administrer maler") {
                            showingTemplateOptions = false
                            showingTemplateManager = true
                        }
                    }
                    
                    Section(header: Text("Velg mal")) {
                        ForEach(templates.filter { $0.type == selectedCategory.rawValue }) { template in
                            Button(action: {
                                loadTemplate(template)
                                showingTemplateOptions = false
                            }) {
                                Text(template.name)
                            }
                        }
                    }
                }
                .navigationTitle("Maler")
                .navigationBarItems(
                    trailing: Button("Lukk") {
                        showingTemplateOptions = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingTemplateManager) {
            NavigationView {
                TemplateManagerView()
            }
        }
        .alert("Lagre som mal", isPresented: $showingSaveTemplateAlert) {
            TextField("Navn på mal", text: $newTemplateName)
            Button("Avbryt", role: .cancel) {
                dismiss()
            }
            Button("Lagre") {
                Task {
                    do {
                        let template = WorkoutTemplate(
                            id: UUID().uuidString,
                            name: newTemplateName,
                            type: selectedCategory.rawValue,
                            layout: selectedCategory == .other ? selectedLayout : nil
                        )
                        try await cloudKitManager.saveTemplate(template)
                        dismiss()
                    } catch {
                        print("Error saving template: \(error)")
                    }
                }
            }
        }
        .alert("Legg til øvelse", isPresented: $showingAddExercise) {
            TextField("Navn på øvelse", text: $newExerciseName)
            Button("Avbryt", role: .cancel) { }
            Button("Legg til") {
                addNewExercise()
            }
        }
        .task {
            await loadTemplates()
        }
    }
}

#Preview {
    NavigationView {
        WorkoutLogView(selectedDate: .constant(Date()), selectedCategory: .strength)
            .environmentObject(CloudKitManager.shared)
    }
} 