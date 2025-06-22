import SwiftUI

struct WorkoutListView: View {
    @Binding var workouts: [Workout]
    @State private var showAddWorkout = false

    var body: some View {
        List {
            ForEach(workouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    workoutCard(for: workout)
                }
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteWorkout)
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
        .animation(.default, value: workouts)
    }

    private func deleteWorkout(at offsets: IndexSet) {
        workouts.remove(atOffsets: offsets)
    }

    private func workoutCard(for workout: Workout) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForType(workout.type))
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type.capitalized)
                    .font(.headline)
                Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if !workout.exercises.isEmpty {
                    Text("\(workout.exercises.count) øvelse\(workout.exercises.count == 1 ? "" : "r")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "push": return "arrow.up.circle.fill"
        case "pull": return "arrow.down.circle.fill"
        case "bein", "legs": return "figure.walk"
        case "bryst": return "heart.fill"
        case "rygg": return "square.stack.3d.up.fill"
        case "skuldre": return "bolt.fill"
        case "arm": return "hand.raised.fill"
        default: return "dumbbell"
        }
    }
}
