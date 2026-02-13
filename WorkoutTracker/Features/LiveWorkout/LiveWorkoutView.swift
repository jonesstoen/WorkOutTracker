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
    @State private var showFinishConfirm = false

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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tid")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(vm.isRunning ? "Pågår" : "Pauset")
                            .font(.caption)
                            .foregroundStyle(vm.isRunning ? .green : .orange)
                    }

                    HStack {
                        Spacer()
                        Text(timeString(vm.elapsed))
                            .font(.system(size: 32, weight: .semibold, design: .monospaced))
                            .foregroundStyle(vm.isRunning ? .primary : .secondary)
                        Spacer()
                    }

                    HStack {
                        Button {
                            vm.isRunning ? vm.pause() : vm.resume()
                        } label: {
                            Label(vm.isRunning ? "Pause" : "Fortsett",
                                  systemImage: vm.isRunning ? "pause.fill" : "play.fill")
                        }

                        Spacer()
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
                    VStack(spacing: 8) {
                        ContentUnavailableView(
                            "Ingen øvelser enda",
                            systemImage: "list.bullet.rectangle",
                            description: Text("Legg til øvelser underveis.")
                        )
                        Button {
                            vm.showExerciseSheet = true
                        } label: {
                            Label("Legg til første øvelse", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
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

            } header: {
                HStack {
                    Text("Øvelser")
                    Spacer()
                    Text("\(vm.draft.exercises.count)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Notater") {
                ZStack(alignment: .topLeading) {
                    if vm.draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Skriv notater om hvordan økten føltes, hva som gikk bra, osv.")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                    }
                    TextEditor(text: $vm.draft.notes)
                        .frame(minHeight: 100)
                }
            }

            Section {
                Button {
                    Task { await handleFinishTapped() }
                } label: {
                    HStack {
                        Spacer()
                        Label("Fullfør økt", systemImage: "checkmark.circle.fill")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
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
            "Avbryte økten uten å lagre?",
            isPresented: $showExitConfirm,
            titleVisibility: .visible
        ) {
            Button("Avbryt økt uten å lagre", role: .destructive) {
                dismiss()
            }
            Button("Fortsett økten", role: .cancel) { }
        } message: {
            Text("Hvis du avbryter nå vil økten ikke bli lagret.")
        }
        .alert("Fullføre og lagre økten?", isPresented: $showFinishConfirm) {
            Button("Avbryt", role: .cancel) { }
            Button("Fullfør", role: .destructive) {
                vm.finish()
                dismiss()
            }
        } message: {
            Text("Økten er veldig kort eller uten øvelser. Er du sikker på at du vil fullføre og lagre den?")
        }
        .sheet(isPresented: $vm.showExerciseSheet) {
            NewExerciseSheet(exercises: $vm.draft.exercises)
        }
        .sheet(item: $vm.editingExerciseIndex) { idx in
            EditExerciseSheet(exercise: $vm.draft.exercises[idx.value])
        }
    }

    @MainActor
    private func handleFinishTapped() async {
        // Hvis økta er veldig kort eller uten øvelser → bekreft før vi lagrer.
        let isVeryShort = vm.elapsed < 60 // under 1 minutt
        let hasNoExercises = vm.draft.exercises.isEmpty

        if isVeryShort || hasNoExercises {
            // Vis egen bekreftelse for å fullføre (lagre) kort/tom økt.
            showFinishConfirm = true
        } else {
            vm.finish()
            dismiss()
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
