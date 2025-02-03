import SwiftUI
import CoreData

struct WorkoutHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date
    
    @FetchRequest(
        fetchRequest: CDWorkoutSession.fetchRequest(nil),
        animation: .default
    )
    private var workoutSessions: FetchedResults<CDWorkoutSession>
    
    var filteredSessions: [CDWorkoutSession] {
        workoutSessions.filter { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        VStack {
            CalendarView(
                selectedDate: $selectedDate,
                workoutDates: Set(workoutSessions.map { $0.date ?? Date() })
            )
            
            List {
                ForEach(filteredSessions) { session in
                    WorkoutSessionView(session: session)
                }
                .onDelete(perform: deleteWorkouts)
            }
        }
    }
    
    private func deleteWorkouts(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredSessions[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting workout: \(error)")
            }
        }
    }
} 