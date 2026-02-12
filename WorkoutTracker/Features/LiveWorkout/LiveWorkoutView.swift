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
    @FocusState private var focused: Bool

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
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Tid")
                        Spacer()
                        Text(timeString(vm.elapsed))
                            .font(.headline)
                            .monospacedDigit()
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
                        ForEach(vm.draft.exercises) { ex in
                            Button {
                                openEdit(ex)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ex.name).font(.headline)
                                    Text("Sett: \(ex.sets) · Reps: \(ex.reps) · \(String(format: "%.1f", ex.weight)) kg")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
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
                        Text("\(vm.draft.exercises.count)").foregroundStyle(.secondary)
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
                    Button("Lukk") { dismiss() }
                }
            }
            .sheet(isPresented: $vm.showExerciseSheet) {
                NewExerciseSheet(exercises: $vm.draft.exercises)
            }
            .sheet(item: $vm.editingExerciseIndex) { idx in
                EditExerciseSheet(exercise: $vm.draft.exercises[idx.value])
            }
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
