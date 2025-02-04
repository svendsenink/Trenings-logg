import SwiftUI

@main
struct TreningsLoggApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                TreningsLoggContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
} 