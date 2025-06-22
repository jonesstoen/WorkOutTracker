import SwiftUI

struct ContentView: View {
    @StateObject private var store = WorkoutStore()

    var body: some View {
        NavigationView {
            WorkoutListView(workouts: $store.workouts)
                .navigationTitle("Mine Økter")
        }
    }
}