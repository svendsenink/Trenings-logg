import SwiftUI
import HealthKit

struct WorkoutSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationStack {
            VStack {
                // Sentrert overskrift
                Text("Log Your Workout")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Tomt område for å skyve innholdet ned
                Spacer()
                    .frame(height: 40)
                
                List {
                    // Strength Section
                    NavigationLink(
                        destination: WorkoutTypeList(
                            selectedDate: $selectedDate,
                            category: .strength
                        )
                    ) {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundColor(.red)
                                .font(.system(size: 30))
                            Text("Strength Training")
                                .font(.title2)
                                .padding(.leading, 12)
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .padding(.vertical, 12)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                    
                    // Endurance Section
                    NavigationLink(
                        destination: WorkoutTypeList(
                            selectedDate: $selectedDate,
                            category: .endurance
                        )
                    ) {
                        HStack {
                            Image(systemName: "figure.run")
                                .foregroundColor(.green)
                                .font(.system(size: 30))
                            Text("Endurance Training")
                                .font(.title2)
                                .padding(.leading, 12)
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .padding(.vertical, 12)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                    
                    // Other Section
                    NavigationLink(
                        destination: WorkoutTypeList(
                            selectedDate: $selectedDate,
                            category: .other
                        )
                    ) {
                        HStack {
                            Image(systemName: "figure.mixed.cardio")
                                .foregroundColor(.yellow)
                                .font(.system(size: 30))
                            Text("Other Training")
                                .font(.title2)
                                .padding(.leading, 12)
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .padding(.vertical, 12)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarHidden(true)  // Skjul standard navigasjonsbar
        }
    }
}

// Ny view for å vise liste over treningstyper
struct WorkoutTypeList: View {
    @Binding var selectedDate: Date
    let category: WorkoutCategory
    @State private var showingManageTypes = false
    @State private var workoutTypes: [WorkoutTypeItem] = []
    
    var visibleTypes: [WorkoutTypeItem] {
        workoutTypes.filter { $0.category == category && $0.isVisible }
    }
    
    var body: some View {
        List {
            ForEach(visibleTypes) { type in
                NavigationLink(
                    destination: WorkoutLogView(
                        selectedDate: $selectedDate,
                        selectedCategory: category
                    )
                ) {
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundColor(category.themeColor)
                            .font(.system(size: 30))
                        Text(type.name)
                            .font(.title2)
                            .padding(.leading, 12)
                    }
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .padding(.vertical, 12)
                }
            }
            
            Button(action: {
                showingManageTypes = true
            }) {
                Label("Manage Workout Types", systemImage: "gear")
            }
        }
        .navigationTitle(category.rawValue)
        .sheet(isPresented: $showingManageTypes) {
            ManageWorkoutTypesView()
        }
        .onAppear {
            loadWorkoutTypes()
        }
    }
    
    private func loadWorkoutTypes() {
        if let data = UserDefaults.standard.data(forKey: "workoutTypes"),
           let savedTypes = try? JSONDecoder().decode([WorkoutTypeItem].self, from: data) {
            workoutTypes = savedTypes
        }
    }
}
