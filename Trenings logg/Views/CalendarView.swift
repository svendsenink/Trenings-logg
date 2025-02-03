import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    let workoutDates: Set<Date>
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 10) {
            // Månedvisning og navigasjonsknapper
            HStack {
                Button(action: { moveMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(dateFormatter.string(from: selectedDate))
                    .font(.headline)
                Spacer()
                Button(action: { moveMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Ukedager
            HStack(spacing: 0) {
                ForEach(["Man", "Tir", "Ons", "Tor", "Fre", "Lør", "Søn"], id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                }
            }
            
            // Datoer
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(0..<daysInMonth().count, id: \.self) { index in
                    if let date = daysInMonth()[index] {
                        Text(String(calendar.component(.day, from: date)))
                            .frame(height: 45)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(getTextColor(for: date))
                            .background(
                                Circle()
                                    .fill(getBackground(for: date))
                                    .frame(width: 35, height: 35)
                            )
                            .onTapGesture {
                                selectedDate = date
                            }
                    } else {
                        Text("")
                            .frame(height: 45)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    private func getTextColor(for date: Date) -> Color {
        if calendar.isDate(date, inSameDayAs: selectedDate) {
            return .white
        }
        if workoutDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
            return .green
        }
        return .primary
    }
    
    private func getBackground(for date: Date) -> Color {
        calendar.isDate(date, inSameDayAs: selectedDate) ? .blue : .clear
    }
    
    private func moveMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func daysInMonth() -> [Date?] {
        let interval = calendar.dateInterval(of: .month, for: selectedDate)!
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let offsetDays = (firstWeekday + 5) % 7 // Juster for at uken starter på mandag
        
        let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        
        var dates: [Date?] = Array(repeating: nil, count: offsetDays)
        
        for day in 1...days {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: interval.start) {
                dates.append(date)
            }
        }
        
        // Fyll ut resten av siste uke
        while dates.count % 7 != 0 {
            dates.append(nil)
        }
        
        return dates
    }
} 