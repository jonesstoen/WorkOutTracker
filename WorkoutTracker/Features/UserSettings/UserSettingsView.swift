import SwiftUI
import UniformTypeIdentifiers

struct UserSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: WorkoutStore

    @AppStorage("userName")    private var userName: String = ""
    @AppStorage("weeklyGoal") private var weeklyGoal: Int  = 3

    @State private var showImporter = false
    @State private var pendingImport: PendingImport?
    @State private var resultMessage: String?
    @State private var importError: String?

    private struct PendingImport {
        let backup: WorkoutBackup
        let preview: ImportPreview
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profil") {
                    TextField("Navn", text: $userName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }

                Section {
                    Stepper(
                        weeklyGoal == 1 ? "1 økt per uke" : "\(weeklyGoal) økter per uke",
                        value: $weeklyGoal,
                        in: 1...7
                    )
                } header: {
                    Text("Ukentlig mål")
                } footer: {
                    Text("Brukes til å vise fremgang på oversikten.")
                }

                dataSection
            }
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ferdig") { dismiss() }
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                handlePickedFile(result)
            }
            .confirmationDialog(
                importTitle,
                isPresented: Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } }),
                titleVisibility: .visible
            ) {
                if let pending = pendingImport {
                    if pending.preview.newCount > 0 {
                        Button("Legg til \(pending.preview.newCount) nye") { runImport(pending, mode: .addNew) }
                    }
                    Button("Erstatt alle økter", role: .destructive) { runImport(pending, mode: .replaceAll) }
                }
                Button("Avbryt", role: .cancel) { }
            } message: {
                Text("«Erstatt alle» sletter de \(store.workouts.count) øktene som ligger i appen nå.")
            }
            .alert("Import fullført", isPresented: Binding(get: { resultMessage != nil }, set: { if !$0 { resultMessage = nil } })) {
                Button("OK") { }
            } message: {
                Text(resultMessage ?? "")
            }
            .alert("Kunne ikke importere", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
                Button("OK") { }
            } message: {
                Text(importError ?? "")
            }
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            ShareLink(
                item: BackupFile(workouts: store.workouts, format: .json),
                preview: SharePreview("Sikkerhetskopi av treningsøkter", image: Image(systemName: "externaldrive"))
            ) {
                Label("Eksporter sikkerhetskopi (JSON)", systemImage: "square.and.arrow.up")
            }

            ShareLink(
                item: BackupFile(workouts: store.workouts, format: .csv),
                preview: SharePreview("Treningsøkter som regneark", image: Image(systemName: "tablecells"))
            ) {
                Label("Eksporter til regneark (CSV)", systemImage: "tablecells")
            }

            Button {
                showImporter = true
            } label: {
                Label("Importer sikkerhetskopi", systemImage: "square.and.arrow.down")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("\(store.workouts.count) økter lagret på denne telefonen. Lagre sikkerhetskopien i Filer eller iCloud Drive, så kan du hente historikken tilbake hvis appen slettes.")
        }
    }

    private var importTitle: String {
        guard let preview = pendingImport?.preview else { return "" }
        let existing = preview.existingCount > 0 ? ", \(preview.existingCount) finnes allerede" : ""
        return "Filen inneholder \(preview.total) økter\(existing)"
    }

    // MARK: - Import

    private func handlePickedFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

            let backup = try WorkoutBackupService.parse(Data(contentsOf: url))
            pendingImport = PendingImport(
                backup: backup,
                preview: WorkoutBackupService.preview(of: backup, existing: store.workouts)
            )
        } catch {
            importError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func runImport(_ pending: PendingImport, mode: WorkoutBackupService.ImportMode) {
        let before = store.workouts.count
        store.replaceAll(with: WorkoutBackupService.merged(existing: store.workouts, with: pending.backup, mode: mode))
        WorkoutBackupService.restoreCustomExercises(from: pending.backup)

        switch mode {
        case .addNew:
            resultMessage = "La til \(store.workouts.count - before) økter. Du har nå \(store.workouts.count)."
        case .replaceAll:
            resultMessage = "Historikken er erstattet med \(store.workouts.count) økter fra filen."
        }
    }
}

/// A backup or CSV file written to a temporary location when the share sheet asks for it.
private struct BackupFile: Transferable {
    let workouts: [Workout]
    let format: WorkoutBackupService.Format

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { file in
            try SentTransferredFile(file.write())
        }
        .exportingCondition { $0.format == .json }

        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            try SentTransferredFile(file.write())
        }
        .exportingCondition { $0.format == .csv }
    }

    private func write() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(WorkoutBackupService.fileName(for: format))
        let data: Data
        switch format {
        case .json:
            data = try WorkoutBackupService.jsonData(WorkoutBackupService.makeBackup(workouts: workouts))
        case .csv:
            data = Data(WorkoutBackupService.csv(for: workouts).utf8)
        }
        try data.write(to: url, options: .atomic)
        return url
    }
}
