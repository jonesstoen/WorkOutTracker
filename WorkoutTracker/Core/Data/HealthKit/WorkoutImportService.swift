import Foundation
import HealthKit
import OSLog

/// Ansvarlig for å hente inn økter fra HealthKit og legge dem til i `WorkoutRepository`.
///
/// Denne typen samler all import‑logikk ett sted slik at `ContentView` bare
/// trenger å trigge en høy‑nivå handling (`importIfNeeded()`), uten å vite
/// hvordan HealthKit fungerer eller hvordan øktene lagres.
///
/// For enkel testing er HealthKit‑tilgang også abstrahert bak `HealthKitWorkoutFetching`.
protocol HealthKitWorkoutFetching {
    func fetchNewWorkouts(since anchor: HKQueryAnchor?) async throws -> (workouts: [HKWorkout], anchor: HKQueryAnchor?)
}

/// Standard‑implementasjon som bare delegerer videre til `HealthKitService`.
struct DefaultHealthKitWorkoutFetcher: HealthKitWorkoutFetching {
    func fetchNewWorkouts(since anchor: HKQueryAnchor?) async throws -> (workouts: [HKWorkout], anchor: HKQueryAnchor?) {
        try await HealthKitService.fetchNewWorkouts(since: anchor)
    }
}

protocol WorkoutImporting {
    /// Importerer nye HealthKit‑økter hvis det er nødvendig.
    ///
    /// Kaller ikke HealthKit eller repo unødvendig:
    /// - kjører maks én gang per app‑sesjon
    /// - henter bare økter lagt til i HealthKit siden forrige import (anker)
    func importIfNeeded() async
}

final class WorkoutImportService: WorkoutImporting {
    private let repository: WorkoutRepository
    private let workoutFetcher: HealthKitWorkoutFetching
    private let defaults: UserDefaults
    private let isAuthorized: () -> Bool

    /// HealthKit-ankeret fra forrige import; neste import fortsetter derfra.
    private let anchorKey = "healthKitWorkoutAnchor"
    /// Tidspunkt for siste import fra før ankeret ble tatt i bruk. Brukes bare første gang.
    private let legacyLastImportKey = "lastHealthKitImport"

    /// Sørger for at vi bare forsøker én gang per app‑sesjon.
    private var didImportInitial = false

    init(
        repository: WorkoutRepository,
        workoutFetcher: HealthKitWorkoutFetching = DefaultHealthKitWorkoutFetcher(),
        defaults: UserDefaults = .standard,
        isAuthorized: @escaping () -> Bool = {
            HKHealthStore().authorizationStatus(for: .workoutType()) == .sharingAuthorized
        }
    ) {
        self.repository = repository
        self.workoutFetcher = workoutFetcher
        self.defaults = defaults
        self.isAuthorized = isAuthorized
    }

    func importIfNeeded() async {
        // Kun én import‑runde per app‑sesjon
        guard !didImportInitial else { return }
        didImportInitial = true

        // Krever at brukeren har gitt HealthKit‑tillatelse
        guard isAuthorized() else { return }

        do {
            // 1) Hent økter lagt til i HealthKit siden forrige anker
            let previousAnchor = loadAnchor()
            let (fetched, newAnchor) = try await workoutFetcher.fetchNewWorkouts(since: previousAnchor)

            // 2) Første gang med anker: hopp over økter den gamle, datobaserte importen allerede håndterte,
            //    slik at økter brukeren har slettet i appen ikke kommer tilbake
            var candidates = fetched
            let legacyLastImport = defaults.double(forKey: legacyLastImportKey)
            if previousAnchor == nil, legacyLastImport > 0 {
                let since = Date(timeIntervalSince1970: legacyLastImport)
                candidates = fetched.filter { $0.startDate > since }
            }

            // 3) Map til egne Workout‑modeller parallelt
            let imported = try await withThrowingTaskGroup(of: Workout.self) { group in
                for hk in candidates {
                    group.addTask { try await HealthDataImporter.asyncMap(hk) }
                }
                var results = [Workout]()
                for try await w in group { results.append(w) }
                return results
            }

            // 4) Filtrer ut økter vi allerede har (HealthKit-id er økt-id)
            let existing = Set(repository.workouts.map(\.id))
            let unique = imported.filter { !existing.contains($0.id) }

            // 5) Oppdater repo og lagre ankeret først når alt har gått bra
            await MainActor.run {
                if !unique.isEmpty { repository.add(contentsOf: unique) }
                saveAnchor(newAnchor)
            }
        } catch {
            Logger.healthKit.error("HealthKit-import feilet: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadAnchor() -> HKQueryAnchor? {
        guard let data = defaults.data(forKey: anchorKey) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
    }

    private func saveAnchor(_ anchor: HKQueryAnchor?) {
        guard let anchor,
              let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
        else { return }
        defaults.set(data, forKey: anchorKey)
    }
}
