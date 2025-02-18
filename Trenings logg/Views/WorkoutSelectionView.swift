import SwiftUI
import HealthKit

struct WorkoutCategoryCard: View {
    let category: WorkoutCategory
    
    // Returnerer passende bilde for hver kategori
    private var backgroundImage: String {
        switch category {
        case .strength:
            return "strength_background"
        case .endurance:
            return "endurance_background"
        case .other:
            return "other_background"
        }
    }
    
    // Returnerer passende ikon for hver kategori
    private var categoryIcon: String {
        switch category {
        case .strength:
            return "dumbbell.fill"
        case .endurance:
            return "figure.run"
        case .other:
            return "figure.mixed.cardio"  // Generelt treningsikon
        }
    }
    
    var body: some View {
        ZStack {
            // Bakgrunnsbilde med overlay
            Image(backgroundImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.black.opacity(0.6), .black.opacity(0.3)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            
            // Innhold
            VStack {
                Image(systemName: categoryIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                Text(category.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(radius: 5)
    }
}

struct WorkoutSelectionView: View {
    let selectedDate: Date
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)
            ], spacing: 20) {
                ForEach(WorkoutCategory.allHealthKitTypes, id: \.rawValue) { type in
                    WorkoutTypeButton(
                        type: WorkoutCategory.from(healthKitType: type),
                        icon: iconName(for: type),
                        title: WorkoutCategory.name(for: type),
                        selectedDate: selectedDate
                    )
                }
            }
            .padding()
        }
        .navigationTitle("New workout")
    }
    
    private func iconName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: return "figure.strengthtraining.traditional"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional"
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.cycling"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "figure.hiking"
        case .rowing: return "figure.rower"
        case .crossTraining: return "figure.mixed.cardio"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        case .boxing: return "figure.boxing"
        case .other: return "figure.mixed.cardio"
        default: return "figure.mixed.cardio"
        }
    }
} 