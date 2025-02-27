import SwiftUI
import UIKit

struct WorkoutHistoryView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @State private var workoutSessions: [WorkoutSession] = []
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingNewWorkout = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(workoutSessions) { session in
                        NavigationLink {
                            WorkoutDetailView(workout: session)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(session.type)
                                    .font(.headline)
                                Text(dateFormatter.string(from: session.date))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Treningsøkter")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewWorkout = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewWorkout) {
            NavigationView {
                WorkoutSelectionView(selectedDate: .constant(Date()))
            }
        }
        .task {
            await loadWorkoutSessions()
        }
        .alert("Feil", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .refreshable {
            await loadWorkoutSessions()
        }
    }
    
    private func loadWorkoutSessions() async {
        do {
            workoutSessions = try await cloudKitManager.fetchWorkoutSessions()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            isLoading = false
        }
    }
}

#Preview {
    WorkoutHistoryView()
        .environmentObject(CloudKitManager.shared)
} 