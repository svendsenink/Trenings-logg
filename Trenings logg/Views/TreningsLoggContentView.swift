import SwiftUI
import CoreData

struct TreningsLoggContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    @State private var selectedDate = Date()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutSelectionView(
                selectedDate: $selectedDate
            )
            .tabItem {
                Label("Ny økt", systemImage: "plus.circle.fill")
            }
            .tag(0)
            
            WorkoutHistoryView(
                selectedDate: $selectedDate
            )
            .tabItem {
                Label("Historie", systemImage: "calendar")
            }
            .tag(1)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    TreningsLoggContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 