// ContentView.swift

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var store: WorkoutStore
    @State private var selectedTab = 0

    @AppStorage("hasSeenHealthOnboarding") private var hasSeenHealthOnboarding = false
    @State private var showHealthOnboarding = false

    /// Timestamp for forrige import
    @AppStorage("lastHealthKitImport") private var lastHealthKitImport: TimeInterval = 0
    /// Sørger for at vi bare importerer én gang per app‐sesjon
    @State private var didImportInitial = false

    init(store: WorkoutStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeView(store: store)
                    .navigationBarHidden(true)
            }
            .tabItem { Label("Oversikt", systemImage: "house") }
            .tag(0)

            NavigationView {
                WorkoutListView(store: store)
                    .navigationTitle("Mine Økter")
            }
            .tabItem { Label("Liste", systemImage: "list.bullet") }
            .tag(1)

            NavigationView {
                CalendarWorkoutView(store: store)
                    .navigationTitle("Kalender")
            }
            .tabItem { Label("Kalender", systemImage: "calendar") }
            .tag(2)
        }
        .onAppear {
            let status = HKHealthStore().authorizationStatus(for: .workoutType())
            showHealthOnboarding = !hasSeenHealthOnboarding && status == .notDetermined

            // Hvis vi allerede har autorisasjon og har sett onboarding → importer
            if !showHealthOnboarding {
                Task { await importWorkouts() }
            }
        }
        .sheet(isPresented: $showHealthOnboarding, onDismiss: {
            hasSeenHealthOnboarding = true
            Task { await importWorkouts() }
        }) {
            HealthOnboardingView(isPresented: $showHealthOnboarding)
                .environmentObject(store)
        }
    }

    /// Henter nye HealthKit-økter siden sist import og legger til i `store`.
    private func importWorkouts() async {
        // Kun én import første gang
        guard !didImportInitial else { return }
        didImportInitial = true

        // Krever at brukeren har gitt HealthKit-tillatelse
        guard HKHealthStore().authorizationStatus(for: .workoutType()) == .sharingAuthorized
        else { return }

        do {
            // 1) Hent alle økter
            let hkWorkouts = try await HealthKitService.fetchWorkouts()

            // 2) Bestem hvilke som er nye
            let newHK: [HKWorkout]
            if lastHealthKitImport == 0 {
                newHK = hkWorkouts
            } else {
                let sinceDate = Date(timeIntervalSince1970: lastHealthKitImport)
                newHK = hkWorkouts.filter { $0.startDate > sinceDate }
            }
            guard !newHK.isEmpty else { return }

            // 3) Map til egne Workout-modeller parallelt
            let imported = try await withThrowingTaskGroup(of: Workout.self) { group in
                for hk in newHK {
                    group.addTask { try await HealthDataImporter.asyncMap(hk) }
                }
                var results = [Workout]()
                for try await w in group { results.append(w) }
                return results
            }

            // 4) Fjern økter vi allerede har (sjekk på id)
            let unique = imported.filter { new in
                !store.workouts.contains(where: { $0.id == new.id })
            }
            guard !unique.isEmpty else { return }

            // 5) Oppdater butikken og merk nytt import‐tidspunkt
            await MainActor.run {
                store.workouts.append(contentsOf: unique)
                lastHealthKitImport = Date().timeIntervalSince1970
            }
        } catch {
            print("HealthKit-import feilet:", error)
        }
    }
}
