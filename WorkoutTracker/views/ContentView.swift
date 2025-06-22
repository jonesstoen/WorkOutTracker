import SwiftUI

struct ContentView: View {
    @StateObject private var store = WorkoutStore()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                WorkoutListView(workouts: $store.workouts)
                    .navigationTitle("Mine Økter")
            }
            .tabItem {
                Label("Liste", systemImage: "list.bullet")
            }
            .tag(0)

            NavigationView {
                CalendarWorkoutView(workouts: $store.workouts)
                    .navigationTitle("Kalender")
            }
            .tabItem {
                Label("Kalender", systemImage: "calendar")
            }
            .tag(1)
        }
    }
}
