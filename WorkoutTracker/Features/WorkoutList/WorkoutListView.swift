import SwiftUI

struct WorkoutListView: View {
    @ObservedObject private var store: WorkoutStore
    @StateObject   private var vm: WorkoutListViewModel
    @State         private var showAddWorkout = false

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
        self._vm    = StateObject(wrappedValue: WorkoutListViewModel(store: store))
    }

    var body: some View {
        List {
            ForEach(vm.sections, id: \.self) { week in
                Section(header: Text(week).font(.headline)) {
                    ForEach(vm.groupedWorkouts[week]!) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            workoutCard(for: workout)
                        }
                    }
                    .onDelete { vm.delete(at: $0, in: week) }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Mine økter")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddWorkout = true } label: {
                    Label("Ny økt", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView(store: store)
        }
    }

    @ViewBuilder
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
