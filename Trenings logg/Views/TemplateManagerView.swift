import SwiftUI

struct TemplateManagerView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var templates: [WorkoutTemplate] = []
    @State private var showingDeleteAlert = false
    @State private var templateToDelete: WorkoutTemplate?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showingError = false
    
    private func loadTemplates() async {
        do {
            templates = try await cloudKitManager.fetchTemplates()
            isLoading = false
        } catch {
            self.error = error
            showingError = true
            isLoading = false
        }
    }
    
    private func deleteTemplate(_ template: WorkoutTemplate) {
        Task {
            do {
                try await cloudKitManager.deleteTemplate(template)
                if let index = templates.firstIndex(where: { $0.id == template.id }) {
                    templates.remove(at: index)
                }
            } catch {
                self.error = error
                showingError = true
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(WorkoutCategory.allCases) { category in
                Section(header: Text(category.rawValue)) {
                    ForEach(templates.filter { $0.type == category.rawValue }) { template in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(template.name)
                                    .font(.headline)
                                if let exercises = template.exercises {
                                    Text("\(exercises.count) øvelser")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                templateToDelete = template
                                showingDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Administrer maler")
        .navigationBarItems(trailing: Button("Ferdig") { dismiss() })
        .alert("Slett mal", isPresented: $showingDeleteAlert) {
            Button("Avbryt", role: .cancel) { }
            Button("Slett", role: .destructive) {
                if let template = templateToDelete {
                    deleteTemplate(template)
                }
            }
        } message: {
            if let template = templateToDelete {
                Text("Er du sikker på at du vil slette malen '\(template.name)'?")
            }
        }
        .alert("Feil", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = error {
                Text("Det oppstod en feil: \(error.localizedDescription)")
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            await loadTemplates()
        }
    }
}

#Preview {
    NavigationView {
        TemplateManagerView()
            .environmentObject(CloudKitManager.shared)
    }
} 