//
//  ContentView.swift
//  Trenings logg
//
//  Created by Didrik Svendsen on 28/01/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var selectedDate = Date()
    @State private var workoutSessions: [WorkoutSession] = [] {
        didSet {
            // Lagrer data hver gang workoutSessions endres
            saveWorkoutSessions()
        }
    }
    
    // Initializer for å laste lagrede data når appen starter
    init() {
        _workoutSessions = State(initialValue: loadWorkoutSessions())
    }
    
    // Funksjon for å laste data
    private func loadWorkoutSessions() -> [WorkoutSession] {
        if let data = UserDefaults.standard.data(forKey: "WorkoutSessions") {
            do {
                let decoded = try JSONDecoder().decode([WorkoutSession].self, from: data)
                print("Lastet \(decoded.count) treningsøkter")  // Debug logging
                return decoded
            } catch {
                print("Feil ved lasting av treningsøkter: \(error)")  // Debug logging
                // Forsøk å migrere gamle data hvis nødvendig
                // eller lagre en backup av dataene
                if let rawData = String(data: data, encoding: .utf8) {
                    print("Rå data: \(rawData)")  // Debug logging
                    UserDefaults.standard.set(data, forKey: "WorkoutSessions_backup")
                }
            }
        }
        return []
    }
    
    // Funksjon for å lagre data
    private func saveWorkoutSessions() {
        do {
            let encoded = try JSONEncoder().encode(workoutSessions)
            UserDefaults.standard.set(encoded, forKey: "WorkoutSessions")
            print("Lagret \(workoutSessions.count) treningsøkter")  // Debug logging
        } catch {
            print("Feil ved lagring av treningsøkter: \(error)")  // Debug logging
        }
    }
    
    var workoutDates: Set<Date> {
        Set(workoutSessions.map { $0.date })
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutSelectionView(
                workoutSessions: $workoutSessions,
                selectedDate: $selectedDate
            )
            .tabItem {
                Label("Ny økt", systemImage: "plus.circle.fill")
            }
            .tag(0)
            
            WorkoutHistoryView(
                workoutSessions: $workoutSessions,
                selectedDate: $selectedDate
            )
            .tabItem {
                Label("Historie", systemImage: "calendar")
            }
            .tag(1)
        }
        .preferredColorScheme(.dark)  // Setter mørk modus som standard
    }
}

extension Array where Element == WorkoutSession {
    func lastWorkoutData(for exerciseName: String, setIndex: Int) -> (reps: String, weight: String, duration: String?, distance: String?)? {
        // Sorter økter etter dato, nyeste først
        let sortedSessions = self.sorted { $0.date > $1.date }
        
        // Finn siste økt som inneholder øvelsen
        for session in sortedSessions {
            if let exercise = session.exercises.first(where: { $0.name.lowercased() == exerciseName.lowercased() }),
               exercise.sets.count > setIndex {
                let set = exercise.sets[setIndex]
                return (
                    reps: set.reps,
                    weight: set.weight,
                    duration: set.duration,
                    distance: set.distance
                )
            }
        }
        return nil
    }
}

