import SwiftUI

struct WorkoutListView: View {
    @Binding var workouts: [Workout]
    @State private var showAddWorkout = false

    var body: some View {
        List {
            ForEach(workouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    Text("\(workout.type) – \(workout.date.formatted(date: .abbreviated, time: .omitted))")
                }
            }
            .onDelete(perform: deleteWorkout)
        }
        .toolbar {
            EditButton()
            Button(action: { showAddWorkout = true }) {
                Label("Ny økt", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView(workouts: $workouts)
        }
    }

    private func deleteWorkout(at offsets: IndexSet) {
        workouts.remove(atOffsets: offsets)
    }
}