import SwiftUI

struct WorkoutTypeButton: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    
    let type: WorkoutCategory
    let icon: String
    let title: String
    
    var body: some View {
        NavigationLink(
            destination: WorkoutLogView(
                selectedDate: $selectedDate,
                selectedCategory: type
            )
        ) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(width: 120, height: 120)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 3)
        }
    }
} 