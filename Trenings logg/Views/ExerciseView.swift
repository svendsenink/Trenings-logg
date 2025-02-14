import SwiftUI
import CoreData

struct ExerciseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var exercise: CDExercise
    let selectedCategory: WorkoutCategory
    let selectedLayout: WorkoutLayout
    
    @State private var sets: [CDSetData] = []
    @State private var lastWorkoutData: String = ""  // For å vise siste økt
    
    @FocusState private var focusedField: String?
    @State private var isEditing: Set<String> = []
    
    @State private var previousValues: [String: String] = [:]  // Legg til denne for å lagre tidligere verdier
    @State private var justGotFocus: Set<String> = []  // Legg til denne nye tilstanden
    
    private func addSet() {
        withAnimation {
            let set = CDSetData(context: viewContext)
            set.id = UUID()
            set.exercise = exercise
            sets.append(set)
            
            do {
                try viewContext.save()
            } catch {
                print("Error adding set: \(error)")
            }
        }
    }
    
    private func deleteSet(_ set: CDSetData) {
        withAnimation {
            if let index = sets.firstIndex(of: set) {
                sets.remove(at: index)
                viewContext.delete(set)
                
                do {
                    try viewContext.save()
                } catch {
                    print("Error deleting set: \(error)")
                }
            }
        }
    }
    
    private func fetchLastWorkoutData() {
        let request = CDWorkoutSession.fetchRequest(NSPredicate(format: "type CONTAINS %@", selectedCategory.rawValue))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWorkoutSession.date, ascending: false)]
        request.fetchLimit = 1
        
        if let lastSession = try? viewContext.fetch(request).first,
           let exerciseName = exercise.name,
           let matchingExercise = lastSession.exerciseArray.first(where: { $0.name == exerciseName }) {
            
            // Sjekk om øvelsen var markert for økning sist
            if matchingExercise.increaseNextTime {
                exercise.increaseNextTime = true  // Behold stjernen
                // Her kunne vi også vist en melding eller indikator om at vekt/reps bør økes
            }
            
            // Oppdater settene med data fra siste økt
            if sets.isEmpty {
                // Fjern eventuelle eksisterende sett
                for set in exercise.setArray {
                    viewContext.delete(set)
                }
                
                // Kopier sett fra siste økt
                for lastSet in matchingExercise.setArray {
                    let newSet = CDSetData(context: viewContext)
                    newSet.id = UUID()
                    newSet.exercise = exercise
                    
                    // Lagre de gamle verdiene i previousValues dictionary
                    if let id = newSet.id?.uuidString {
                        if selectedCategory == .strength {
                            previousValues["\(id)-weight"] = lastSet.weight
                            previousValues["\(id)-reps"] = lastSet.reps
                            
                            // Kopier også verdiene til det nye settet
                            newSet.weight = lastSet.weight
                            newSet.reps = lastSet.reps
                        } else if selectedCategory == .endurance {
                            previousValues["\(id)-speed"] = lastSet.reps
                            previousValues["\(id)-incline"] = lastSet.incline
                            previousValues["\(id)-time"] = lastSet.duration
                            previousValues["\(id)-dist"] = lastSet.distance
                            previousValues["\(id)-rest"] = lastSet.restPeriod
                            
                            // Kopier verdiene for utholdenhet
                            newSet.reps = lastSet.reps  // speed
                            newSet.incline = lastSet.incline
                            newSet.duration = lastSet.duration
                            newSet.distance = lastSet.distance
                            newSet.restPeriod = lastSet.restPeriod
                        }
                    }
                    
                    sets.append(newSet)
                }
                
                do {
                    try viewContext.save()
                } catch {
                    print("Error saving sets: \(error)")
                }
            } else {
                // Hvis sett allerede eksisterer, oppdater bare previousValues
                for (index, set) in sets.enumerated() {
                    if let id = set.id?.uuidString,
                       index < matchingExercise.setArray.count {
                        let lastSet = matchingExercise.setArray[index]
                        if selectedCategory == .strength {
                            previousValues["\(id)-weight"] = lastSet.weight
                            previousValues["\(id)-reps"] = lastSet.reps
                        } else if selectedCategory == .endurance {
                            previousValues["\(id)-speed"] = lastSet.reps
                            previousValues["\(id)-incline"] = lastSet.incline
                            previousValues["\(id)-time"] = lastSet.duration
                            previousValues["\(id)-dist"] = lastSet.distance
                            previousValues["\(id)-rest"] = lastSet.restPeriod
                        }
                    }
                }
            }
        }
    }
    
    private var shouldShowTotals: Bool {
        selectedLayout == .endurance && exercise.setArray.count >= 2
    }
    
    private var totals: (time: Double, distance: Double, avgSpeed: Double?) {
        let sets = exercise.setArray
        var totalTime: Double = 0
        var totalDistance: Double = 0
        
        for set in sets {
            totalTime += Double(set.duration ?? "0") ?? 0
            totalDistance += Double(set.distance ?? "0") ?? 0
        }
        
        // Beregn gjennomsnittsfart (min/km) hvis både tid og distanse er større enn 0
        let avgSpeed: Double?
        if totalTime > 0 && totalDistance > 0 {
            avgSpeed = totalTime / totalDistance
        } else {
            avgSpeed = nil
        }
        
        return (totalTime, totalDistance, avgSpeed)
    }
    
    private func buildStrengthSetView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Set")
                    .frame(width: 40)
                Text("Weight")
                    .frame(width: 60)
                Text("Reps")
                    .frame(width: 60)
                Spacer()
                Button(action: addSet) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 5)
            }
            .font(.caption)
            .fontWeight(.medium)
            
            // Sett
            ForEach(sets) { set in
                HStack {
                    Text("\(sets.firstIndex(of: set)! + 1)")
                        .frame(width: 40)
                    
                    let weightId = "\(set.id?.uuidString ?? "")-weight"
                    TextField("", text: Binding(
                        get: { 
                            if justGotFocus.contains(weightId) {
                                return ""
                            } else if isEditing.contains(weightId) {
                                return set.weight ?? ""
                            } else {
                                return previousValues[weightId] ?? ""
                            }
                        },
                        set: { newValue in
                            set.weight = newValue
                            if !newValue.isEmpty {
                                isEditing.insert(weightId)
                                justGotFocus.remove(weightId)  // Fjern fra justGotFocus når brukeren begynner å skrive
                            }
                            try? viewContext.save()
                        }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
                    .keyboardType(.decimalPad)
                    .foregroundColor(isEditing.contains(weightId) ? .primary : .gray)
                    .focused($focusedField, equals: weightId)
                    .onChange(of: focusedField) { _, newValue in
                        if newValue == weightId {
                            justGotFocus.insert(weightId)
                        }
                    }
                    
                    let repsId = "\(set.id?.uuidString ?? "")-reps"
                    TextField("", text: Binding(
                        get: { 
                            if justGotFocus.contains(repsId) {
                                return ""
                            } else if isEditing.contains(repsId) {
                                return set.reps ?? ""
                            } else {
                                return previousValues[repsId] ?? ""
                            }
                        },
                        set: { newValue in
                            set.reps = newValue
                            if !newValue.isEmpty {
                                isEditing.insert(repsId)
                                justGotFocus.remove(repsId)  // Fjern fra justGotFocus når brukeren begynner å skrive
                            }
                            try? viewContext.save()
                        }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
                    .keyboardType(.numberPad)
                    .foregroundColor(isEditing.contains(repsId) ? .primary : .gray)
                    .focused($focusedField, equals: repsId)
                    .onChange(of: focusedField) { _, newValue in
                        if newValue == repsId {
                            justGotFocus.insert(repsId)
                        }
                    }
                    
                    if sets.count > 1 {
                        Button(action: { deleteSet(set) }) {
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
                Text("Set")
                    .frame(width: 40)
                Text("Speed")
                    .frame(width: 60)
                Text("Incline")  // Ny header for stigning
                    .frame(width: 60)
                Text("Time")
                    .frame(width: 60)
                Text("Dist")
                    .frame(width: 60)
                Spacer()
                Button(action: addSet) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 5)
            }
            .font(.caption)
            .fontWeight(.medium)
            
            // Sett
            ForEach(sets) { set in
                VStack(spacing: 8) {
                    HStack(alignment: .center) {
                        Text("\(sets.firstIndex(of: set)! + 1)")
                            .frame(width: 40)
                        
                        let speedId = "\(set.id?.uuidString ?? "")-speed"
                        TextField("", text: Binding(
                            get: { 
                                if justGotFocus.contains(speedId) {
                                    return ""
                                } else if isEditing.contains(speedId) {
                                    return set.reps ?? ""
                                } else {
                                    return previousValues[speedId] ?? ""
                                }
                            },
                            set: { newValue in
                                set.reps = newValue
                                if !newValue.isEmpty {
                                    isEditing.insert(speedId)
                                    justGotFocus.remove(speedId)
                                }
                                try? viewContext.save()
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .keyboardType(.decimalPad)
                        .foregroundColor(isEditing.contains(speedId) ? .primary : .gray)
                        .focused($focusedField, equals: speedId)
                        .onChange(of: focusedField) { _, newValue in
                            if newValue == speedId {
                                justGotFocus.insert(speedId)
                            }
                        }
                        
                        let inclineId = "\(set.id?.uuidString ?? "")-incline"
                        TextField("", text: Binding(
                            get: { 
                                if justGotFocus.contains(inclineId) {
                                    return ""
                                } else if isEditing.contains(inclineId) {
                                    return set.incline ?? ""
                                } else {
                                    return previousValues[inclineId] ?? ""
                                }
                            },
                            set: { newValue in
                                set.incline = newValue
                                if !newValue.isEmpty {
                                    isEditing.insert(inclineId)
                                    justGotFocus.remove(inclineId)
                                }
                                try? viewContext.save()
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .keyboardType(.decimalPad)
                        .foregroundColor(isEditing.contains(inclineId) ? .primary : .gray)
                        .focused($focusedField, equals: inclineId)
                        .onChange(of: focusedField) { _, newValue in
                            if newValue == inclineId {
                                justGotFocus.insert(inclineId)
                            }
                        }
                        
                        let timeId = "\(set.id?.uuidString ?? "")-time"
                        TextField("", text: Binding(
                            get: { 
                                if justGotFocus.contains(timeId) {
                                    return ""
                                } else if isEditing.contains(timeId) {
                                    return set.duration ?? ""
                                } else {
                                    return previousValues[timeId] ?? ""
                                }
                            },
                            set: { newValue in
                                set.duration = newValue
                                if !newValue.isEmpty {
                                    isEditing.insert(timeId)
                                    justGotFocus.remove(timeId)
                                }
                                try? viewContext.save()
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .keyboardType(.numberPad)
                        .foregroundColor(isEditing.contains(timeId) ? .primary : .gray)
                        .focused($focusedField, equals: timeId)
                        .onChange(of: focusedField) { _, newValue in
                            if newValue == timeId {
                                justGotFocus.insert(timeId)
                            }
                        }
                        
                        let distId = "\(set.id?.uuidString ?? "")-dist"
                        TextField("", text: Binding(
                            get: { 
                                if justGotFocus.contains(distId) {
                                    return ""
                                } else if isEditing.contains(distId) {
                                    return set.distance ?? ""
                                } else {
                                    return previousValues[distId] ?? ""
                                }
                            },
                            set: { newValue in
                                set.distance = newValue
                                if !newValue.isEmpty {
                                    isEditing.insert(distId)
                                    justGotFocus.remove(distId)
                                }
                                try? viewContext.save()
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .keyboardType(.decimalPad)
                        .foregroundColor(isEditing.contains(distId) ? .primary : .gray)
                        .focused($focusedField, equals: distId)
                        .onChange(of: focusedField) { _, newValue in
                            if newValue == distId {
                                justGotFocus.insert(distId)
                            }
                        }
                        
                        if sets.count > 1 {
                            Button(action: { deleteSet(set) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Rest periode
                    if sets.firstIndex(of: set)! < sets.count - 1 {
                        HStack {
                            Text("Rest:")
                                .font(.caption)
                                .frame(width: 40, alignment: .leading)
                            
                            let restId = "\(set.id?.uuidString ?? "")-rest"
                            TextField("", text: Binding(
                                get: { 
                                    if justGotFocus.contains(restId) {
                                        return ""
                                    } else if isEditing.contains(restId) {
                                        return set.restPeriod ?? ""
                                    } else {
                                        return previousValues[restId] ?? ""
                                    }
                                },
                                set: { newValue in
                                    set.restPeriod = newValue
                                    if !newValue.isEmpty {
                                        isEditing.insert(restId)
                                        justGotFocus.remove(restId)
                                    }
                                    try? viewContext.save()
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                            .keyboardType(.numberPad)
                            .foregroundColor(isEditing.contains(restId) ? .primary : .gray)
                            .focused($focusedField, equals: restId)
                            .onChange(of: focusedField) { _, newValue in
                                if newValue == restId {
                                    justGotFocus.insert(restId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                TextField("Exercise name", text: Binding(
                    get: { exercise.name ?? "" },
                    set: { exercise.name = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    withAnimation {
                        exercise.increaseNextTime.toggle()
                        try? viewContext.save()
                    }
                }) {
                    Image(systemName: exercise.increaseNextTime ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 5)
            }
            
            Group {
                if let layoutString = exercise.layout,
                   let layout = WorkoutLayout(rawValue: layoutString) {
                    switch layout {
                    case .strength:
                        buildStrengthSetView()
                    case .endurance:
                        buildEnduranceSetView()
                    case .basic:
                        buildBasicSetView()
                    }
                }
            }
            
            // Vis totaler for utholdenhetstrening med 2+ sett
            if shouldShowTotals {
                Divider()
                HStack {
                    Text("Total:")
                        .fontWeight(.medium)
                    Spacer()
                    if totals.time > 0 {
                        Text("\(String(format: "%.0f", totals.time)) min")
                    }
                    if totals.distance > 0 {
                        Text("\(String(format: "%.1f", totals.distance)) km")
                    }
                    if let avgSpeed = totals.avgSpeed {
                        Text("(\(String(format: "%.1f", avgSpeed)) min/km)")
                    }
                }
                .foregroundColor(.gray)
                .padding(.top, 5)
            }
        }
        .onAppear {
            if sets.isEmpty {
                sets = exercise.setArray
                fetchLastWorkoutData()
            }
        }
    }
    
    private func buildBasicSetView() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Set")
                    .frame(width: 40)
                Text("Time")
                    .frame(width: 60)
                Spacer()
                Button(action: addSet) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 5)
            }
            .font(.caption)
            .fontWeight(.medium)
            
            // Sett
            ForEach(sets) { set in
                VStack(spacing: 8) {
                    HStack {
                        Text("\(sets.firstIndex(of: set)! + 1)")
                            .frame(width: 40)
                        
                        let timeId = "\(set.id?.uuidString ?? "")-time"
                        TextField("", text: Binding(
                            get: { 
                                if justGotFocus.contains(timeId) {
                                    return ""
                                } else if isEditing.contains(timeId) {
                                    return set.duration ?? ""
                                } else {
                                    return previousValues[timeId] ?? ""
                                }
                            },
                            set: { 
                                set.duration = $0
                                if !$0.isEmpty {
                                    isEditing.insert(timeId)
                                    justGotFocus.remove(timeId)
                                }
                                try? viewContext.save()
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                        .keyboardType(.numberPad)
                        .foregroundColor(isEditing.contains(timeId) ? .primary : .gray)
                        .focused($focusedField, equals: timeId)
                        .onChange(of: focusedField) { _, newValue in
                            if newValue == timeId {
                                justGotFocus.insert(timeId)
                            }
                        }
                        
                        Text("minutes")
                            .foregroundColor(.gray)
                        
                        if sets.count > 1 {
                            Button(action: { deleteSet(set) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Rest periode (vis bare hvis det ikke er siste sett)
                    if sets.firstIndex(of: set)! < sets.count - 1 {
                        HStack {
                            Text("Rest:")
                                .font(.caption)
                                .frame(width: 40, alignment: .leading)
                            
                            let restId = "\(set.id?.uuidString ?? "")-rest"
                            TextField("", text: Binding(
                                get: { 
                                    if justGotFocus.contains(restId) {
                                        return ""
                                    } else if isEditing.contains(restId) {
                                        return set.restPeriod ?? ""
                                    } else {
                                        return previousValues[restId] ?? ""
                                    }
                                },
                                set: { 
                                    set.restPeriod = $0
                                    if !$0.isEmpty {
                                        isEditing.insert(restId)
                                        justGotFocus.remove(restId)
                                    }
                                    try? viewContext.save()
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                            .keyboardType(.numberPad)
                            .foregroundColor(isEditing.contains(restId) ? .primary : .gray)
                            .focused($focusedField, equals: restId)
                            .onChange(of: focusedField) { _, newValue in
                                if newValue == restId {
                                    justGotFocus.insert(restId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
} 