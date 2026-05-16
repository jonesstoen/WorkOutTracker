import SwiftUI

private struct ExerciseEntry {
    let name: String
    let muscle: String
}

struct NewExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exercises: [Exercise]

    @StateObject private var vm = ExercisesViewModel()
    @State private var searchText = ""
    @State private var selectedMuscle: String? = nil
    @State private var showEditSheet = false

    private let muscles = ["Bryst", "Rygg", "Ben", "Skuldre", "Armer", "Kjerne"]

    private let predefined: [ExerciseEntry] = [
        // Bryst
        ExerciseEntry(name: "Benkpress",              muscle: "Bryst"),
        ExerciseEntry(name: "Benkpress manualer",     muscle: "Bryst"),
        ExerciseEntry(name: "Incline benkpress",      muscle: "Bryst"),
        ExerciseEntry(name: "Flyes",                  muscle: "Bryst"),
        ExerciseEntry(name: "Dips",                   muscle: "Bryst"),
        // Rygg
        ExerciseEntry(name: "Nedtrekk",               muscle: "Rygg"),
        ExerciseEntry(name: "Pull-ups",               muscle: "Rygg"),
        ExerciseEntry(name: "Roing",                  muscle: "Rygg"),
        ExerciseEntry(name: "Sittende roing",         muscle: "Rygg"),
        ExerciseEntry(name: "Kabelroing",             muscle: "Rygg"),
        ExerciseEntry(name: "Markløft",               muscle: "Rygg"),
        // Ben
        ExerciseEntry(name: "Squat",                  muscle: "Ben"),
        ExerciseEntry(name: "Leg press",              muscle: "Ben"),
        ExerciseEntry(name: "Utfall",                 muscle: "Ben"),
        ExerciseEntry(name: "Strak markløft",         muscle: "Ben"),
        ExerciseEntry(name: "Hip thrust",             muscle: "Ben"),
        ExerciseEntry(name: "Leg curl",               muscle: "Ben"),
        ExerciseEntry(name: "Leg extension",          muscle: "Ben"),
        // Skuldre
        ExerciseEntry(name: "Skulderpress",           muscle: "Skuldre"),
        ExerciseEntry(name: "Stående press",          muscle: "Skuldre"),
        ExerciseEntry(name: "Lateral raises",         muscle: "Skuldre"),
        ExerciseEntry(name: "Facepull",               muscle: "Skuldre"),
        // Armer
        ExerciseEntry(name: "Bicep curl",             muscle: "Armer"),
        ExerciseEntry(name: "Hammer curl",            muscle: "Armer"),
        ExerciseEntry(name: "Triceps pushdown",       muscle: "Armer"),
        ExerciseEntry(name: "Skull crushers",         muscle: "Armer"),
        // Kjerne
        ExerciseEntry(name: "Planke",                 muscle: "Kjerne"),
        ExerciseEntry(name: "Cable crunch",           muscle: "Kjerne"),
        ExerciseEntry(name: "Russian twist",          muscle: "Kjerne"),
        ExerciseEntry(name: "Hanging leg raise",      muscle: "Kjerne"),
    ]

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

    private var filteredPredefined: [ExerciseEntry] {
        predefined.filter { entry in
            let matchesSearch = searchText.isEmpty || entry.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscle == nil || entry.muscle == selectedMuscle
            return matchesSearch && matchesMuscle
        }
    }

    private var filteredCustom: [String] {
        guard selectedMuscle == nil else { return [] }
        return vm.exercises.filter {
            searchText.isEmpty || $0.localizedCaseInsensitiveContains(searchText)
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
                                exerciseRow(name: name, muscle: nil)
                            }
                        }
                    }
                }

                if !filteredPredefined.isEmpty {
                    Section(selectedMuscle ?? "Alle øvelser") {
                        ForEach(filteredPredefined, id: \.name) { entry in
                            Button { add(name: entry.name) } label: {
                                exerciseRow(name: entry.name, muscle: entry.muscle)
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
        }
    }

    // MARK: - Sections

    private var filterChipsSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "Alle", value: nil)
                    ForEach(muscles, id: \.self) { muscle in
                        filterChip(label: muscle, value: muscle)
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
            Button { add(name: q) } label: {
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

    private func filterChip(label: String, value: String?) -> some View {
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

    private func add(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let isBuiltIn = predefined.contains {
            $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }
        if !isBuiltIn { vm.add(trimmed) }
        exercises.append(Exercise(name: trimmed, sets: [WorkingSet(reps: 10, weight: 0)]))
        dismiss()
    }
}
