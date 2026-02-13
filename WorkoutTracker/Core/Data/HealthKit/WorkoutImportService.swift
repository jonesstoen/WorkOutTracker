import Foundation
import HealthKit

/// Ansvarlig for å hente inn økter fra HealthKit og legge dem til i `WorkoutRepository`.
///
/// Denne typen samler all import‑logikk ett sted slik at `ContentView` bare
/// trenger å trigge en høy‑nivå handling (`importIfNeeded()`), uten å vite
/// hvordan HealthKit fungerer eller hvordan øktene lagres.
///
/// For enkel testing er HealthKit‑tilgang også abstrahert bak `HealthKitWorkoutFetching`.
protocol HealthKitWorkoutFetching {
    func fetchWorkouts(limit: Int) async throws -> [HKWorkout]
}

/// Standard‑implementasjon som bare delegerer videre til `HealthKitService`.
struct DefaultHealthKitWorkoutFetcher: HealthKitWorkoutFetching {
    func fetchWorkouts(limit: Int = 100) async throws -> [HKWorkout] {
        try await HealthKitService.fetchWorkouts(limit: limit)
    }
}
protocol WorkoutImporting {
    /// Importerer nye HealthKit‑økter hvis det er nødvendig.
    ///
    /// Kaller ikke HealthKit eller repo unødvendig:
    /// - kjører maks én gang per app‑sesjon
    /// - filtrerer på sist importerte tidspunkt
    func importIfNeeded() async
}

final class WorkoutImportService: WorkoutImporting {
    private let repository: WorkoutRepository
    private let workoutFetcher: HealthKitWorkoutFetching

    /// Nøkkel brukt til å lagre tidspunkt for sist vellykkede import.
    private let lastImportKey = "lastHealthKitImport"

    /// Sørger for at vi bare forsøker én gang per app‑sesjon.
    private var didImportInitial = false

    init(
        repository: WorkoutRepository,
        workoutFetcher: HealthKitWorkoutFetching = DefaultHealthKitWorkoutFetcher()
    ) {
        self.repository = repository
        self.workoutFetcher = workoutFetcher
    }

    func importIfNeeded() async {
        // Kun én import‑runde per app‑sesjon
        guard !didImportInitial else { return }
        didImportInitial = true

        // Krever at brukeren har gitt HealthKit‑tillatelse
        guard HKHealthStore().authorizationStatus(for: .workoutType()) == .sharingAuthorized
        else { return }

        do {
            // 1) Hent alle økter
            let hkWorkouts = try await workoutFetcher.fetchWorkouts(limit: 100)

            // 2) Bestem hvilke som er nye basert på sist importerte tidspunkt
            let lastImport = UserDefaults.standard.double(forKey: lastImportKey)
            let newHK: [HKWorkout]
            if lastImport == 0 {
                newHK = hkWorkouts
            } else {
                let sinceDate = Date(timeIntervalSince1970: lastImport)
                newHK = hkWorkouts.filter { $0.startDate > sinceDate }
            }
            guard !newHK.isEmpty else { return }

            // 3) Map til egne Workout‑modeller parallelt
            let imported = try await withThrowingTaskGroup(of: Workout.self) { group in
                for hk in newHK {
                    group.addTask { try await HealthDataImporter.asyncMap(hk) }
                }
                var results = [Workout]()
                for try await w in group { results.append(w) }
                return results
            }

            // 4) Filtrer ut økter vi allerede har (sjekk på id)
            let existing = repository.workouts
            let unique = imported.filter { new in
                !existing.contains(where: { $0.id == new.id })
            }
            guard !unique.isEmpty else { return }

            // 5) Oppdater repo og merk nytt import‑tidspunkt
            await MainActor.run {
                repository.add(contentsOf: unique)
                UserDefaults.standard.set(
                    Date().timeIntervalSince1970,
                    forKey: lastImportKey
                )
            }
        } catch {
            // TODO: Erstatt med bedre logging / bruker‑feedback
            print("HealthKit-import feilet:", error)
        }
    }
}

