import SwiftUI

struct WorkoutListView: View {
    @Binding var workouts: [Workout]
    @State private var showAddWorkout = false

    var groupedWorkouts: [String: [Workout]] {
        Dictionary(grouping: workouts) { workout in
            let weekOfYear = Calendar.current.component(.weekOfYear, from: workout.date)
            let year = Calendar.current.component(.yearForWeekOfYear, from: workout.date)
            return "Uke \(weekOfYear), \(year)"
        }
    }

    var body: some View {
        List {
            ForEach(groupedWorkouts.keys.sorted(by: >), id: \.self) { weekKey in
                Section(header: Text(weekKey).font(.headline)) {
                    ForEach(groupedWorkouts[weekKey]!) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            workoutCard(for: workout)
                        }
                    }
                    .onDelete { indexSet in
                        deleteWorkout(at: indexSet, in: weekKey)
                    }
                }
            }
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddWorkout = true }) {
                    Label("Ny økt", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView(workouts: $workouts)
        }
    }

    private func deleteWorkout(at offsets: IndexSet, in weekKey: String) {
        guard let workoutsInSection = groupedWorkouts[weekKey] else { return }
        let itemsToDelete = offsets.map { workoutsInSection[$0] }
        workouts.removeAll { itemsToDelete.contains($0) }
    }

    private func workoutCard(for workout: Workout) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: workout.category.iconName)
                .font(.title2)
                .foregroundColor(workout.category.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type.capitalized)
                    .font(.headline)
                Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if workout.exercises.isEmpty {
                    Text("(Ingen øvelser)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(workout.exercises.count) øvelse\(workout.exercises.count == 1 ? "" : "r")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
