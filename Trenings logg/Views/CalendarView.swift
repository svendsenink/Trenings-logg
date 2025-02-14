import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    let workoutDates: Set<Date>
    
    private let calendar = Calendar.current
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
    
    var body: some View {
        VStack(spacing: 15) {  // Behold spacing mellom elementene
            // Måned og år header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthFormatter.string(from: selectedDate))
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            
            // Legg til "I dag" knapp
            Button(action: goToToday) {
                Label("I dag", systemImage: "calendar")
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 5)
            
            // Ukedager header
            HStack {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                }
            }
            
            // Kalenderdager
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    CalendarCell(
                        date: date,
                        isCurrentMonth: calendar.isDate(date, equalTo: selectedDate, toGranularity: .month),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        hasWorkout: workoutDates.contains { calendar.isDate($0, inSameDayAs: date) }
                    )
                }
            }
        }
        .padding(.top, 10)  // Endre fra -20 til 10 for å senke kalenderen
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func goToToday() {
        selectedDate = Date()
    }
    
    private func CalendarCell(date: Date, isCurrentMonth: Bool, isSelected: Bool, hasWorkout: Bool) -> some View {
        Button(action: {
            selectedDate = date
        }) {
            Text(dateFormatter.string(from: date))
                .font(.system(size: 20))  // Øk fontstørrelsen ytterligere
                .foregroundColor(
                    isSelected ? .white :
                        hasWorkout ? .green :
                        isCurrentMonth ? .primary : .secondary
                )
                .frame(width: 40, height: 40)
                .background(
                    Group {
                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 36, height: 36)
                        } else {
                            Circle()
                                .fill(Color.clear)
                        }
                    }
                )
        }
    }
} 