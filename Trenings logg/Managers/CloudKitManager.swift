import CloudKit
import Foundation
import SwiftUI

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    private let container: CKContainer
    private let database: CKDatabase
    
    @Published var error: String?
    
    private init() {
        container = CKContainer(identifier: "iCloud.com.Svendsenink.Trenings-logg")
        database = container.privateCloudDatabase
    }
    
    // MARK: - WorkoutSession
    func saveWorkoutSession(_ session: WorkoutSession) async throws {
        let record = session.toRecord()
        try await database.save(record)
        
        // Lagre øvelser
        for exercise in session.exercises {
            let exerciseRecord = exercise.toRecord()
            exerciseRecord["workoutSession"] = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
            try await database.save(exerciseRecord)
            
            // Lagre sett
            for set in exercise.sets {
                let setRecord = set.toRecord()
                setRecord["exercise"] = CKRecord.Reference(recordID: exerciseRecord.recordID, action: .deleteSelf)
                try await database.save(setRecord)
            }
        }
    }
    
    func fetchWorkoutSessions() async throws -> [WorkoutSession] {
        let query = CKQuery(recordType: "WorkoutSession", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let result = try await database.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        
        return try await withThrowingTaskGroup(of: WorkoutSession.self) { group in
            for record in records {
                group.addTask {
                    var session = WorkoutSession.fromRecord(record)
                    
                    // Hent øvelser
                    let exerciseQuery = CKQuery(
                        recordType: "Exercise",
                        predicate: NSPredicate(
                            format: "workoutSession == %@",
                            CKRecord.Reference(recordID: record.recordID, action: .none)
                        )
                    )
                    
                    let exerciseResult = try await self.database.records(matching: exerciseQuery)
                    let exerciseRecords = exerciseResult.matchResults.compactMap { try? $0.1.get() }
                    
                    var exercises: [Exercise] = []
                    for exerciseRecord in exerciseRecords {
                        var exercise = Exercise.fromRecord(exerciseRecord)
                        
                        // Hent sett
                        let setQuery = CKQuery(
                            recordType: "SetData",
                            predicate: NSPredicate(
                                format: "exercise == %@",
                                CKRecord.Reference(recordID: exerciseRecord.recordID, action: .none)
                            )
                        )
                        
                        let setResult = try await self.database.records(matching: setQuery)
                        let setRecords = setResult.matchResults.compactMap { try? $0.1.get() }
                        exercise.sets = setRecords.map { SetData.fromRecord($0) }
                        
                        exercises.append(exercise)
                    }
                    
                    session.exercises = exercises
                    return session
                }
            }
            
            var sessions: [WorkoutSession] = []
            for try await session in group {
                sessions.append(session)
            }
            
            return sessions.sorted { $0.date > $1.date }
        }
    }
    
    func fetchAllWorkoutSessions() async throws -> [WorkoutSession] {
        let query = CKQuery(recordType: "WorkoutSession", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let result = try await database.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        
        return try await withThrowingTaskGroup(of: WorkoutSession.self) { group in
            for record in records {
                group.addTask {
                    var session = WorkoutSession.fromRecord(record)
                    
                    // Hent øvelser
                    let exerciseQuery = CKQuery(
                        recordType: "Exercise",
                        predicate: NSPredicate(
                            format: "sessionId == %@",
                            session.id
                        )
                    )
                    
                    let exerciseResult = try await self.database.records(matching: exerciseQuery)
                    let exerciseRecords = exerciseResult.matchResults.compactMap { try? $0.1.get() }
                    
                    var exercises: [Exercise] = []
                    for exerciseRecord in exerciseRecords {
                        var exercise = Exercise.fromRecord(exerciseRecord)
                        
                        // Hent sett
                        let setQuery = CKQuery(
                            recordType: "SetData",
                            predicate: NSPredicate(
                                format: "exerciseId == %@",
                                exercise.id
                            )
                        )
                        
                        let setResult = try await self.database.records(matching: setQuery)
                        let setRecords = setResult.matchResults.compactMap { try? $0.1.get() }
                        exercise.sets = setRecords.map { SetData.fromRecord($0) }
                        
                        exercises.append(exercise)
                    }
                    
                    session.exercises = exercises
                    return session
                }
            }
            
            var sessions: [WorkoutSession] = []
            for try await session in group {
                sessions.append(session)
            }
            
            return sessions.sorted { $0.date > $1.date }
        }
    }
    
    // MARK: - WorkoutTemplate
    func saveTemplate(_ template: WorkoutTemplate) async throws {
        let record = template.toRecord()
        try await database.save(record)
        
        // Lagre øvelser
        if let exercises = template.exercises {
            for exercise in exercises {
                let exerciseRecord = exercise.toRecord()
                exerciseRecord["template"] = CKRecord.Reference(recordID: record.recordID, action: .deleteSelf)
                try await database.save(exerciseRecord)
            }
        }
    }
    
    func fetchTemplates() async throws -> [WorkoutTemplate] {
        let query = CKQuery(recordType: "WorkoutTemplate", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let result = try await database.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        
        return try await withThrowingTaskGroup(of: WorkoutTemplate.self) { group in
            for record in records {
                group.addTask {
                    var template = WorkoutTemplate.fromRecord(record)
                    
                    // Hent øvelser
                    let exerciseQuery = CKQuery(
                        recordType: "ExerciseTemplate",
                        predicate: NSPredicate(
                            format: "template == %@",
                            CKRecord.Reference(recordID: record.recordID, action: .none)
                        )
                    )
                    
                    let exerciseResult = try await self.database.records(matching: exerciseQuery)
                    let exerciseRecords = exerciseResult.matchResults.compactMap { try? $0.1.get() }
                    template.exercises = exerciseRecords.map { ExerciseTemplate.fromRecord($0) }
                    
                    return template
                }
            }
            
            var templates: [WorkoutTemplate] = []
            for try await template in group {
                templates.append(template)
            }
            
            return templates.sorted { $0.name < $1.name }
        }
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) async throws {
        let record = CKRecord.ID(recordName: template.id)
        try await database.deleteRecord(withID: record)
    }
    
    // MARK: - Exercises
    func saveExercise(_ exercise: Exercise, for sessionId: String) async throws {
        let exerciseRecord = exercise.toRecord()
        exerciseRecord["sessionId"] = sessionId as CKRecordValue
        try await database.save(exerciseRecord)
        
        // Lagre sett
        for set in exercise.sets {
            let setRecord = set.toRecord()
            setRecord["exercise"] = CKRecord.Reference(recordID: exerciseRecord.recordID, action: .deleteSelf)
            try await database.save(setRecord)
        }
    }
    
    func fetchExercises(for sessionId: String) async throws -> [Exercise] {
        let predicate = NSPredicate(format: "sessionId == %@", sessionId)
        let query = CKQuery(recordType: "Exercise", predicate: predicate)
        
        let result = try await database.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        
        return try await withThrowingTaskGroup(of: Exercise.self) { group in
            for record in records {
                group.addTask {
                    var exercise = Exercise.fromRecord(record)
                    
                    // Hent sett
                    let setQuery = CKQuery(
                        recordType: "SetData",
                        predicate: NSPredicate(
                            format: "exercise == %@",
                            CKRecord.Reference(recordID: record.recordID, action: .none)
                        )
                    )
                    
                    let setResult = try await self.database.records(matching: setQuery)
                    let setRecords = setResult.matchResults.compactMap { try? $0.1.get() }
                    exercise.sets = setRecords.map { SetData.fromRecord($0) }
                    
                    return exercise
                }
            }
            
            var exercises: [Exercise] = []
            for try await exercise in group {
                exercises.append(exercise)
            }
            
            return exercises
        }
    }
    
    // MARK: - Sets
    func saveSet(_ set: SetData, for exerciseId: String) async throws {
        let setRecord = set.toRecord()
        setRecord["exerciseId"] = exerciseId as CKRecordValue
        try await database.save(setRecord)
    }
    
    func fetchSets(for exerciseId: String) async throws -> [SetData] {
        let predicate = NSPredicate(format: "exerciseId == %@", exerciseId)
        let query = CKQuery(recordType: "SetData", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        
        let result = try await database.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        return records.map { SetData.fromRecord($0) }
    }
} 