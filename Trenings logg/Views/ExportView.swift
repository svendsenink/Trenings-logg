import SwiftUI
import CoreData

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        fetchRequest: CDWorkoutSession.fetchRequest(nil),
        animation: .default
    )
    private var workoutSessions: FetchedResults<CDWorkoutSession>
    
    private let calendar = Calendar.current
    
    // Legg til disse hjelpefunksjonene
    private var currentMonth: Int? {
        calendar.component(.month, from: Date())
    }
    
    private var monthlyWorkouts: [CDWorkoutSession] {
        let now = Date()
        return workoutSessions.filter {
            let month = calendar.component(.month, from: $0.date ?? Date())
            let year = calendar.component(.year, from: $0.date ?? Date())
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            return month == currentMonth && year == currentYear
        }
    }
    
    private var yearlyWorkouts: [CDWorkoutSession] {
        let now = Date()
        return workoutSessions.filter {
            let year = calendar.component(.year, from: $0.date ?? Date())
            let currentYear = calendar.component(.year, from: now)
            return year == currentYear
        }
    }
    
    private func generateStatistics() -> String {
        var export = "TRAINING STATISTICS\n\n"
        
        export += "Total workouts: \(workoutSessions.count)\n\n"
        
        // Denne måneden
        if let currentMonth = currentMonth {
            export += "THIS MONTH (\(monthName(currentMonth)))\n"
            export += "Number of workouts: \(monthlyWorkouts.count)\n"
            export += typeStatistics(for: monthlyWorkouts)
            export += "\n"
        }
        
        // Dette året
        export += "THIS YEAR (2025)\n"
        export += "Number of workouts: \(yearlyWorkouts.count)\n"
        export += typeStatistics(for: yearlyWorkouts)
        export += "\n"
        
        // Månedlig fordeling
        export += "MONTHLY DISTRIBUTION 2025:\n"
        for month in 1...12 {
            let monthlyCount = workoutSessions.filter {
                let components = calendar.dateComponents([.year, .month], from: $0.date ?? Date())
                return components.year == 2025 && components.month == month
            }.count
            if monthlyCount > 0 {
                export += "\(monthName(month).lowercased()): \(monthlyCount) workouts\n"
            }
        }
        
        // Vektstatistikk
        if let bodyWeightSessions = workoutSessions.filter({ $0.bodyWeight != nil && !$0.bodyWeight!.isEmpty }) as? [CDWorkoutSession] {
            export += "\nWEIGHT STATISTICS\n"
            if let lastWeight = bodyWeightSessions.sorted(by: {
                ($0.date ?? Date()) > ($1.date ?? Date())
            }).first {
                export += "Last measured weight: \(lastWeight.bodyWeight ?? "") kg"
                export += " (\(formatDate(lastWeight.date ?? Date())))\n"
            }
            
            if let lowestWeight = bodyWeightSessions.min(by: {
                (Double($0.bodyWeight ?? "0") ?? 0) < (Double($1.bodyWeight ?? "0") ?? 0)
            }) {
                export += "Lowest weight: \(lowestWeight.bodyWeight ?? "") kg"
                export += " (\(formatDate(lowestWeight.date ?? Date())))\n"
            }
            
            if let highestWeight = bodyWeightSessions.max(by: {
                (Double($0.bodyWeight ?? "0") ?? 0) < (Double($1.bodyWeight ?? "0") ?? 0)
            }) {
                export += "Highest weight: \(highestWeight.bodyWeight ?? "") kg"
                export += " (\(formatDate(highestWeight.date ?? Date())))\n"
            }
        }
        
        return export
    }
    
    private func typeStatistics(for sessions: [CDWorkoutSession]) -> String {
        var typeCount: [String: Int] = [:]
        
        for session in sessions {
            let type = session.type ?? ""
            typeCount[type, default: 0] += 1
        }
        
        var result = "Distribution:\n"
        for (type, count) in typeCount.sorted(by: { $0.key < $1.key }) {
            result += "- \(type): \(count) workout\(count == 1 ? "" : "s")\n"
        }
        return result
    }
    
    private func monthName(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "nb_NO")
        return dateFormatter.monthSymbols[month - 1]
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(generateStatistics())
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Training Statistics")
            .navigationBarItems(
                leading: Button("Close") { dismiss() },
                trailing: ShareLink(
                    item: generateStatistics(),
                    subject: Text("Training Statistics"),
                    message: Text("Here is my training statistics")
                )
            )
        }
    }
} 