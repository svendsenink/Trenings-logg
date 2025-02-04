import SwiftUI
import CoreData

struct TreningsLoggContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                NavigationView {
                    WorkoutSelectionView()
                }
                .tabItem {
                    Label("New workout", systemImage: "plus.circle.fill")
                }
                .tag(0)
                
                NavigationView {
                    WorkoutHistoryView(selectedDate: $selectedDate)
                }
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)
            }
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    TreningsLoggContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 