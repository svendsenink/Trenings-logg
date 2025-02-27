import HealthKit
import UIKit
import Foundation

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var error: String?
    
    private init() {
        print("HealthKitManager: Init starter")
        
        // Sjekk om vi har riktig capability
        if Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.healthkit") == nil {
            print("VIKTIG: HealthKit capability mangler!")
            print("Gå til Xcode -> Target -> Signing & Capabilities")
            print("Klikk + -> Søk etter 'HealthKit' -> Legg til")
            error = "HealthKit capability er ikke konfigurert"
            return
        }
        
        if HKHealthStore.isHealthDataAvailable() {
            print("HealthKit er tilgjengelig")
            
            // Sjekk direkte om vi har tilgang til HealthKit
            let workoutType = HKObjectType.workoutType()
            let status = healthStore.authorizationStatus(for: workoutType)
            print("HealthKit autorisasjonsstatus: \(status.rawValue)")
            
            // Sjekk provisioning profile
            if let provisioningPath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") {
                print("Provisioning profile funnet: \(provisioningPath)")
            } else {
                print("Ingen provisioning profile funnet - kjører i simulator?")
            }
        } else {
            print("HealthKit er IKKE tilgjengelig")
            error = "HealthKit er ikke tilgjengelig på denne enheten"
        }
        
        print("HealthKitManager: Sjekker Bundle ID")
        if let bundleId = Bundle.main.bundleIdentifier {
            print("Bundle ID: \(bundleId)")
        } else {
            print("Ingen Bundle ID funnet")
        }
        
        print("HealthKitManager: Sjekker entitlements")
        if let entitlements = Bundle.main.infoDictionary?["com.apple.developer.healthkit"] as? Bool {
            print("HealthKit entitlement funnet: \(entitlements)")
        } else {
            print("HealthKit entitlement IKKE funnet")
        }
    }
    
    func requestAuthorization() async throws {
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKQuantityType.workoutType()
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        await MainActor.run {
            isAuthorized = true
        }
    }
    
    func saveWorkout(_ workout: WorkoutSession) async throws {
        guard let workoutType = getWorkoutType(for: workout.type) else {
            throw HealthKitError.invalidWorkoutType
        }
        
        let startDate = workout.date
        let endDate = workout.date.addingTimeInterval(3600) // Standard 1 time
        let duration = endDate.timeIntervalSince(startDate)
        
        // Opprett metadata dictionary
        var metadata: [String: Any] = [:]
        if let notes = workout.notes {
            metadata["notes"] = notes
        }
        if let bodyWeight = workout.bodyWeight {
            metadata["bodyWeight"] = bodyWeight
        }
        
        // Opprett HKWorkout med eller uten kalorier
        let hkWorkout: HKWorkout
        if let calories = workout.calories {
            let energyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: Double(calories))
            hkWorkout = HKWorkout(
                activityType: workoutType,
                start: startDate,
                end: endDate,
                duration: duration,
                totalEnergyBurned: energyBurned,
                totalDistance: nil,
                metadata: metadata
            )
        } else {
            hkWorkout = HKWorkout(
                activityType: workoutType,
                start: startDate,
                end: endDate,
                duration: duration,
                totalEnergyBurned: nil,
                totalDistance: nil,
                metadata: metadata
            )
        }
        
        try await healthStore.save(hkWorkout)
    }
    
    private func getWorkoutType(for category: String) -> HKWorkoutActivityType? {
        if category.contains("Styrke") {
            return .traditionalStrengthTraining
        } else if category.contains("Utholdenhet") {
            return .running // Eller annen passende type
        } else {
            return .other
        }
    }
}

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    case invalidWorkoutType
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit er ikke tilgjengelig på denne enheten"
        case .notAuthorized:
            return "Ingen tilgang til HealthKit data. Gå til Innstillinger > Personvern > Helse for å gi tilgang."
        case .invalidWorkoutType:
            return "Ugyldig treningstype"
        }
    }
} 