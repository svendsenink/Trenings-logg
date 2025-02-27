import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    let workoutDates: Set<Date>
    
    private let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2  // 2 = Mandag (1 er Søndag)
        return calendar
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter
    }()
    
    private let weekNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "w"  // 'w' gir ukenummer
        return formatter
    }()
    
    private let daysInWeek = ["Man", "Tir", "Ons", "Tor", "Fre", "Lør", "Søn"]
    
    private var monthStart: Date {
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        return calendar.date(from: components) ?? selectedDate
    }
    
    private var days: [Date] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
              let monthRange = calendar.range(of: .day, in: .month, for: selectedDate)
        else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offsetDays = (firstWeekday + 5) % 7 // Justerer for at uken starter på mandag
        
        let totalDays = monthRange.count
        let totalCells = ((totalDays + offsetDays - 1) / 7 + 1) * 7
        
        var days: [Date] = []
        
        // Legg til dager fra forrige måned
        if offsetDays > 0 {
            for day in (1...offsetDays).reversed() {
                if let date = calendar.date(byAdding: .day, value: -day, to: monthStart) {
                    days.append(date)
                }
            }
        }
        
        // Legg til dager i denne måneden
        for day in 0..<totalDays {
            if let date = calendar.date(byAdding: .day, value: day, to: monthStart) {
                days.append(date)
            }
        }
        
        // Legg til dager fra neste måned
        let remainingCells = totalCells - days.count
        if remainingCells > 0 {
            for day in 0..<remainingCells {
                if let date = calendar.date(byAdding: .day, value: totalDays + day, to: monthStart) {
                    days.append(date)
                }
            }
        }
        
        return days
    }
    
    // Legg til en property for dagens dato
    private let today = Date()
    
    var body: some View {
        VStack {
            // Månedvisning og navigasjonsknapper
            HStack {
                Text(monthFormatter.string(from: selectedDate))
                    .font(.title2)
                Spacer()
                
                // Legg til Today-knapp
                Button(action: {
                    withAnimation {
                        selectedDate = today
                    }
                }) {
                    Text("Today")
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                
                Button(action: { moveMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Button(action: { moveMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            // Ukedager header med ukenummer
            HStack(spacing: 0) {
                Text("W")  // Header for ukenummer
                    .font(.caption)
                    .frame(width: 30)
                
                ForEach(getWeekdaySymbols(), id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            // Datoer med ukenummer
            LazyVGrid(columns: [
                GridItem(.fixed(30)),  // Kolonne for ukenummer
                GridItem(.flexible()),  // Mandag
                GridItem(.flexible()),  // Tirsdag
                GridItem(.flexible()),  // Onsdag
                GridItem(.flexible()),  // Torsdag
                GridItem(.flexible()),  // Fredag
                GridItem(.flexible()),  // Lørdag
                GridItem(.flexible())   // Søndag
            ], spacing: 8) {
                // For hver uke
                ForEach(weeks, id: \.self) { week in
                    // Ukenummer
                    Text(weekNumberFormatter.string(from: week.first ?? Date()))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Dager i uken
                    ForEach(week, id: \.self) { date in
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasWorkout: workoutDates.contains { calendar.isDate($0, inSameDayAs: date) }
                        )
                    }
                }
            }
        }
    }
    
    private func moveMonth(by: Int) {
        if let newDate = calendar.date(byAdding: .month, value: by, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func DayCell(date: Date, isSelected: Bool, hasWorkout: Bool) -> some View {
        Button(action: {
            selectedDate = date
        }) {
            Text(dateFormatter.string(from: date))
                .foregroundColor(isSelected ? .white : .primary)
                .opacity(isDateInCurrentMonth(date) ? 1.0 : 0.3)
                .frame(width: 40, height: 40)
                .background(
                    Group {
                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                        } else if hasWorkout {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.blue, lineWidth: 5)
                                .opacity(isDateInCurrentMonth(date) ? 0.8 : 0.3)
                        }
                    }
                )
        }
    }
    
    // Hjelpefunksjon for å sjekke om en dato er i gjeldende måned
    private func isDateInCurrentMonth(_ date: Date) -> Bool {
        calendar.component(.month, from: date) == calendar.component(.month, from: selectedDate)
    }
    
    // Hjelpefunksjon for å få ukedager i riktig rekkefølge
    private func getWeekdaySymbols() -> [String] {
        let weekdays = calendar.shortWeekdaySymbols
        let sunday = weekdays.first!
        var reorderedWeekdays = Array(weekdays.dropFirst())
        reorderedWeekdays.append(sunday)
        return reorderedWeekdays
    }
    
    // Ny property for å gruppere dager i uker
    private var weeks: [[Date]] {
        let days = days
        var weeks: [[Date]] = []
        var currentWeek: [Date] = []
        
        for day in days {
            if !currentWeek.isEmpty && calendar.component(.weekOfYear, from: day) != calendar.component(.weekOfYear, from: currentWeek[0]) {
                weeks.append(currentWeek)
                currentWeek = []
            }
            currentWeek.append(day)
            
            if day == days.last {
                weeks.append(currentWeek)
            }
        }
        
        return weeks
    }
} 