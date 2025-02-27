import Foundation
import CloudKit
import SwiftUI

struct WorkoutSession: Identifiable, Codable {
    let id: String
    var date: Date
    var type: String
    var notes: String?
    var bodyWeight: String?
    var calories: Int?
    var healthKitId: String?
    var exercises: [Exercise]
    
    init(id: String = UUID().uuidString, 
         date: Date = Date(),
         type: String,
         notes: String? = nil,
         bodyWeight: String? = nil,
         calories: Int? = nil,
         healthKitId: String? = nil,
         exercises: [Exercise] = []) {
        self.id = id
        self.date = date
        self.type = type
        self.notes = notes
        self.bodyWeight = bodyWeight
        self.calories = calories
        self.healthKitId = healthKitId
        self.exercises = exercises
    }
}

struct Exercise: Identifiable, Codable {
    let id: String
    var name: String
    var layout: WorkoutLayout
    var sets: [SetData]
    var increaseNextTime: Bool
    
    init(id: String = UUID().uuidString,
         name: String,
         layout: WorkoutLayout = .basic,
         sets: [SetData] = [],
         increaseNextTime: Bool = false) {
        self.id = id
        self.name = name
        self.layout = layout
        self.sets = sets
        self.increaseNextTime = increaseNextTime
    }
}

struct SetData: Identifiable, Codable {
    let id: String
    var weight: String?
    var reps: String?
    var duration: String?
    var distance: String?
    var incline: String?
    var restPeriod: String?
    var order: Int
    var notes: String?
    
    init(id: String = UUID().uuidString,
         weight: String? = nil,
         reps: String? = nil,
         duration: String? = nil,
         distance: String? = nil,
         incline: String? = nil,
         restPeriod: String? = nil,
         order: Int = 0,
         notes: String? = nil) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.duration = duration
        self.distance = distance
        self.incline = incline
        self.restPeriod = restPeriod
        self.order = order
        self.notes = notes
    }
}

struct WorkoutTemplate: Identifiable {
    let id: String
    var name: String
    var type: String
    var layout: WorkoutLayout?
    var exercises: [ExerciseTemplate]?
    
    init(id: String = UUID().uuidString,
         name: String,
         type: String,
         layout: WorkoutLayout? = nil,
         exercises: [ExerciseTemplate]? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.layout = layout
        self.exercises = exercises
    }
}

struct ExerciseTemplate: Identifiable {
    let id: String
    var name: String
    var layout: WorkoutLayout
    var defaultSets: Int
    
    init(id: String = UUID().uuidString,
         name: String,
         layout: WorkoutLayout = .basic,
         defaultSets: Int = 3) {
        self.id = id
        self.name = name
        self.layout = layout
        self.defaultSets = defaultSets
    }
}

// CloudKit konverteringer
extension WorkoutSession {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "WorkoutSession")
        record["date"] = date as CKRecordValue
        record["type"] = type as CKRecordValue
        record["notes"] = notes as CKRecordValue?
        record["bodyWeight"] = bodyWeight as CKRecordValue?
        record["calories"] = calories as CKRecordValue?
        record["healthKitId"] = healthKitId as CKRecordValue?
        return record
    }
    
    static func fromRecord(_ record: CKRecord) -> WorkoutSession {
        return WorkoutSession(
            id: record.recordID.recordName,
            date: record["date"] as? Date ?? Date(),
            type: record["type"] as? String ?? "",
            notes: record["notes"] as? String,
            bodyWeight: record["bodyWeight"] as? String,
            calories: record["calories"] as? Int,
            healthKitId: record["healthKitId"] as? String
        )
    }
}

extension Exercise {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Exercise")
        record["name"] = name as CKRecordValue
        record["layout"] = layout.rawValue as CKRecordValue
        record["increaseNextTime"] = increaseNextTime as CKRecordValue
        return record
    }
    
    static func fromRecord(_ record: CKRecord) -> Exercise {
        return Exercise(
            id: record.recordID.recordName,
            name: record["name"] as? String ?? "",
            layout: WorkoutLayout(rawValue: record["layout"] as? String ?? "") ?? .basic,
            increaseNextTime: record["increaseNextTime"] as? Bool ?? false
        )
    }
}

extension SetData {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "SetData")
        record["weight"] = weight as CKRecordValue?
        record["reps"] = reps as CKRecordValue?
        record["duration"] = duration as CKRecordValue?
        record["distance"] = distance as CKRecordValue?
        record["incline"] = incline as CKRecordValue?
        record["restPeriod"] = restPeriod as CKRecordValue?
        record["order"] = order as CKRecordValue
        record["notes"] = notes as CKRecordValue?
        return record
    }
    
    static func fromRecord(_ record: CKRecord) -> SetData {
        return SetData(
            id: record.recordID.recordName,
            weight: record["weight"] as? String,
            reps: record["reps"] as? String,
            duration: record["duration"] as? String,
            distance: record["distance"] as? String,
            incline: record["incline"] as? String,
            restPeriod: record["restPeriod"] as? String,
            order: record["order"] as? Int ?? 0,
            notes: record["notes"] as? String
        )
    }
}

extension WorkoutTemplate {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "WorkoutTemplate")
        record["name"] = name as CKRecordValue
        record["type"] = type as CKRecordValue
        record["layout"] = layout?.rawValue as CKRecordValue?
        return record
    }
    
    static func fromRecord(_ record: CKRecord) -> WorkoutTemplate {
        return WorkoutTemplate(
            id: record.recordID.recordName,
            name: record["name"] as? String ?? "",
            type: record["type"] as? String ?? "",
            layout: record["layout"].flatMap { WorkoutLayout(rawValue: $0 as? String ?? "") }
        )
    }
}

extension ExerciseTemplate {
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "ExerciseTemplate")
        record["name"] = name as CKRecordValue
        record["layout"] = layout.rawValue as CKRecordValue
        record["defaultSets"] = defaultSets as CKRecordValue
        return record
    }
    
    static func fromRecord(_ record: CKRecord) -> ExerciseTemplate {
        return ExerciseTemplate(
            id: record.recordID.recordName,
            name: record["name"] as? String ?? "",
            layout: WorkoutLayout(rawValue: record["layout"] as? String ?? "") ?? .basic,
            defaultSets: record["defaultSets"] as? Int ?? 3
        )
    }
} 