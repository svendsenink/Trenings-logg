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
                            category: .strength,
                            workoutTypes: [.traditionalStrengthTraining, .functionalStrengthTraining]
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
                            category: .endurance,
                            workoutTypes: [.running, .cycling, .swimming, .walking, .rowing]
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
                            category: .other,
                            workoutTypes: [.hiking, .crossTraining, .yoga, .pilates, .boxing, .other]
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
    let workoutTypes: [HKWorkoutActivityType]
    
    var body: some View {
        List {
            ForEach(workoutTypes, id: \.rawValue) { type in
                NavigationLink(
                    destination: WorkoutLogView(
                        selectedDate: $selectedDate,
                        selectedCategory: category
                    )
                ) {
                    HStack {
                        Image(systemName: iconName(for: type))
                            .foregroundColor(category.themeColor)
                            .font(.system(size: 30))
                        Text(WorkoutCategory.name(for: type))
                            .font(.title2)
                            .padding(.leading, 12)
                    }
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationTitle(category.rawValue)
    }
    
    private func iconName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: return "figure.strengthtraining.traditional"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional"
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "figure.hiking"
        case .rowing: return "figure.rower"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        case .boxing: return "figure.boxing"
        default: return "figure.mixed.cardio"
        }
    }
}
