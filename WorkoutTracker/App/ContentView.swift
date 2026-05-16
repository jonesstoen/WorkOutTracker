// ContentView.swift

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var store: WorkoutStore
    private let importService: WorkoutImporting
    @StateObject private var liveSession = LiveSessionCoordinator.shared
    @StateObject private var homeNav = HomeNavigationCoordinator.shared
    @State private var selectedTab = 0

    @AppStorage("hasSeenHealthOnboarding") private var hasSeenHealthOnboarding = false
    @State private var showHealthOnboarding = false

    init(store: WorkoutStore) {
        _store = StateObject(wrappedValue: store)
        // Bruk WorkoutStore som repo, men snakk via WorkoutImporting‑protokollen.
        self.importService = WorkoutImportService(repository: store)
    }

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                HomeView(store: store)
                    .environmentObject(homeNav)
                    .tabItem { Label("Oversikt", systemImage: "house") }
                    .tag(0)

                NavigationView {
                    WorkoutListView(store: store)
                        .navigationTitle("Historikk")
                }
                .tabItem { Label("Historikk", systemImage: "clock.arrow.circlepath") }
                .tag(1)

                NavigationView {
                    CalendarWorkoutView(store: store)
                        .navigationTitle("Kalender")
                }
                .tabItem { Label("Kalender", systemImage: "calendar") }
                .tag(2)

                NavigationView {
                    PRListView(store: store)
                }
                .tabItem { Label("Rekorder", systemImage: "trophy") }
                .tag(3)
            }
            LiveWorkoutBanner(session: liveSession)
                .padding(.top, 4)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: liveSession.isActive)
        }
        .onAppear {
            let status = HKHealthStore().authorizationStatus(for: .workoutType())
            showHealthOnboarding = !hasSeenHealthOnboarding && status == .notDetermined

            if !showHealthOnboarding {
                Task { await importService.importIfNeeded() }
            }

            // Restore live session banner if the app was killed mid-workout
            if LiveWorkoutViewModel.hasSnapshot(), let snap = LiveWorkoutViewModel.loadSnapshot() {
                liveSession.isActive = true
                liveSession.type = snap.draft.type
                liveSession.category = snap.draft.category
                let backgrounded = snap.wasRunning ? 0.0 : Date().timeIntervalSince(snap.savedAt)
                liveSession.elapsed = Date().timeIntervalSince(snap.draft.startDate)
                    - snap.totalPaused - backgrounded
            }

            liveSession.onResumeTapped = {
                selectedTab = 0
                homeNav.resumeLiveRequested = true
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

