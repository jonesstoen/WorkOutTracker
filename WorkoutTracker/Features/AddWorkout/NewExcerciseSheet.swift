import SwiftUI

struct NewExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exercises: [Exercise]
    /// Sets from the last time an exercise was done; used to pre-fill a newly added exercise
    var previousSets: (String) -> [WorkingSet]? = { _ in nil }

    @StateObject private var vm = ExercisesViewModel()
    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup? = nil
    @State private var showEditSheet = false
    @State private var pendingCustomName: String? = nil

    private let muscles = MuscleGroup.selectable
    private let predefined = ExerciseCatalog.predefined

    private var allNames: [String] {
        var seen = Set<String>()
        return (predefined.map { $0.name } + vm.exercises).filter {
            seen.insert($0.lowercased()).inserted
        }
    }

    private var showAddCustom: Bool {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        return !q.isEmpty && !allNames.contains {
            $0.localizedCaseInsensitiveCompare(q) == .orderedSame
        }
    }

    private var filteredPredefined: [CatalogExercise] {
        predefined.filter { entry in
            let matchesSearch = searchText.isEmpty || entry.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscle == nil || entry.muscle == selectedMuscle
            return matchesSearch && matchesMuscle
        }
    }

    private var customMuscles: [String: MuscleGroup] { ExerciseCatalog.customMuscles() }

    private var filteredCustom: [String] {
        vm.exercises.filter { name in
            let matchesSearch = searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscle == nil || customMuscles[name.exerciseKey] == selectedMuscle
            return matchesSearch && matchesMuscle
        }
    }

    var body: some View {
        NavigationStack {
            List {
                filterChipsSection

                if showAddCustom {
                    addCustomSection
                }

                if !filteredCustom.isEmpty {
                    Section("Mine øvelser") {
                        ForEach(filteredCustom, id: \.self) { name in
                            Button { add(name: name) } label: {
                                exerciseRow(name: name, muscle: customMuscles[name.exerciseKey]?.rawValue)
                            }
                        }
                    }
                }

                if !filteredPredefined.isEmpty {
                    Section(selectedMuscle?.rawValue ?? "Alle øvelser") {
                        ForEach(filteredPredefined, id: \.name) { entry in
                            Button { add(name: entry.name) } label: {
                                exerciseRow(name: entry.name, muscle: entry.muscle.rawValue)
                            }
                        }
                    }
                }

                if filteredPredefined.isEmpty && filteredCustom.isEmpty && !showAddCustom {
                    Section {
                        Text("Ingen treff")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Søk eller skriv ny øvelse"
            )
            .navigationTitle("Velg øvelse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showEditSheet = true } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditCustomExercisesView(vm: vm)
            }
            .confirmationDialog(
                "Hvilken muskelgruppe trener \(pendingCustomName ?? "øvelsen")?",
                isPresented: Binding(
                    get: { pendingCustomName != nil },
                    set: { if !$0 { pendingCustomName = nil } }
                ),
                titleVisibility: .visible
            ) {
                ForEach(muscles) { muscle in
                    Button(muscle.rawValue) { addCustom(muscle: muscle) }
                }
                Button("Hopp over") { addCustom(muscle: nil) }
            } message: {
                Text("Brukes til å vise volum per muskelgruppe.")
            }
        }
    }

    // MARK: - Sections

    private var filterChipsSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "Alle", value: nil)
                    ForEach(muscles) { muscle in
                        filterChip(label: muscle.rawValue, value: muscle)
                    }
                }
                .padding(.vertical, 2)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var addCustomSection: some View {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        return Section {
            Button { pendingCustomName = q } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Legg til egendefinert")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(q)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Row

    private func exerciseRow(name: String, muscle: String?) -> some View {
        HStack {
            Text(name).foregroundStyle(.primary)
            Spacer()
            if let muscle {
                Text(muscle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Filter chip

    private func filterChip(label: String, value: MuscleGroup?) -> some View {
        let isSelected = selectedMuscle == value
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                if let value {
                    selectedMuscle = selectedMuscle == value ? nil : value
                } else {
                    selectedMuscle = nil
                }
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add

    private func addCustom(muscle: MuscleGroup?) {
        guard let name = pendingCustomName else { return }
        if let muscle { ExerciseCatalog.setCustomMuscle(muscle, for: name) }
        pendingCustomName = nil
        add(name: name)
    }

    private func add(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !ExerciseCatalog.isBuiltIn(trimmed) { vm.add(trimmed) }
        let sets = previousSets(trimmed) ?? [WorkingSet(reps: 10, weight: 0, isCompleted: false)]
        exercises.append(Exercise(name: trimmed, sets: sets))
        dismiss()
    }
}
