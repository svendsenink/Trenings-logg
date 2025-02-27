import SwiftUI
import CloudKit

@main
struct TreningsLoggApp: App {
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    init() {
        print("APP STARTER NÅ!")
    }
    
    var body: some Scene {
        WindowGroup {
            TreningsLoggContentView()
                .environmentObject(cloudKitManager)
                .environmentObject(healthKitManager)
        }
    }
} 