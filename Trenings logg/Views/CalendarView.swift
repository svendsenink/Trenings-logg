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
            for day in (offsetDays - 1)...0 {
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
        VStack {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }
                
                Text(monthFormatter.string(from: selectedDate))
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            // Ukedager
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
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: selectedDate, toGranularity: .month),
                        hasWorkout: workoutDates.contains { calendar.isDate($0, inSameDayAs: date) }
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
        }
        .padding()
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
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasWorkout: Bool
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.blue : Color.clear)
                .overlay(
                    Circle()
                        .stroke(hasWorkout ? Color.blue : Color.clear, lineWidth: 1)
                )
            
            Text(dateFormatter.string(from: date))
                .foregroundColor(
                    isSelected ? .white :
                        isCurrentMonth ? .primary : .secondary
                )
        }
        .frame(height: 35)
    }
} 