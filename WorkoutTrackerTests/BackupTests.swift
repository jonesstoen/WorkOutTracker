import Foundation
import Testing
@testable import WorkoutTracker

struct BackupTests {

    private static let cal = Calendar(identifier: .gregorian)

    private static func date(_ day: Int, hour: Int = 18) -> Date {
        cal.date(from: DateComponents(timeZone: .current, year: 2026, month: 9, day: day, hour: hour, minute: 30))!
    }

    private func date(_ day: Int, hour: Int = 18) -> Date { Self.date(day, hour: hour) }

    private func defaults() -> UserDefaults {
        UserDefaults(suiteName: "BackupTests-\(UUID().uuidString)")!
    }

    // Stored once, so every use refers to the same workout (same id)
    private let bench = Workout(
        date: BackupTests.date(22),
        type: "Push",
        category: .strength,
        exercises: [Exercise(name: "Benkpress", sets: [
            WorkingSet(reps: 5, weight: 82.5),
            WorkingSet(reps: 5, weight: 82.5),
        ])],
        notes: "Tung; men \"bra\"\nny linje",
        duration: 3540
    )

    private let run = Workout(date: BackupTests.date(23, hour: 7), type: "Løpetur", category: .running, exercises: [], duration: 1800)

    // MARK: - JSON

    @Test
    func json_roundTripsWorkoutsAndCustomExercises() throws {
        let store = defaults()
        store.set(["Min press"], forKey: "customExercises")
        ExerciseCatalog.setCustomMuscle(.shoulders, for: "Min press", in: store)

        let backup = WorkoutBackupService.makeBackup(workouts: [bench, run], defaults: store, now: date(29))
        let parsed = try WorkoutBackupService.parse(WorkoutBackupService.jsonData(backup))

        #expect(parsed.workouts == [bench, run])
        #expect(parsed.customExercises == ["Min press"])
        #expect(parsed.customExerciseMuscles == ["min press": "Skuldre"])
    }

    @Test
    func parse_acceptsTheAppsOwnWorkoutsFile() throws {
        // workouts.json is a bare array with default date encoding
        let raw = try JSONEncoder().encode([bench])
        #expect(try WorkoutBackupService.parse(raw).workouts == [bench])
    }

    @Test
    func parse_rejectsOtherFiles() {
        #expect(throws: WorkoutBackupService.BackupError.self) {
            try WorkoutBackupService.parse(Data("ikke en backup".utf8))
        }
    }

    // MARK: - Import

    @Test
    func preview_countsNewAndExisting() throws {
        let backup = WorkoutBackupService.makeBackup(workouts: [bench, run], defaults: defaults(), now: .now)
        let preview = WorkoutBackupService.preview(of: backup, existing: [bench])

        #expect(preview.total == 2)
        #expect(preview.newCount == 1)
        #expect(preview.existingCount == 1)
    }

    @Test
    func addNew_keepsExistingAndSkipsDuplicates() {
        var edited = bench
        edited.notes = "Endret lokalt"
        let backup = WorkoutBackupService.makeBackup(workouts: [bench, run], defaults: defaults(), now: .now)

        let result = WorkoutBackupService.merged(existing: [edited], with: backup, mode: .addNew)

        #expect(result.count == 2)
        // The local version of a workout that exists in both wins
        #expect(result.first { $0.id == bench.id }?.notes == "Endret lokalt")
    }

    @Test
    func replaceAll_usesOnlyTheBackup() {
        let other = Workout(date: date(1), type: "Bein", category: .strength, exercises: [])
        let backup = WorkoutBackupService.makeBackup(workouts: [run], defaults: defaults(), now: .now)

        #expect(WorkoutBackupService.merged(existing: [other], with: backup, mode: .replaceAll) == [run])
    }

    @Test
    func restoreCustomExercises_mergesWithExistingOnes() {
        let source = defaults()
        source.set(["Min press"], forKey: "customExercises")
        ExerciseCatalog.setCustomMuscle(.shoulders, for: "Min press", in: source)
        let backup = WorkoutBackupService.makeBackup(workouts: [], defaults: source, now: .now)

        let target = defaults()
        target.set(["Egen curl"], forKey: "customExercises")
        WorkoutBackupService.restoreCustomExercises(from: backup, into: target)

        #expect(target.stringArray(forKey: "customExercises") == ["Egen curl", "Min press"])
        #expect(ExerciseCatalog.customMuscles(in: target)["min press"] == .shoulders)
    }

    // MARK: - CSV

    @Test
    func csv_hasOneRowPerSetWithNorwegianNumbers() throws {
        let csv = WorkoutBackupService.csv(for: [bench, run], timeZone: .current)
        let lines = csv.dropFirst().components(separatedBy: "\r\n").filter { !$0.isEmpty }

        #expect(csv.hasPrefix("\u{FEFF}"))  // BOM so Excel reads æøå correctly
        #expect(lines[0] == "Dato;Økt;Kategori;Øvelse;Sett;Vekt (kg);Reps;Fullført;Varighet (min);Notater")
        #expect(lines[1] == "2026-09-22 18:30;Push;Styrke;Benkpress;1;82,5;5;Ja;59;\"Tung; men \"\"bra\"\"\nny linje\"")
        #expect(lines[2].hasPrefix("2026-09-22 18:30;Push;Styrke;Benkpress;2;82,5;5;Ja;59;"))
        // A workout without exercises still gets a row
        #expect(lines.last == "2026-09-23 07:30;Løpetur;Løping;;;;;;30;")
    }

    @Test
    func fileNames_includeTheDate() {
        #expect(WorkoutBackupService.fileName(for: .json, on: date(29)) == "WorkoutTracker-2026-09-29.json")
        #expect(WorkoutBackupService.fileName(for: .csv, on: date(29)) == "WorkoutTracker-2026-09-29.csv")
    }
}
