import SwiftUI

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newExerciseName: String
    @Binding var selectedLayout: WorkoutLayout
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Exercise name", text: $newExerciseName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Vis alltid layout-velger
            VStack(alignment: .leading) {
                Text("Select layout:")
                    .fontWeight(.medium)
                    .padding(.horizontal)
                
                Picker("Layout", selection: $selectedLayout) {
                    ForEach(WorkoutLayout.allCases, id: \.self) { layout in
                        Text(layout.rawValue).tag(layout)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .navigationTitle("Add exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { 
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    onAdd()
                }
                .disabled(newExerciseName.isEmpty)
            }
        }
    }
} 