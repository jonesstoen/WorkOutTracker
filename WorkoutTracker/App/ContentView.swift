// ContentView.swift

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var store: WorkoutStore
    private let importService: WorkoutImporting
    @State private var selectedTab = 0

    @AppStorage("hasSeenHealthOnboarding") private var hasSeenHealthOnboarding = false
    @State private var showHealthOnboarding = false

    init(store: WorkoutStore) {
        _store = StateObject(wrappedValue: store)
        // Bruk WorkoutStore som repo, men snakk via WorkoutImporting‑protokollen.
        self.importService = WorkoutImportService(repository: store)
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
                Task { await importService.importIfNeeded() }
            }
        }
        .sheet(isPresented: $showHealthOnboarding, onDismiss: {
            hasSeenHealthOnboarding = true
            Task { await importService.importIfNeeded() }
        }) {
            HealthOnboardingView(isPresented: $showHealthOnboarding)
                .environmentObject(store)
        }
    }
}
