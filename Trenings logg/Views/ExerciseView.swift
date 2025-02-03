import SwiftUI
import CoreData

struct ExerciseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var exercise: CDExercise
    
    private func addSet() {
        let set = CDSetData(context: viewContext)
        set.id = UUID()
        set.exercise = exercise
    }
    
    private func buildStrengthSetView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Sett")
                    .frame(width: 40)
                Text("Vekt")
                    .frame(width: 60)
                Text("Reps")
                    .frame(width: 60)
                Spacer()
                Button(action: addSet) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            
            // Sett
            ForEach(exercise.setArray) { set in
                HStack {
                    Text("\(exercise.setArray.firstIndex(of: set)! + 1)")
                        .frame(width: 40)
                    
                    TextField("Kg", text: Binding(
                        get: { set.weight ?? "" },
                        set: { set.weight = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
                    .keyboardType(.decimalPad)
                    
                    TextField("Reps", text: Binding(
                        get: { set.reps ?? "" },
                        set: { set.reps = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
                    .keyboardType(.numberPad)
                    
                    if exercise.setArray.count > 1 {
                        Button(action: { viewContext.delete(set) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
    
    private func buildEnduranceSetView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Sett")
                    .frame(width: 40)
                Text("Fart")
                    .frame(width: 60)
                Text("Tid")
                    .frame(width: 60)
                Text("Dist")
                    .frame(width: 60)
                Spacer()
                Button(action: addSet) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            
            // Sett
            ForEach(exercise.setArray) { set in
                VStack(spacing: 8) {
                    HStack {
                        Text("\(exercise.setArray.firstIndex(of: set)! + 1)")
                            .frame(width: 40)
                        
                        TextField("km/t", text: Binding(
                            get: { set.reps ?? "" },
                            set: { set.reps = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .keyboardType(.decimalPad)
                        
                        TextField("min", text: Binding(
                            get: { set.duration ?? "" },
                            set: { set.duration = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .keyboardType(.numberPad)
                        
                        TextField("km", text: Binding(
                            get: { set.distance ?? "" },
                            set: { set.distance = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .keyboardType(.decimalPad)
                        
                        if exercise.setArray.count > 1 {
                            Button(action: { viewContext.delete(set) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if exercise.setArray.firstIndex(of: set)! < exercise.setArray.count - 1 {
                        HStack {
                            Text("Pause:")
                                .font(.caption)
                            TextField("min", text: Binding(
                                get: { set.restPeriod ?? "" },
                                set: { set.restPeriod = $0 }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                            .keyboardType(.numberPad)
                            Spacer()
                        }
                        .padding(.leading, 40)
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                TextField("Øvelsesnavn", text: Binding(
                    get: { exercise.name ?? "" },
                    set: { exercise.name = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    exercise.increaseNextTime.toggle()
                }) {
                    Image(systemName: exercise.increaseNextTime ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
            }
            
            if let sessionType = exercise.session?.type {
                Group {
                    if sessionType.contains("Styrke") {
                        buildStrengthSetView()
                    } else if sessionType.contains("Utholdenhet") {
                        buildEnduranceSetView()
                    } else {
                        buildBasicSetView()
                    }
                }
            }
        }
    }
    
    private func buildBasicSetView() -> some View {
        HStack {
            Text("Tid:")
                .frame(width: 40)
            TextField("min", text: Binding(
                get: { exercise.setArray.first?.duration ?? "" },
                set: { 
                    if exercise.setArray.isEmpty {
                        let set = CDSetData(context: viewContext)
                        set.id = UUID()
                        set.exercise = exercise
                        set.duration = $0
                    } else {
                        exercise.setArray[0].duration = $0
                    }
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(width: 60)
            .keyboardType(.numberPad)
            Text("minutter")
                .foregroundColor(.gray)
            Spacer()
        }
    }
} 