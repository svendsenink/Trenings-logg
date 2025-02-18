import SwiftUI

@main
struct TreningsLoggApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        print("APP STARTER NÅ!")
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                TreningsLoggContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
} 