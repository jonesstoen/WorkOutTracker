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
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ———————— Dato & tid ————————
                    dateTimeCard

                    // ——————— Type & kategori ———————
                    typeCategoryCard

                    // ——————— Øvelser ———————
                    exercisesCard

                    // ——————— Notater ———————
                    if showNotesSection {
                        notesCard
                    } else {
                        Card {
                            Button {
                                withAnimation { showNotesSection = true }
                            } label: {
                                HStack {
                                    Image(systemName: "note.text")
                                    Text("Legg til notater")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 60)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.vertical)
            }
            .navigationTitle("Ny økt")
            .toolbar { toolbarItems }
            .sheet(isPresented: $vm.showExerciseSheet) {
                NewExerciseSheet(exercises: $vm.exercises)
            }
            .sheet(item: $vm.editingExerciseIndex) { idx in
                EditExerciseSheet(exercise: $vm.exercises[idx.value])
            }
        }
    }

    // MARK: – SUBVIEWS
    private var dateTimeCard: some View {
      Card {
        VStack(alignment: .leading, spacing: 12) {
          Text("Dato & klokkeslett")
            .font(.headline)
            .foregroundColor(.primary.opacity(0.9))

          DatePicker("", selection: $vm.date, in: ...Date(),
                     displayedComponents: [.date, .hourAndMinute])
            .datePickerStyle(.compact)
            .labelsHidden()
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
      }
    }

    private var typeCategoryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Type og kategori")
                    .font(.headline)
                    .foregroundColor(.primary.opacity(0.9))

                TextField("F.eks. Push / Bein / Øktnavn", text: $vm.type)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedField == .title ? Color.accentColor : Color(.separator), lineWidth: 1)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    )
                    .focused($focusedField, equals: .title)

                Picker("Kategori", selection: $vm.category) {
                    ForEach(WorkoutCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.iconName).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
    }

    private var exercisesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Øvelser (\(vm.exercises.count))")
                        .font(.headline)
                        .foregroundColor(.primary.opacity(0.9))
                    Spacer()
                    Button {
                        withAnimation { vm.showExerciseSheet = true }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Legg til øvelse")
                }

                if vm.exercises.isEmpty {
                    Text("Ingen øvelser enda")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                } else {
                    ForEach(vm.exercises) { ex in
                        exerciseRow(ex)
                    }
                }
            }
        }
    }

    private func exerciseRow(_ ex: Exercise) -> some View {
        let weight = String(format: "%.1f", ex.weight)
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ex.name).bold()
                Text("Sett: \(ex.sets), Reps: \(ex.reps), Vekt: \(weight) kg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 16) {
                // Rediger-knapp
                Button {
                    withAnimation {
                        if let idx = vm.exercises.firstIndex(of: ex) {
                            vm.editingExerciseIndex = IdentifiableInt(value: idx)
                        }
                    }
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rediger øvelse")

                // Slett-knapp
                Button(role: .destructive) {
                    delete(ex)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Slett øvelse")
            }
        }
        .padding(.vertical, 6)
    }

    private func delete(_ ex: Exercise) {
        if let idx = vm.exercises.firstIndex(of: ex) {
            withAnimation {
                vm.exercises.remove(at: idx)
            }
        }
    }

    private var notesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notater")
                    .font(.headline)
                    .foregroundColor(.primary.opacity(0.9))

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $vm.notes)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedField == .notes ? Color.accentColor : Color(.separator), lineWidth: 1)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        )
                        .focused($focusedField, equals: .notes)
                        .frame(minHeight: 120)

                    if vm.notes.isEmpty {
                        Text("Skriv notater…")
                            .foregroundColor(.secondary)
                            .padding(12)
                    }
                }
            }
        }
    }

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
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(vm.isSaveDisabled)
            }
        }
    }
}
