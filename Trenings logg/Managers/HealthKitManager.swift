import HealthKit
import CoreData
import UIKit

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private var healthStore: HKHealthStore?
    
    @Published var isAuthorized = false
    @Published var error: String?
    
    init() {
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
            healthStore = HKHealthStore()
            print("HealthKit er tilgjengelig")
            
            // Sjekk direkte om vi har tilgang til HealthKit
            let workoutType = HKObjectType.workoutType()
            let status = healthStore?.authorizationStatus(for: workoutType)
            print("HealthKit autorisasjonsstatus: \(status?.rawValue ?? -1)")
            
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
        print("Starter autorisasjonsforespørsel")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit er ikke tilgjengelig")
            throw HealthKitError.notAvailable
        }
        
        guard let healthStore = self.healthStore else {
            print("HealthStore er ikke initialisert")
            throw HealthKitError.notAvailable
        }
        
        // Be om tilgang til alle treningstyper
        let allTypes: Set<HKObjectType> = Set(
            WorkoutCategory.allHealthKitTypes.compactMap { type in
                HKObjectType.workoutType()
            }
        )
        
        print("Ber om tilgang til \(allTypes.count) treningstyper")
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: allTypes)
            
            // Sjekk status etter forespørsel
            let workoutType = HKObjectType.workoutType()
            let newStatus = healthStore.authorizationStatus(for: workoutType)
            print("Ny autorisasjonsstatus: \(newStatus.rawValue)")
            
            if newStatus == .sharingAuthorized {
                isAuthorized = true
                print("Tilgang innvilget!")
            } else {
                print("Tilgang ikke innvilget. Status: \(newStatus.rawValue)")
                throw HealthKitError.notAuthorized
            }
        } catch {
            print("Feil under autorisasjonsforespørsel: \(error.localizedDescription)")
            self.error = error.localizedDescription
            throw error
        }
    }
    
    func importWorkouts(into context: NSManagedObjectContext) async {
        guard isAuthorized else {
            error = "HealthKit ikke autorisert"
            return
        }
        
        do {
            let workouts = try await fetchWorkouts()
            
            for workout in workouts {
                // Sjekk om økten allerede er importert
                let fetchRequest = CDWorkoutSession.fetchRequest(
                    NSPredicate(format: "healthKitId == %@", workout.uuid.uuidString)
                )
                
                guard let existingWorkouts = try? context.fetch(fetchRequest),
                      existingWorkouts.isEmpty else {
                    continue
                }
                
                // Opprett ny økt
                let session = CDWorkoutSession(context: context)
                session.id = UUID()
                session.date = workout.startDate
                session.healthKitId = workout.uuid.uuidString
                
                // Sett type basert på HKWorkoutActivityType
                session.type = WorkoutCategory.name(for: workout.workoutActivityType)
                
                // Legg til en øvelse med varighet
                let exercise = CDExercise(context: context)
                exercise.id = UUID()
                exercise.name = "Workout"
                exercise.session = session
                exercise.layout = WorkoutLayout.basic.rawValue
                
                let set = CDSetData(context: context)
                set.id = UUID()
                set.exercise = exercise
                set.duration = String(Int(workout.duration / 60))
            }
            
            try context.save()
            
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func fetchWorkouts() async throws -> [HKWorkout] {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }
        
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .greaterThan, duration: 0)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: workoutPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { (_, samples, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
}

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit er ikke tilgjengelig på denne enheten"
        case .notAuthorized:
            return "Ingen tilgang til HealthKit data. Gå til Innstillinger > Personvern > Helse for å gi tilgang."
        }
    }
} 