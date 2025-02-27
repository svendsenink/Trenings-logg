import SwiftUI

struct WorkoutTypeItem: Identifiable, Codable {
    let id = UUID()
    var name: String
    var icon: String
    var isVisible: Bool
    var category: WorkoutCategory
    var order: Int  // For å bevare rekkefølgen
}

struct WorkoutIcon: Identifiable {
    let id = UUID()
    let name: String
    let category: WorkoutCategory
}

struct ManageWorkoutTypesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: WorkoutCategory = .strength
    @State private var workoutTypesData: Data {
        didSet {
            UserDefaults.standard.set(workoutTypesData, forKey: "workoutTypes")
        }
    }
    @State private var workoutTypes: [WorkoutTypeItem] = []
    @State private var showingAddNew = false
    
    init() {
        let data = UserDefaults.standard.data(forKey: "workoutTypes") ?? Data()
        _workoutTypesData = State(initialValue: data)
    }
    
    // Standard treningstyper
    private let defaultWorkoutTypes: [WorkoutTypeItem] = [
        // Styrketrening
        WorkoutTypeItem(name: "Traditional Strength", icon: "figure.strengthtraining.traditional", isVisible: true, category: .strength, order: 0),
        WorkoutTypeItem(name: "Functional Training", icon: "figure.strengthtraining.functional", isVisible: false, category: .strength, order: 1),
        WorkoutTypeItem(name: "Weight Training", icon: "dumbbell.fill", isVisible: false, category: .strength, order: 2),
        WorkoutTypeItem(name: "Core Training", icon: "figure.core.training", isVisible: false, category: .strength, order: 3),
        WorkoutTypeItem(name: "Stairs", icon: "figure.stairs", isVisible: false, category: .strength, order: 4),
        WorkoutTypeItem(name: "Flexibility", icon: "figure.flexibility", isVisible: false, category: .strength, order: 5),
        WorkoutTypeItem(name: "Cooldown", icon: "figure.cooldown", isVisible: false, category: .strength, order: 6),
        WorkoutTypeItem(name: "Upper Body", icon: "figure.arms.open", isVisible: false, category: .strength, order: 7),
        WorkoutTypeItem(name: "Lower Body", icon: "figure.walk", isVisible: false, category: .strength, order: 8),
        WorkoutTypeItem(name: "CrossFit", icon: "figure.cross.training", isVisible: false, category: .strength, order: 9),
        WorkoutTypeItem(name: "Bodyweight", icon: "figure.stand", isVisible: false, category: .strength, order: 10),
        
        // Utholdenhet
        WorkoutTypeItem(name: "Running", icon: "figure.run", isVisible: true, category: .endurance, order: 0),
        WorkoutTypeItem(name: "Walking", icon: "figure.walk", isVisible: false, category: .endurance, order: 1),
        WorkoutTypeItem(name: "Cycling", icon: "bicycle", isVisible: false, category: .endurance, order: 2),
        WorkoutTypeItem(name: "Swimming", icon: "figure.pool.swim", isVisible: false, category: .endurance, order: 3),
        WorkoutTypeItem(name: "Hiking", icon: "figure.hiking", isVisible: false, category: .endurance, order: 4),
        WorkoutTypeItem(name: "Rowing", icon: "figure.rower", isVisible: false, category: .endurance, order: 5),
        WorkoutTypeItem(name: "Skiing", icon: "figure.skiing.downhill", isVisible: false, category: .endurance, order: 6),
        WorkoutTypeItem(name: "Skating", icon: "figure.skating", isVisible: false, category: .endurance, order: 7),
        WorkoutTypeItem(name: "Dance", icon: "figure.dance", isVisible: false, category: .endurance, order: 8),
        WorkoutTypeItem(name: "Stair Climbing", icon: "figure.stair.stepper", isVisible: false, category: .endurance, order: 9),
        WorkoutTypeItem(name: "Elliptical", icon: "figure.elliptical", isVisible: false, category: .endurance, order: 10),
        WorkoutTypeItem(name: "Trail Running", icon: "mountain.2", isVisible: false, category: .endurance, order: 11),
        
        // Andre
        WorkoutTypeItem(name: "Yoga", icon: "figure.yoga", isVisible: false, category: .other, order: 0),
        WorkoutTypeItem(name: "Pilates", icon: "figure.pilates", isVisible: false, category: .other, order: 1),
        WorkoutTypeItem(name: "Boxing", icon: "figure.boxing", isVisible: false, category: .other, order: 2),
        WorkoutTypeItem(name: "Mixed Cardio", icon: "figure.mixed.cardio", isVisible: false, category: .other, order: 3),
        WorkoutTypeItem(name: "Mind and Body", icon: "figure.mind.and.body", isVisible: false, category: .other, order: 4),
        WorkoutTypeItem(name: "Barre", icon: "figure.barre", isVisible: false, category: .other, order: 5),
        WorkoutTypeItem(name: "Climbing", icon: "figure.climbing", isVisible: false, category: .other, order: 6),
        WorkoutTypeItem(name: "Play", icon: "figure.play", isVisible: false, category: .other, order: 7),
        WorkoutTypeItem(name: "Tai Chi", icon: "figure.taichi", isVisible: false, category: .other, order: 8),
        WorkoutTypeItem(name: "Martial Arts", icon: "figure.martial.arts", isVisible: false, category: .other, order: 9),
        WorkoutTypeItem(name: "Stretching", icon: "figure.flexibility", isVisible: false, category: .other, order: 10),
        WorkoutTypeItem(name: "Meditation", icon: "figure.mind.and.body", isVisible: false, category: .other, order: 11)
    ]
    
    static let availableIcons: [WorkoutIcon] = [
        // Styrke
        WorkoutIcon(name: "figure.strengthtraining.traditional", category: .strength),
        WorkoutIcon(name: "figure.strengthtraining.functional", category: .strength),
        WorkoutIcon(name: "figure.core.training", category: .strength),
        WorkoutIcon(name: "figure.arms.open", category: .strength),
        WorkoutIcon(name: "figure.cross.training", category: .strength),
        WorkoutIcon(name: "dumbbell.fill", category: .strength),
        WorkoutIcon(name: "figure.cooldown", category: .strength),
        WorkoutIcon(name: "figure.stand", category: .strength),
        WorkoutIcon(name: "figure.step.training", category: .strength),
        
        // Utholdenhet
        WorkoutIcon(name: "figure.run", category: .endurance),
        WorkoutIcon(name: "figure.walk", category: .endurance),
        WorkoutIcon(name: "figure.hiking", category: .endurance),
        WorkoutIcon(name: "figure.pool.swim", category: .endurance),
        WorkoutIcon(name: "figure.stair.stepper", category: .endurance),
        WorkoutIcon(name: "figure.dance", category: .endurance),
        WorkoutIcon(name: "figure.mixed.cardio", category: .endurance),
        WorkoutIcon(name: "figure.elliptical", category: .endurance),
        WorkoutIcon(name: "figure.rower", category: .endurance),
        WorkoutIcon(name: "bicycle", category: .endurance),
        WorkoutIcon(name: "figure.skiing.downhill", category: .endurance),
        WorkoutIcon(name: "figure.skating", category: .endurance),
        
        // Andre
        WorkoutIcon(name: "figure.yoga", category: .other),
        WorkoutIcon(name: "figure.pilates", category: .other),
        WorkoutIcon(name: "figure.mind.and.body", category: .other),
        WorkoutIcon(name: "figure.flexibility", category: .other),
        WorkoutIcon(name: "figure.barre", category: .other),
        WorkoutIcon(name: "figure.taichi", category: .other),
        WorkoutIcon(name: "figure.climbing", category: .other),
        WorkoutIcon(name: "figure.boxing", category: .other),
        WorkoutIcon(name: "figure.martial.arts", category: .other),
        WorkoutIcon(name: "figure.play", category: .other),
        WorkoutIcon(name: "mountain.2", category: .other),
        WorkoutIcon(name: "water.waves", category: .other)
    ]
    
    var filteredTypes: [WorkoutTypeItem] {
        workoutTypes.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Kategori-velger
                Picker("Category", selection: $selectedCategory) {
                    ForEach(WorkoutCategory.allCases) { category in
                        Text(category.rawValue)
                            .tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    Section(header: Text("Visible Types")) {
                        ForEach(filteredTypes.filter { $0.isVisible }) { type in
                            WorkoutTypeRow(item: type) {
                                toggleVisibility(for: type)
                            }
                        }
                        .onDelete { indexSet in
                            deleteWorkoutTypes(at: indexSet, isVisible: true)
                        }
                    }
                    
                    Section(header: Text("Hidden Types")) {
                        ForEach(filteredTypes.filter { !$0.isVisible }) { type in
                            WorkoutTypeRow(item: type) {
                                toggleVisibility(for: type)
                            }
                        }
                        .onDelete { indexSet in
                            deleteWorkoutTypes(at: indexSet, isVisible: false)
                        }
                    }
                    
                    Button(action: {
                        showingAddNew = true
                    }) {
                        Label("Add New Type", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Manage Workout Types")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .sheet(isPresented: $showingAddNew) {
                AddWorkoutTypeView(category: selectedCategory, onSave: addNewWorkoutType)
            }
        }
        .onAppear {
            loadWorkoutTypes()
        }
    }
    
    // Funksjon for å laste lagrede treningstyper
    private func loadWorkoutTypes() {
        if let savedTypes = try? JSONDecoder().decode([WorkoutTypeItem].self, from: workoutTypesData) {
            // Sjekk om vi har noen lagrede typer
            if !savedTypes.isEmpty {
                workoutTypes = savedTypes
            } else {
                // Hvis ingen lagrede typer, bruk standardtypene
                workoutTypes = defaultWorkoutTypes
            }
            
            // Oppdater ikoner for alle typer for å sikre at de er oppdaterte
            workoutTypes = workoutTypes.map { type in
                var updatedType = type
                if let defaultType = defaultWorkoutTypes.first(where: { $0.name == type.name }) {
                    updatedType.icon = defaultType.icon
                }
                return updatedType
            }
            
            // Lagre oppdaterte typer
            saveWorkoutTypes()
        } else {
            workoutTypes = defaultWorkoutTypes
            saveWorkoutTypes()
        }
    }
    
    // Funksjon for å lagre treningstyper
    private func saveWorkoutTypes() {
        if let encoded = try? JSONEncoder().encode(workoutTypes) {
            workoutTypesData = encoded
        }
    }
    
    private func toggleVisibility(for item: WorkoutTypeItem) {
        if let index = workoutTypes.firstIndex(where: { $0.id == item.id }) {
            workoutTypes[index].isVisible.toggle()
            saveWorkoutTypes()
        }
    }
    
    private func addNewWorkoutType(name: String, icon: String) {
        let newType = WorkoutTypeItem(
            name: name,
            icon: icon,
            isVisible: true,
            category: selectedCategory,
            order: workoutTypes.filter { $0.category == selectedCategory }.count
        )
        workoutTypes.append(newType)
        saveWorkoutTypes()
    }
    
    private func resetToDefaults() {
        workoutTypes = defaultWorkoutTypes
        saveWorkoutTypes()
    }
    
    // Funksjon for å slette treningstyper
    private func deleteWorkoutTypes(at offsets: IndexSet, isVisible: Bool) {
        let filteredArray = filteredTypes.filter { $0.isVisible == isVisible }
        let itemsToDelete = offsets.map { filteredArray[$0] }
        
        workoutTypes.removeAll { workoutType in
            itemsToDelete.contains { $0.id == workoutType.id }
        }
        
        saveWorkoutTypes()
    }
}

struct WorkoutTypeRow: View {
    let item: WorkoutTypeItem
    var onToggleVisibility: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(item.category.themeColor)
                .font(.title2)
            Text(item.name)
            Spacer()
            Toggle("", isOn: Binding(
                get: { item.isVisible },
                set: { _ in onToggleVisibility() }
            ))
        }
    }
}

struct AddWorkoutTypeView: View {
    let category: WorkoutCategory
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = ManageWorkoutTypesView.availableIcons[0]
    @State private var selectedCategory: WorkoutCategory
    
    init(category: WorkoutCategory, onSave: @escaping (String, String) -> Void) {
        self.category = category
        self.onSave = onSave
        _selectedCategory = State(initialValue: category)
    }
    
    var allIcons: [WorkoutIcon] {
        ManageWorkoutTypesView.availableIcons
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Workout type name", text: $name)
                
                Section(header: Text("Select Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(WorkoutCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Select Icon")) {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60))
                    ], spacing: 20) {
                        ForEach(allIcons) { icon in
                            Image(systemName: icon.name)
                                .font(.title)
                                .frame(width: 50, height: 50)
                                .background(selectedIcon.id == icon.id ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Add Workout Type")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    onSave(name, selectedIcon.name)
                    dismiss()
                }
                .disabled(name.isEmpty)
            )
        }
    }
} 