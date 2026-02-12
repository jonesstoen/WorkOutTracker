import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: AddWorkoutViewModel

    @State private var showNotesSection = false
    @FocusState private var focusedField: Field?

    private enum Field { case title, notes }

    init(store: WorkoutStore) {
        _vm = StateObject(wrappedValue: AddWorkoutViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Date & time
                Section("Dato & klokkeslett") {
                    DatePicker(
                        "Dato og tid",
                        selection: $vm.date,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                // MARK: Type & category
                Section("Type og kategori") {
                    TextField("F.eks. Push / Bein / Øktnavn", text: $vm.type)
                        .focused($focusedField, equals: .title)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)

                    Picker("Kategori", selection: $vm.category) {
                        ForEach(WorkoutCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                // MARK: Exercises
                Section {
                    if vm.exercises.isEmpty {
                        ContentUnavailableView(
                            "Ingen øvelser enda",
                            systemImage: "list.bullet.rectangle",
                            description: Text("Trykk under for å legge til øvelser.")
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(vm.exercises) { ex in
                            Button {
                                openEdit(ex)
                            } label: {
                                exerciseRow(ex)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteExercises)
                    }

                    Button {
                        vm.showExerciseSheet = true
                    } label: {
                        Label("Legg til øvelse", systemImage: "plus")
                    }
                } header: {
                    HStack {
                        Text("Øvelser")
                        Spacer()
                        Text("\(vm.exercises.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: Notes
                Section {
                    DisclosureGroup(isExpanded: $showNotesSection) {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $vm.notes)
                                .focused($focusedField, equals: .notes)
                                .frame(minHeight: 120)

                            if vm.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("Skriv notater…")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                    } label: {
                        Label("Notater", systemImage: "note.text")
                    }
                }
            }
            .navigationTitle("Ny økt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Ferdig") { focusedField = nil }
                }
            }
            .sheet(isPresented: $vm.showExerciseSheet) {
                NewExerciseSheet(exercises: $vm.exercises)
            }
            .sheet(item: $vm.editingExerciseIndex) { idx in
                EditExerciseSheet(exercise: $vm.exercises[idx.value])
            }
        }
    }

    // MARK: Rows / actions

    @ViewBuilder
    private func exerciseRow(_ ex: Exercise) -> some View {
        let weight = String(format: "%.1f", ex.weight)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(ex.name)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }

            Text("Sett: \(ex.sets) · Reps: \(ex.reps) · \(weight) kg")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private func openEdit(_ ex: Exercise) {
        if let idx = vm.exercises.firstIndex(of: ex) {
            vm.editingExerciseIndex = IdentifiableInt(value: idx)
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        vm.exercises.remove(atOffsets: offsets)
    }

    // MARK: Toolbar
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Avbryt") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Lagre") {
                    vm.save()
                    dismiss()
                }
                .disabled(vm.isSaveDisabled)
            }
        }
    }
}
