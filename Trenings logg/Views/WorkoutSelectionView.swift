import SwiftUI

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
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Select workout type")
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack(spacing: 40) {
                    WorkoutTypeButton(
                        type: .strength,
                        icon: "dumbbell.fill",
                        title: "Strength"
                    )
                    
                    WorkoutTypeButton(
                        type: .endurance,
                        icon: "figure.run",
                        title: "Endurance"
                    )
                }
                
                WorkoutTypeButton(
                    type: .other,
                    icon: "figure.mixed.cardio",
                    title: "Other"
                )
            }
            .padding()
        }
    }
} 