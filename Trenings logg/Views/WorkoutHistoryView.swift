import SwiftUI
import CoreData

struct WorkoutHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date
    @State private var showingStatistics = false
    @State private var showingWorkoutSelection = false
    
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
                Button(action: {
                    showingWorkoutSelection = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add workout")
                    }
                    .foregroundColor(.blue)
                }
                
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
        .sheet(isPresented: $showingWorkoutSelection) {
            NavigationView {
                WorkoutSelectionView(selectedDate: selectedDate)
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