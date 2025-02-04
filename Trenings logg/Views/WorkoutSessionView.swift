import SwiftUI

struct WorkoutSessionView: View {
    let session: CDWorkoutSession
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formatWorkoutType(session.type ?? ""))
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Text(dateFormatter.string(from: session.date ?? Date()))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
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
                }
                Divider()
            }
            
            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if let calories = session.calories, !calories.isEmpty {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(calories) kcal")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatWorkoutType(_ type: String) -> String {
        if type.contains("Other training") {
            if let range = type.range(of: "\\((.+?)\\)", options: .regularExpression) {
                let templateName = type[range]
                    .replacingOccurrences(of: "(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                return "Other training (\(templateName))"
            }
        }
        return type
    }
} 