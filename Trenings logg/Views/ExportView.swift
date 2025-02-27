import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @State private var workoutSessions: [WorkoutSession] = []
    @State private var isExporting = false
    @State private var exportData: Data?
    
    var body: some View {
        NavigationView {
            VStack {
                if !workoutSessions.isEmpty {
                    List {
                        ForEach(workoutSessions) { session in
                            VStack(alignment: .leading) {
                                Text(session.type)
                                    .font(.headline)
                                Text(session.date.formatted())
                                    .font(.subheadline)
                            }
                        }
                    }
                } else {
                    Text("Ingen treningsøkter å eksportere")
                        .foregroundColor(.secondary)
                }
                
                Button(action: exportWorkouts) {
                    Text("Eksporter treningsøkter")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Eksporter treningsøkter")
            .task {
                await loadWorkouts()
            }
            .fileExporter(
                isPresented: $isExporting,
                document: WorkoutExportDocument(data: exportData ?? Data()),
                contentType: .json,
                defaultFilename: "treningsokter.json"
            ) { result in
                switch result {
                case .success(let url):
                    print("Eksportert til: \(url)")
                case .failure(let error):
                    print("Eksportfeil: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadWorkouts() async {
        do {
            workoutSessions = try await cloudKitManager.fetchAllWorkoutSessions()
        } catch {
            print("Feil ved lasting av treningsøkter: \(error)")
        }
    }
    
    private func exportWorkouts() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(workoutSessions)
            self.exportData = data
            self.isExporting = true
        } catch {
            print("Eksportfeil: \(error)")
        }
    }
}

struct WorkoutExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
} 