import SwiftUI
import CoreData

struct ExportView: View {
    @FetchRequest(
        fetchRequest: CDWorkoutSession.fetchRequest(nil),
        animation: .default
    )
    private var workoutSessions: FetchedResults<CDWorkoutSession>
    @Environment(\.dismiss) private var dismiss
    
    private func generateStatistics() -> String {
        let calendar = Calendar.current
        let now = Date()
        var export = "TRENINGSSTATISTIKK\n\n"
        
        // Totalt antall økter
        export += "Totalt antall økter: \(workoutSessions.count)\n\n"
        
        // Månedsoversikt
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        let thisMonthSessions = workoutSessions.filter {
            let month = calendar.component(.month, from: $0.date ?? Date())
            let year = calendar.component(.year, from: $0.date ?? Date())
            return month == currentMonth && year == currentYear
        }
        
        export += "DENNE MÅNEDEN (\(monthName(currentMonth)))\n"
        export += "Antall økter: \(thisMonthSessions.count)\n"
        export += typeStatistics(for: thisMonthSessions)
        export += "\n"
        
        // Årsoversikt
        let thisYearSessions = workoutSessions.filter {
            calendar.component(.year, from: $0.date ?? Date()) == currentYear
        }
        
        export += "DETTE ÅRET (\(currentYear))\n"
        export += "Antall økter: \(thisYearSessions.count)\n"
        export += typeStatistics(for: thisYearSessions)
        export += "\n"
        
        // Månedlig fordeling dette året
        export += "MÅNEDLIG FORDELING \(currentYear):\n"
        for month in 1...12 {
            let monthSessions = thisYearSessions.filter {
                calendar.component(.month, from: $0.date ?? Date()) == month
            }
            if monthSessions.count > 0 {
                export += "\(monthName(month)): \(monthSessions.count) økter\n"
            }
        }
        export += "\n"
        
        // Vektstatistikk
        let weightSessions = workoutSessions
            .filter { $0.bodyWeight?.isEmpty == false }
            .sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
        
        if let lastWeight = weightSessions.first {
            export += "VEKTSTATISTIKK\n"
            export += "Sist målte vekt: \(lastWeight.bodyWeight ?? "") kg"
            export += " (\(formatDate(lastWeight.date ?? Date())))\n"
            
            if let lowestWeight = weightSessions.min(by: { 
                (Double($0.bodyWeight ?? "0") ?? 0) < (Double($1.bodyWeight ?? "0") ?? 0) 
            }) {
                export += "Laveste vekt: \(lowestWeight.bodyWeight ?? "") kg"
                export += " (\(formatDate(lowestWeight.date ?? Date())))\n"
            }
            
            if let highestWeight = weightSessions.max(by: { 
                (Double($0.bodyWeight ?? "0") ?? 0) < (Double($1.bodyWeight ?? "0") ?? 0) 
            }) {
                export += "Høyeste vekt: \(highestWeight.bodyWeight ?? "") kg"
                export += " (\(formatDate(highestWeight.date ?? Date())))\n"
            }
        }
        
        return export
    }
    
    private func typeStatistics(for sessions: [CDWorkoutSession]) -> String {
        var typeCount: [String: Int] = [:]
        for session in sessions {
            typeCount[session.type ?? "", default: 0] += 1
        }
        
        var result = "Fordeling:\n"
        for (type, count) in typeCount.sorted(by: { $0.key < $1.key }) {
            result += "- \(type): \(count) økter\n"
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
            .navigationTitle("Treningsstatistikk")
            .navigationBarItems(
                leading: Button("Lukk") { dismiss() },
                trailing: ShareLink(
                    item: generateStatistics(),
                    subject: Text("Treningsstatistikk"),
                    message: Text("Her er min treningsstatistikk")
                )
            )
        }
    }
} 