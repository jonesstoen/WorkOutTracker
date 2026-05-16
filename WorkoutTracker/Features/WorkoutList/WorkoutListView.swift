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
        Group {
            if vm.workouts.isEmpty {
                ContentUnavailableView(
                    "Ingen økter enda",
                    systemImage: "dumbbell",
                    description: Text("Trykk + for å legge til din første økt.")
                )
                .navigationTitle("Historikk")
            } else {
                listContent
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !vm.workouts.isEmpty { EditButton() }
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

    // MARK: - List

    private var listContent: some View {
        List {
            ForEach(vm.sections, id: \.title) { section in
                Section(header: Text(section.title)) {
                    ForEach(section.workouts) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            workoutCard(for: workout)
                        }
                    }
                    .onDelete { vm.delete(at: $0, in: section.title) }
                }
            }

            if vm.sections.isEmpty {
                ContentUnavailableView(
                    "Ingen treff",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Ingen økter i denne kategorien.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Historikk")
        .safeAreaInset(edge: .top, spacing: 0) {
            filterBar
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "Alle", category: nil)
                ForEach(WorkoutCategory.allCases) { cat in
                    filterChip(label: cat.rawValue, category: cat)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func filterChip(label: String, category: WorkoutCategory?) -> some View {
        let isSelected = vm.selectedCategory == category
        let activeColor: Color = category?.color ?? .accentColor
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                if let category {
                    vm.selectedCategory = vm.selectedCategory == category ? nil : category
                } else {
                    vm.selectedCategory = nil
                }
            }
        } label: {
            HStack(spacing: 5) {
                if let category {
                    Image(systemName: category.iconName)
                        .font(.caption)
                }
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? activeColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : (category.map { $0.color } ?? .primary))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Workout card

    @ViewBuilder
    private func workoutCard(for workout: Workout) -> some View {
        let title = workout.type.trimmingCharacters(in: .whitespacesAndNewlines)
        let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
        let totalVolume = workout.exercises.reduce(0.0) { $0 + $1.totalVolume }

        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(workout.category.color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: workout.category.iconName)
                    .font(.body)
                    .foregroundColor(workout.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title.isEmpty ? workout.category.rawValue : title.capitalized)
                    .font(.headline)
                Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                statsLine(for: workout, sets: totalSets, volume: totalVolume)

                if !workout.exercises.isEmpty {
                    let names = workout.exercises.prefix(3).map(\.name)
                    let extra = workout.exercises.count - names.count
                    let label = names.joined(separator: " · ") + (extra > 0 ? " +\(extra)" : "")
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func statsLine(for workout: Workout, sets: Int, volume: Double) -> some View {
        if workout.exercises.isEmpty {
            Text("Ingen øvelser")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            Text(statsText(for: workout, sets: sets, volume: volume))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func statsText(for workout: Workout, sets: Int, volume: Double) -> String {
        var parts: [String] = []
        if workout.duration > 0 { parts.append(durationString(workout.duration)) }
        parts.append("\(workout.exercises.count) øv · \(sets) sett")
        if volume > 0 { parts.append("\(Int(volume)) kg") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Helpers

    private func durationString(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600, m = (s % 3600) / 60
        return h > 0 ? "\(h)t \(m)m" : "\(m) min"
    }
}
