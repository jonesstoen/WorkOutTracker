//
//  LiveWorkoutView.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 12/02/2026.
//

import SwiftUI

struct LiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: LiveWorkoutViewModel
    @State private var showExitConfirm = false

    init(store: WorkoutStore, initialType: String = "", initialCategory: WorkoutCategory = .strength) {
        _vm = StateObject(
            wrappedValue: LiveWorkoutViewModel(
                store: store,
                initialType: initialType,
                initialCategory: initialCategory
            )
        )
    }

    var body: some View {
        // Viktig: IKKE legg en ny NavigationStack her.
        // LiveWorkoutView pushes allerede fra en NavigationStack.
        Form {
            Section {
                HStack {
                    Text("Tid")
                    Spacer()
                    Text(timeString(vm.elapsed))
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(vm.isRunning ? .primary : .secondary)
                }

                HStack {
                    Button(vm.isRunning ? "Pause" : "Fortsett") {
                        vm.isRunning ? vm.pause() : vm.resume()
                    }
                    Spacer()
                    Button("Fullfør") {
                        vm.finish()
                        dismiss()
                    }
                }
            }

            // Read-only info om økta
            Section {
                HStack {
                    Label(vm.draft.category.rawValue, systemImage: vm.draft.category.iconName)
                        .foregroundStyle(vm.draft.category.color)
                    Spacer()
                    Text(vm.draft.type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                         ? "Uten tittel"
                         : vm.draft.type)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if vm.draft.exercises.isEmpty {
                    ContentUnavailableView(
                        "Ingen øvelser enda",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Legg til øvelser underveis.")
                    )
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(Array(vm.draft.exercises.enumerated()), id: \.element.id) { index, ex in
                        HStack {
                            Button {
                                openEdit(ex)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ex.name)
                                        .font(.headline)
                                    Text("Sett: \(ex.sets) · Reps: \(ex.reps) · \(String(format: "%.1f", ex.weight)) kg")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            // Quick +1 set
                            Button {
                                vm.draft.exercises[index].sets += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.large)
                            }
                            .accessibilityLabel("Legg til ett sett")
                        }
                    }
                    .onDelete { vm.draft.exercises.remove(atOffsets: $0) }
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
                    Text("\(vm.draft.exercises.count)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Notater") {
                TextEditor(text: $vm.draft.notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle("Pågående økt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Lukk") { showExitConfirm = true }
            }
        }
        .confirmationDialog(
            "Avslutte økten?",
            isPresented: $showExitConfirm,
            titleVisibility: .visible
        ) {
            Button("Avslutt uten å lagre", role: .destructive) {
                dismiss()
            }
            Button("Fortsett økten", role: .cancel) { }
        } message: {
            Text("Du har en pågående økt. Hvis du avslutter nå, blir den ikke lagret.")
        }
        .sheet(isPresented: $vm.showExerciseSheet) {
            NewExerciseSheet(exercises: $vm.draft.exercises)
        }
        .sheet(item: $vm.editingExerciseIndex) { idx in
            EditExerciseSheet(exercise: $vm.draft.exercises[idx.value])
        }
    }

    private func openEdit(_ ex: Exercise) {
        if let idx = vm.draft.exercises.firstIndex(of: ex) {
            vm.editingExerciseIndex = IdentifiableInt(value: idx)
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}