struct WorkoutLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var workoutSessions: [WorkoutSession]
    @Binding var selectedDate: Date
    @StateObject private var templateManager = WorkoutTemplateManager()
    @State private var workoutType: String
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var exercises: [Exercise] = [Exercise(name: "", sets: [SetData()])]
    @State private var notes = ""
    @State private var showingTemplates = false
    @State private var showingSaveTemplateAlert = false
    @State private var newTemplateName = ""
    @State private var calories = ""
    @State private var showingAddExercise = false
    @State private var newExerciseName = ""
    @State private var bodyWeight = ""
    let preSelectedTemplate: WorkoutTemplate?
    let selectedCategory: WorkoutCategory
    @State private var showingTemplateManager = false
    @State private var editingTemplate: WorkoutTemplate?
    @State private var editedTemplateName = ""
    @State private var showingDeleteAlert = false
    @State private var templateToDelete: WorkoutTemplate?
    @State private var selectedLayout: WorkoutLayout = .basic
    
    enum WorkoutLayout: String, CaseIterable {
        case strength = "Styrke (Vekt/Reps)"
        case endurance = "Utholdenhet (Tid/Distanse)"
        case basic = "Enkel (Kun tid)"
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    init(workoutSessions: Binding<[WorkoutSession]>, selectedDate: Binding<Date>, preSelectedTemplate: WorkoutTemplate? = nil, selectedCategory: WorkoutCategory) {
        self._workoutSessions = workoutSessions
        self._selectedDate = selectedDate
        self.preSelectedTemplate = preSelectedTemplate
        self.selectedCategory = selectedCategory
        self._workoutType = State(initialValue: selectedCategory.rawValue)
    }
    
    // Legg til denne funksjonen for å oppdatere tid
    private func updateTimeToNow() {
        let now = Date()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: now)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        if let date = calendar.date(from: components) {
            selectedDate = date
        }
    }
    
    private func hasTemplateChanges() -> Bool {
        guard let template = selectedTemplate else { 
            // Hvis ingen mal er valgt og det er en ny økt, returner true
            return selectedCategory == .other && exercises.count > 0
        }
        
        // Sjekk om antall øvelser er endret
        if template.exercises.count != exercises.count { return true }
        
        // Sjekk om øvelsene er endret
        for (index, exercise) in exercises.enumerated() {
            let templateExercise = template.exercises[index]
            if exercise.name != templateExercise.name { return true }
        }
        
        return false
    }
    
    private func saveWorkout() {
        // Oppdater workoutType basert på selectedLayout hvis det er "Annen trening"
        let finalWorkoutType = selectedCategory == .other ? 
            "\(selectedCategory.rawValue) (\(selectedLayout.rawValue))" : 
            selectedCategory.rawValue
        
        let workout = WorkoutSession(
            date: selectedDate,
            type: finalWorkoutType,
            exercises: exercises,
            notes: notes,
            calories: calories,
            bodyWeight: bodyWeight
        )
        workoutSessions.append(workout)
        
        // Vis mal-dialog hvis det er endringer eller ny økt i "Annen trening"
        if hasTemplateChanges() || (selectedCategory == .other && exercises.count > 0) {
            showingSaveTemplateAlert = true
        } else {
            dismiss()
        }
    }
    
    private func saveAsTemplate() {
        let newTemplate = WorkoutTemplate(
            name: newTemplateName,
            type: workoutType,
            exercises: exercises.map { exercise in
                ExerciseTemplate(
                    name: exercise.name,
                    defaultSets: exercise.sets.count
                )
            }
        )
        templateManager.templates.append(newTemplate)
        templateManager.saveTemplates()
        // Gå tilbake til startsiden
        dismiss()
    }
    
    private func resetForm() {
        exercises = [Exercise(name: "", sets: [SetData()])]
        notes = ""
        calories = ""
        bodyWeight = ""
        selectedTemplate = nil
        newTemplateName = ""
    }
    
    private func lastWorkoutPlaceholder(for exerciseName: String, setIndex: Int, field: String) -> String {
        if let lastData = workoutSessions.lastWorkoutData(for: exerciseName, setIndex: setIndex) {
            switch field {
            case "reps":
                return workoutType == "Utholdenhetstrening" ? lastData.reps + " km/t" : lastData.reps
            case "weight":
                return workoutType == "Utholdenhetstrening" ? lastData.weight + " %" : lastData.weight
            case "duration":
                return lastData.duration ?? ""
            case "distance":
                return lastData.distance ?? ""
            default:
                return ""
            }
        }
        return workoutType == "Utholdenhetstrening" ? 
            (field == "reps" ? "km/t" : field == "weight" ? "%" : field == "duration" ? "min" : "km") :
            (field == "reps" ? "Reps" : "Kg")
    }
    
    private func isSimpleWorkout(_ type: String) -> Bool {
        return type == "Klatring" || type == "Yoga"
    }
    
    var filteredTemplates: [WorkoutTemplate] {
        // Filtrer først etter kategori, deretter sorter alfabetisk på navn
        templateManager.templates
            .filter { $0.type == selectedCategory.rawValue }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    // Hjelpefunksjon for å håndtere optional string bindings
    private func optionalBinding(_ value: Binding<String?>) -> Binding<String> {
        Binding(
            get: { value.wrappedValue ?? "" },
            set: { str in
                value.wrappedValue = str.isEmpty ? nil : str
            }
        )
    }
    
    private func buildSetRow(for exerciseIndex: Int, setIndex: Int) -> some View {
        let exerciseName = exercises[exerciseIndex].name
        
        return VStack(alignment: .leading, spacing: 8) {
            // Sett-rad
            HStack(spacing: 8) {
                // Sett nummer
                Text("\(setIndex + 1)")
                    .frame(width: 30)
                    .foregroundColor(.gray)
                
                if workoutType == "Utholdenhetstrening" {
                    Group {
                        // Stigning
                        TextField(
                            lastWorkoutPlaceholder(for: exerciseName, setIndex: setIndex, field: "weight"),
                            text: $exercises[exerciseIndex].sets[setIndex].weight
                        )
                        .frame(width: 60)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        
                        // Fart
                        TextField(
                            lastWorkoutPlaceholder(for: exerciseName, setIndex: setIndex, field: "reps"),
                            text: $exercises[exerciseIndex].sets[setIndex].reps
                        )
                        .frame(width: 60)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        
                        // Tid
                        TextField("min", text: optionalBinding($exercises[exerciseIndex].sets[setIndex].duration))
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        // Distanse
                        TextField("km", text: optionalBinding($exercises[exerciseIndex].sets[setIndex].distance))
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    
                    Spacer()
                    
                    // Minus-knapp eller placeholder
                    if exercises[exerciseIndex].sets.count > 1 {
                        Button(action: {
                            exercises[exerciseIndex].sets.remove(at: setIndex)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    } else {
                        Color.clear.frame(width: 22)
                    }
                }
            }
            
            // Pause-felt
            if workoutType == "Utholdenhetstrening" && setIndex < exercises[exerciseIndex].sets.count - 1 {
                HStack {
                    Text("Pause:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    TextField("min", text: optionalBinding($exercises[exerciseIndex].sets[setIndex].restPeriod))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                    Text("min")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.leading, 38)
            }
        }
    }
    
    private func buildStrengthSetRow(for exerciseIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Sett")
                    .fontWeight(.medium)
                Spacer()
                Button(action: {
                    exercises[exerciseIndex].sets.append(SetData())
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            // Kolonneoverskrifter
            HStack(spacing: 8) {
                Text("Sett")
                    .frame(width: 30)
                Text("Vekt")
                    .frame(width: 60)
                Text("Reps")
                    .frame(width: 60)
            }
            .fontWeight(.medium)
            .font(.subheadline)
            
            // Sett-rader
            ForEach(exercises[exerciseIndex].sets.indices, id: \.self) { setIndex in
                HStack(spacing: 8) {
                    Text("\(setIndex + 1)")
                        .frame(width: 30)
                    
                    TextField(
                        lastWorkoutPlaceholder(for: exercises[exerciseIndex].name, setIndex: setIndex, field: "weight"),
                        text: $exercises[exerciseIndex].sets[setIndex].weight
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    
                    TextField(
                        lastWorkoutPlaceholder(for: exercises[exerciseIndex].name, setIndex: setIndex, field: "reps"),
                        text: $exercises[exerciseIndex].sets[setIndex].reps
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    
                    if exercises[exerciseIndex].sets.count > 1 {
                        Button(action: {
                            exercises[exerciseIndex].sets.remove(at: setIndex)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
    
    private func buildEnduranceSetRow(for exerciseIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Sett")
                    .fontWeight(.medium)
                Spacer()
                Button(action: {
                    exercises[exerciseIndex].sets.append(SetData(duration: "", distance: ""))
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            // Kolonneoverskrifter
            HStack(spacing: 8) {
                Text("Sett")
                    .frame(width: 30)
                Text("Stigning")
                    .frame(width: 60)
                Text("Fart")
                    .frame(width: 60)
                Text("Tid")
                    .frame(width: 60)
                Text("Dist")
                    .frame(width: 60)
            }
            .fontWeight(.medium)
            .font(.subheadline)
            
            // Sett-rader
            ForEach(exercises[exerciseIndex].sets.indices, id: \.self) { setIndex in
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("\(setIndex + 1)")
                            .frame(width: 30)
                        
                        TextField(
                            lastWorkoutPlaceholder(for: exercises[exerciseIndex].name, setIndex: setIndex, field: "weight"),
                            text: $exercises[exerciseIndex].sets[setIndex].weight
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                        
                        TextField(
                            lastWorkoutPlaceholder(for: exercises[exerciseIndex].name, setIndex: setIndex, field: "reps"),
                            text: $exercises[exerciseIndex].sets[setIndex].reps
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                        
                        TextField("min", text: optionalBinding($exercises[exerciseIndex].sets[setIndex].duration))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        
                        TextField("km", text: optionalBinding($exercises[exerciseIndex].sets[setIndex].distance))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                        
                        if exercises[exerciseIndex].sets.count > 1 {
                            Button(action: {
                                exercises[exerciseIndex].sets.remove(at: setIndex)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if setIndex < exercises[exerciseIndex].sets.count - 1 {
                        HStack {
                            Text("Pause:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextField("min", text: optionalBinding($exercises[exerciseIndex].sets[setIndex].restPeriod))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                            Text("min")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.leading, 38)
                    }
                }
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Treningslogg")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text(dateFormatter.string(from: selectedDate))
                    .foregroundColor(.gray)
                
                // Velg treningsmal
                HStack {
                    Text("Velg økt:")
                        .fontWeight(.medium)
                    Spacer()
                    Button(action: { showingTemplates = true }) {
                        HStack {
                            Text(selectedTemplate?.name ?? "Velg mal")
                            Image(systemName: "chevron.down")
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                
                // Type økt (nå låst til valgt kategori)
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
                
                ForEach(exercises.indices, id: \.self) { exerciseIndex in
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Øvelse \(exerciseIndex + 1):")
                                .fontWeight(.medium)
                            Spacer()
                            
                            // Legg til stjerneknapp
                            Button(action: {
                                exercises[exerciseIndex].increaseNextTime.toggle()
                            }) {
                                Image(systemName: exercises[exerciseIndex].increaseNextTime ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                            
                            if exerciseIndex > 0 {
                                Button(action: { exercises.remove(at: exerciseIndex) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        TextField("F.eks. Benkpress", text: $exercises[exerciseIndex].name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if isSimpleWorkout(workoutType) {
                            // Forenklet visning for klatring og yoga
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Varighet:")
                                        .fontWeight(.medium)
                                    TextField("Minutter", text: Binding(
                                        get: { exercises[exerciseIndex].sets[0].duration ?? "" },
                                        set: { exercises[exerciseIndex].sets[0].duration = $0 }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: 100)
                                }
                            }
                        } else {
                            // Velg layout basert på kategori eller valgt layout
                            if selectedCategory == .strength {
                                buildStrengthSetRow(for: exerciseIndex)
                            } else if selectedCategory == .endurance {
                                buildEnduranceSetRow(for: exerciseIndex)
                            } else {
                                // For "Annen trening", bruk valgt layout
                                switch selectedLayout {
                                case .strength:
                                    buildStrengthSetRow(for: exerciseIndex)
                                case .endurance:
                                    buildEnduranceSetRow(for: exerciseIndex)
                                case .basic:
                                    buildBasicSetRow(for: exerciseIndex)
                                }
                            }
                        }
                    }
                    Divider()
                }
                
                Button(action: {
                    showingAddExercise = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Legg til øvelse")
                    }
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 5)
                
                // Kalorier og vekt i samme rad
                HStack(spacing: 20) {
                    // Kalorier
                    VStack(alignment: .leading) {
                        Text("Kalorier forbrent:")
                            .fontWeight(.medium)
                        TextField("F.eks. 300", text: $calories)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Kroppsvekt
                    VStack(alignment: .leading) {
                        Text("Min vekt:")
                            .fontWeight(.medium)
                        TextField("Kg", text: $bodyWeight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                VStack(alignment: .leading) {
                    Text("Notater:")
                        .fontWeight(.medium)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                Button(action: saveWorkout) {
                    Text("Lagre økt")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Legg til en knapp for å administrere maler
                Button(action: {
                    showingTemplateManager = true
                }) {
                    Label("Administrer maler", systemImage: "list.bullet")
                }
                .sheet(isPresented: $showingTemplateManager) {
                    TemplateManagerView(
                        templates: filteredTemplates,
                        templateManager: templateManager,
                        category: selectedCategory
                    )
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingTemplates) {
            NavigationView {
                List(filteredTemplates) { template in
                    Button(action: {
                        loadTemplate(template)
                        showingTemplates = false
                    }) {
                        Text(template.name)
                    }
                }
                .navigationTitle("Velg \(selectedCategory.rawValue.lowercased())økt")
                .navigationBarItems(trailing: Button("Avbryt") {
                    showingTemplates = false
                })
            }
        }
        .alert("Legg til øvelse", isPresented: $showingAddExercise) {
            TextField("Øvelsesnavn", text: $newExerciseName)
            Button("Avbryt", role: .cancel) {
                newExerciseName = ""
            }
            Button("Legg til") {
                if !newExerciseName.isEmpty {
                    exercises.append(Exercise(
                        name: newExerciseName,
                        sets: [SetData()]
                    ))
                    newExerciseName = ""
                }
            }
        } message: {
            Text("Skriv inn navn på øvelsen")
        }
        .alert("Lagre som ny mal?", isPresented: $showingSaveTemplateAlert) {
            TextField("Navn på mal", text: $newTemplateName)
            Button("Avbryt", role: .cancel) {
                // Gå tilbake til startsiden uten å lagre mal
                dismiss()
            }
            Button("Lagre som mal") {
                saveTemplate()
            }
            Button("Bare lagre økten") {
                // Gå tilbake til startsiden
                dismiss()
            }
        } message: {
            Text("Vil du lagre dette oppsettet som en ny treningsmal?")
        }
        .onAppear {
            updateTimeToNow()  // Oppdater tid når viewet vises
            if let template = preSelectedTemplate {
                loadTemplate(template)
            }
        }
    }
    
    private func loadTemplate(_ template: WorkoutTemplate) {
        workoutType = template.type
        if isSimpleWorkout(template.type) {
            exercises = [Exercise(
                name: template.exercises[0].name,
                sets: [SetData(duration: "")]
            )]
        } else {
            exercises = template.exercises.map { exerciseTemplate in
                // Finn siste økt med denne øvelsen
                let lastExercise = workoutSessions
                    .sorted { $0.date > $1.date }
                    .flatMap { $0.exercises }
                    .first { $0.name.lowercased() == exerciseTemplate.name.lowercased() }
                
                // Bruk antall sett fra siste økt, eller standard antall hvis ingen tidligere økt
                let numberOfSets = lastExercise?.sets.count ?? exerciseTemplate.defaultSets
                
                return Exercise(
                    name: exerciseTemplate.name,
                    sets: Array(repeating: SetData(), count: numberOfSets),
                    increaseNextTime: lastExercise?.increaseNextTime ?? false
                )
            }
        }
        selectedTemplate = template
    }
    
    private func getSetHeaders(for type: String) -> (String, String) {
        switch type {
        case "Utholdenhetstrening":
            return ("Fart", "Stigning")
        default:
            return ("Reps", "Vekt")
        }
    }
    
    private func getSetPlaceholders(for type: String) -> (String, String) {
        switch type {
        case "Utholdenhetstrening":
            return ("km/t", "%")
        default:
            return ("Reps", "Kg")
        }
    }
    
    private func saveTemplate() {
        let newTemplate = WorkoutTemplate(
            name: newTemplateName,
            type: selectedCategory.rawValue,
            exercises: exercises.map { exercise in
                ExerciseTemplate(
                    name: exercise.name,
                    defaultSets: exercise.sets.count
                )
            }
        )
        
        // Finn riktig posisjon for den nye malen basert på navn
        var updatedTemplates = templateManager.templates
        let insertionIndex = updatedTemplates.firstIndex { 
            $0.name.localizedCaseInsensitiveCompare(newTemplate.name) == .orderedDescending 
        } ?? updatedTemplates.endIndex
        
        // Sett inn den nye malen på riktig sted
        updatedTemplates.insert(newTemplate, at: insertionIndex)
        templateManager.templates = updatedTemplates
        
        showingSaveTemplateAlert = false
        newTemplateName = ""
        dismiss()
    }
    
    // Ny funksjon for enkel tidregistrering
    private func buildBasicSetRow(for exerciseIndex: Int) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("Tid:")
                    .frame(width: 30)
                TextField("min", text: optionalBinding($exercises[exerciseIndex].sets[0].duration))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                Text("minutter")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
    
    // ... resten av koden ...
}

// Ny view for å administrere maler
struct TemplateManagerView: View {
    let templates: [WorkoutTemplate]
    @ObservedObject var templateManager: WorkoutTemplateManager
    let category: WorkoutCategory
    @Environment(\.dismiss) private var dismiss
    @State private var editingTemplate: WorkoutTemplate?
    @State private var editedTemplateName = ""
    @State private var showingDeleteAlert = false
    @State private var templateToDelete: WorkoutTemplate?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(templates) { template in
                    HStack {
                        Text(template.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Rediger-knapp
                        Button(action: {
                            editingTemplate = template
                            editedTemplateName = template.name
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        // Slett-knapp
                        Button(action: {
                            templateToDelete = template
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .contentShape(Rectangle())  // Fjern denne for å deaktivere trykk på hele raden
                }
            }
            .navigationTitle("Administrer maler")
            .navigationBarItems(
                leading: Button("Lukk") { dismiss() }
            )
            .alert("Rediger malnavn", isPresented: Binding(
                get: { editingTemplate != nil },
                set: { if !$0 { editingTemplate = nil } }
            )) {
                TextField("Navn", text: $editedTemplateName)
                Button("Avbryt") { editingTemplate = nil }
                Button("Lagre") {
                    if let template = editingTemplate {
                        updateTemplateName(template, newName: editedTemplateName)
                    }
                    editingTemplate = nil
                }
            }
            .alert("Slett mal", isPresented: $showingDeleteAlert) {
                Button("Avbryt", role: .cancel) {
                    templateToDelete = nil
                }
                Button("Slett", role: .destructive) {
                    if let template = templateToDelete {
                        deleteTemplate(template)
                    }
                }
            } message: {
                Text("Er du sikker på at du vil slette denne malen?")
            }
        }
    }
    
    private func updateTemplateName(_ template: WorkoutTemplate, newName: String) {
        var updatedTemplates = templateManager.templates
        if let index = updatedTemplates.firstIndex(where: { $0.id == template.id }) {
            var updatedTemplate = template
            updatedTemplate.name = newName.trimmingCharacters(in: .whitespaces)
            updatedTemplates.remove(at: index)
            
            // Finn ny posisjon basert på det nye navnet
            let insertionIndex = updatedTemplates.firstIndex {
                $0.name.localizedCaseInsensitiveCompare(newName) == .orderedDescending
            } ?? updatedTemplates.endIndex
            
            updatedTemplates.insert(updatedTemplate, at: insertionIndex)
            templateManager.templates = updatedTemplates
        }
    }
    
    private func deleteTemplate(_ template: WorkoutTemplate) {
        templateManager.templates.removeAll { $0.id == template.id }
        templateToDelete = nil
    }
}

struct WorkoutHistoryView: View {
    @Binding var workoutSessions: [WorkoutSession]
    @Binding var selectedDate: Date
    @State private var editingSession: WorkoutSession?
    @State private var showingExportSheet = false
    @State private var showingAddWorkout = false
    
    var filteredSessions: [WorkoutSession] {
        workoutSessions.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        VStack {
            CalendarView(
                selectedDate: $selectedDate,
                workoutDates: Set(workoutSessions.map { $0.date })
            )
            
            // Legg til header med + knapp
            HStack {
                if filteredSessions.isEmpty {
                    Text("Ingen økter denne dagen")
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: { showingAddWorkout = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            List {
                ForEach(filteredSessions) { session in
                    WorkoutSessionView(session: session)
                        .contextMenu {
                            Button(action: { editingSession = session }) {
                                Label("Rediger", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: { deleteSession(session) }) {
                                Label("Slett", systemImage: "trash")
                            }
                        }
                }
            }
            
            Button(action: { showingExportSheet = true }) {
                Label("Statistikk", systemImage: "chart.bar.fill")
            }
            .padding()
        }
        .sheet(item: $editingSession) { session in
            NavigationView {
                WorkoutEditView(
                    session: session,
                    workoutSessions: $workoutSessions
                )
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(workoutSessions: workoutSessions)
        }
        .sheet(isPresented: $showingAddWorkout) {
            NavigationView {
                WorkoutLogView(
                    workoutSessions: $workoutSessions,
                    selectedDate: $selectedDate,
                    selectedCategory: .strength
                )
            }
        }
    }
    
    private func deleteSession(_ session: WorkoutSession) {
        if let index = workoutSessions.firstIndex(where: { $0.id == session.id }) {
            workoutSessions.remove(at: index)
        }
    }
}

struct WorkoutSessionView: View {
    let session: WorkoutSession
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Vis type økt og tidspunkt
            HStack {
                Text(session.type)
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Text(dateFormatter.string(from: session.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            ForEach(session.exercises) { exercise in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(exercise.name)
                            .font(.headline)
                        if exercise.increaseNextTime {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    ForEach(exercise.sets.indices, id: \.self) { index in
                        let set = exercise.sets[index]
                        HStack {
                            Text("Sett \(index + 1):")
                                .foregroundColor(.gray)
                            Text("\(set.reps) reps")
                            Spacer()
                                .frame(maxWidth: 20) // Redusert spacing mellom reps og vekt
                            Text("\(set.weight) kg")
                        }
                        .foregroundColor(.gray)
                    }
                }
                Divider()
            }
            
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if !session.calories.isEmpty {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(session.calories) kcal")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct WorkoutEditView: View {
    let session: WorkoutSession
    @Binding var workoutSessions: [WorkoutSession]
    @Environment(\.dismiss) private var dismiss
    @State private var exercises: [Exercise]
    @State private var notes: String
    
    init(session: WorkoutSession, workoutSessions: Binding<[WorkoutSession]>) {
        self.session = session
        self._workoutSessions = workoutSessions
        self._exercises = State(initialValue: session.exercises)
        self._notes = State(initialValue: session.notes)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Gjenbruk mesteparten av WorkoutLogView sin layout her
                // men med forhåndsutfylte verdier
                
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
        if let index = workoutSessions.firstIndex(where: { $0.id == session.id }) {
            var updatedSession = session
            updatedSession.exercises = exercises
            updatedSession.notes = notes
            workoutSessions[index] = updatedSession
        }
        dismiss()
    }
}

struct ExportView: View {
    let workoutSessions: [WorkoutSession]
    @Environment(\.dismiss) private var dismiss
    
    private func generateStatistics() -> String {
        let calendar = Calendar.current
        let now = Date()
        var export = "TRENINGSSTATISTIKK\n\n"
        
        // Totalt antall økter
        export += "Totalt antall økter: \(workoutSessions.count)\n\n"
        
        // Månedsoversikt
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        let thisMonthSessions = workoutSessions.filter {
            let month = calendar.component(.month, from: $0.date)
            let year = calendar.component(.year, from: $0.date)
            return month == currentMonth && year == currentYear
        }
        
        export += "DENNE MÅNEDEN (\(monthName(currentMonth)))\n"
        export += "Antall økter: \(thisMonthSessions.count)\n"
        export += typeStatistics(for: thisMonthSessions)
        export += "\n"
        
        // Årsoversikt
        let thisYearSessions = workoutSessions.filter {
            calendar.component(.year, from: $0.date) == currentYear
        }
        
        export += "DETTE ÅRET (\(currentYear))\n"
        export += "Antall økter: \(thisYearSessions.count)\n"
        export += typeStatistics(for: thisYearSessions)
        export += "\n"
        
        // Månedlig fordeling dette året
        export += "MÅNEDLIG FORDELING \(currentYear):\n"
        for month in 1...12 {
            let monthSessions = thisYearSessions.filter {
                calendar.component(.month, from: $0.date) == month
            }
            if monthSessions.count > 0 {
                export += "\(monthName(month)): \(monthSessions.count) økter\n"
            }
        }
        export += "\n"
        
        // Vektstatistikk til slutt
        let weightSessions = workoutSessions
            .filter { !$0.bodyWeight.isEmpty }
            .sorted { $0.date > $1.date }
        
        if let lastWeight = weightSessions.first {
            export += "VEKTSTATISTIKK\n"
            export += "Sist målte vekt: \(lastWeight.bodyWeight) kg"
            export += " (\(formatDate(lastWeight.date)))\n"
            
            if let lowestWeight = weightSessions.min(by: { 
                (Double($0.bodyWeight) ?? 0) < (Double($1.bodyWeight) ?? 0) 
            }) {
                export += "Laveste vekt: \(lowestWeight.bodyWeight) kg"
                export += " (\(formatDate(lowestWeight.date)))\n"
            }
            
            if let highestWeight = weightSessions.max(by: { 
                (Double($0.bodyWeight) ?? 0) < (Double($1.bodyWeight) ?? 0) 
            }) {
                export += "Høyeste vekt: \(highestWeight.bodyWeight) kg"
                export += " (\(formatDate(highestWeight.date)))\n"
            }
        }
        
        return export
    }
    
    private func typeStatistics(for sessions: [WorkoutSession]) -> String {
        var typeCount: [String: Int] = [:]
        for session in sessions {
            typeCount[session.type, default: 0] += 1
        }
        
        var result = "Fordeling:\n"
        for (type, count) in typeCount.sorted(by: { $0.key < $1.key }) {
            result += "- \(type): \(count) økter\n"
        }
        return result
    }
    
    private func monthName(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "nb_NO")
        return dateFormatter.monthSymbols[month - 1]
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(generateStatistics())
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Treningsstatistikk")
            .navigationBarItems(
                leading: Button("Lukk") { dismiss() },
                trailing: ShareLink(
                    item: generateStatistics(),
                    subject: Text("Treningsstatistikk"),
                    message: Text("Her er min treningsstatistikk")
                )
            )
        }
    }
}

#Preview {
    ContentView()
}
