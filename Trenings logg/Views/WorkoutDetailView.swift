import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
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
                                    // For styrketrening
                                    if exercise.layout == WorkoutLayout.strength.rawValue {
                                        if let reps = set.reps {
                                            Text("\(reps) reps")
                                        }
                                        if let weight = set.weight {
                                            Text("\(weight) kg")
                                        }
                                    }
                                    
                                    // For utholdenhet/intervaller
                                    if exercise.layout == WorkoutLayout.endurance.rawValue {
                                        if let speed = set.reps {
                                            Text("\(speed) km/h")
                                        }
                                        if let duration = set.duration {
                                            Text("\(duration) min")
                                        }
                                        if let distance = set.distance {
                                            Text("\(distance) km")
                                        }
                                        if let incline = set.incline {
                                            Text("\(incline)° incline")
                                        }
                                    }
                                    
                                    // For basic (tid)
                                    if exercise.layout == WorkoutLayout.basic.rawValue {
                                        if let duration = set.duration {
                                            Text("\(duration) min")
                                        }
                                    }
                                }
                                .foregroundColor(.gray)
                                
                                // Vis hvileperiode hvis den finnes
                                if let rest = set.restPeriod, !rest.isEmpty {
                                    Text("Rest: \(rest) min")
                                        .foregroundColor(.gray)
                                        .italic()
                                }
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
                    HStack {
                        Button(action: {
                            showingEditView = true
                        }) {
                            Image(systemName: "pencil")
                        }
                        
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                NavigationStack {
                    WorkoutEditView(session: session)
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