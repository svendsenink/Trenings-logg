import SwiftUI
import CoreData

struct WorkoutHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date
    @State private var showingStatistics = false
    
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
                
                Button(action: {
                    showingStatistics = true
                }) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("Training Statistics")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
        }
        .sheet(isPresented: $showingStatistics) {
            ExportView()
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