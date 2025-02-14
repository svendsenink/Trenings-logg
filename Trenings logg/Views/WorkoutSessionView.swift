import SwiftUI

struct WorkoutSessionView: View {
    let session: CDWorkoutSession
    @State private var showingDetails = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private var workoutTypeAndTemplate: String {
        let type = session.type ?? ""
        if type.contains(" - ") {
            return type  // Returner hele strengen hvis den inneholder mal
        }
        return type     // Returner bare typen hvis ingen mal
    }
    
    var body: some View {
        Button(action: {
            showingDetails = true
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(workoutTypeAndTemplate)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: session.date ?? Date()))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .sheet(isPresented: $showingDetails) {
            WorkoutDetailView(session: session)
        }
    }
} 