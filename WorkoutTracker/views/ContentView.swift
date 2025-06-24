import SwiftUI

struct ContentView: View {
    @StateObject private var store = WorkoutStore()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // ————————————— Oversikt —————————————
            NavigationView {
                HomeView(store: store)
                    .navigationBarHidden(true)
            }
            .tabItem {
                Label("Oversikt", systemImage: "house")
            }
            .tag(0)

            // ————————————— Liste —————————————
            NavigationView {
                WorkoutListView(store: store)
                    .navigationTitle("Mine Økter")
            }
            .tabItem {
                Label("Liste", systemImage: "list.bullet")
            }
            .tag(1)

            // ————————————— Kalender —————————————
            NavigationView {
                CalendarWorkoutView(workouts: $store.workouts)
                    .navigationTitle("Kalender")
            }
            .tabItem {
                Label("Kalender", systemImage: "calendar")
            }
            .tag(2)
        }
    }
}
