import SwiftUI

struct TreningsLoggContentView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                WorkoutHistoryView()
                    .tabItem {
                        Label("Historie", systemImage: "clock")
                    }
                    .tag(0)
                
                TemplateManagerView()
                    .tabItem {
                        Label("Maler", systemImage: "list.bullet")
                    }
                    .tag(1)
                
                ManageWorkoutTypesView()
                    .tabItem {
                        Label("Kategorier", systemImage: "tag")
                    }
                    .tag(2)
                
                ExportView()
                    .tabItem {
                        Label("Eksport", systemImage: "square.and.arrow.up")
                    }
                    .tag(3)
            }
        }
    }
} 