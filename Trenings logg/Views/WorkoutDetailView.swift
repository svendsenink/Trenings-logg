import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let session: CDWorkoutSession
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "nb_NO")  // Norsk formatering
        return formatter
    }()
    
    var body: some View {
        NavigationStack {  // Endret fra NavigationView til NavigationStack
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Øvelser
                    ForEach(session.exerciseArray) { exercise in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(exercise.name ?? "")
                                    .font(.headline)
                                if exercise.increaseNextTime {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                            
                            ForEach(exercise.setArray) { set in
                                HStack {
                                    if let reps = set.reps {
                                        Text("\(reps) reps")
                                    }
                                    if let weight = set.weight {
                                        Text("\(weight) kg")
                                    }
                                    if let duration = set.duration {
                                        Text("\(duration) min")
                                    }
                                    if let distance = set.distance {
                                        Text("\(distance) km")
                                    }
                                }
                                .foregroundColor(.gray)
                            }
                            Divider()
                        }
                    }
                    
                    // Noter
                    if let notes = session.notes, !notes.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Notes:")
                                .font(.headline)
                            Text(notes)
                        }
                    }
                    
                    // Kalorier og kroppsvekt
                    HStack {
                        if let calories = session.calories, !calories.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Calories:")
                                    .font(.headline)
                                Text("\(calories) kcal")
                            }
                        }
                        
                        if let bodyWeight = session.bodyWeight, !bodyWeight.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Body weight:")
                                    .font(.headline)
                                Text("\(bodyWeight) kg")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(dateFormatter.string(from: session.date ?? Date()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let session = CDWorkoutSession(context: context)
    session.date = Date()
    session.type = "Strength"
    return WorkoutDetailView(session: session)
        .environment(\.managedObjectContext, context)
} 