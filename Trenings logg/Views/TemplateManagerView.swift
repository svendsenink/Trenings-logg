import SwiftUI
import CoreData

struct TemplateManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // Grupperer maler etter type
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CDWorkoutTemplate.type, ascending: true),
            NSSortDescriptor(keyPath: \CDWorkoutTemplate.name, ascending: true)
        ],
        animation: .default
    ) private var templates: FetchedResults<CDWorkoutTemplate>
    
    var groupedTemplates: [String: [CDWorkoutTemplate]] {
        Dictionary(grouping: templates) { $0.type ?? "" }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedTemplates.keys.sorted(), id: \.self) { type in
                    Section(header: Text(type)) {
                        ForEach(groupedTemplates[type] ?? []) { template in
                            NavigationLink(destination: EditTemplateView(template: template)) {
                                VStack(alignment: .leading) {
                                    Text(template.name ?? "")
                                        .font(.headline)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            deleteTemplates(type: type, at: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("Templates")
            .navigationBarItems(
                leading: Button("Close") { dismiss() }
            )
        }
    }
    
    private func deleteTemplates(type: String, at offsets: IndexSet) {
        withAnimation {
            let templatesForType = groupedTemplates[type] ?? []
            offsets.map { templatesForType[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting template: \(error)")
            }
        }
    }
} 