import SwiftUI

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newExerciseName: String
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Øvelsesnavn", text: $newExerciseName)
            }
            .navigationTitle("Legg til øvelse")
            .navigationBarItems(
                leading: Button("Avbryt") { dismiss() },
                trailing: Button("Legg til") {
                    if !newExerciseName.isEmpty {
                        dismiss()
                    }
                }
                .disabled(newExerciseName.isEmpty)
            )
        }
    }
} 