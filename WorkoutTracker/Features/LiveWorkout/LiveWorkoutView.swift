import SwiftUI
import UIKit

struct LiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var vm: LiveWorkoutViewModel
    @State private var showExitConfirm = false
    @State private var showFinishConfirm = false
    @State private var showNotes = false

    init(
        store: WorkoutStore,
        initialType: String = "",
        initialCategory: WorkoutCategory = .strength,
        initialExercises: [Exercise] = [],
        restoreIfAvailable: Bool = false
    ) {
        _vm = StateObject(
            wrappedValue: LiveWorkoutViewModel(
                store: store,
                initialType: initialType,
                initialCategory: initialCategory,
                initialExercises: initialExercises,
                restoreIfAvailable: restoreIfAvailable
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                timerBar

                if vm.draft.exercises.isEmpty {
                    emptyState
                } else {
                    exerciseList
                }

                addExerciseButton
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                notesToggle
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Spacer().frame(height: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .tabBar)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                principalToolbar
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Avbryt") { showExitConfirm = true }
            }
            ToolbarItem(placement: .keyboard) {
                Button("Ferdig") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .confirmationDialog(
            "Avbryte økten uten å lagre?",
            isPresented: $showExitConfirm,
            titleVisibility: .visible
        ) {
            Button("Avbryt økt uten å lagre", role: .destructive) {
                vm.abort()
                LiveSessionCoordinator.shared.isActive = false
                LiveSessionCoordinator.shared.isLiveViewVisible = false
                dismiss()
            }
            Button("Fortsett økten", role: .cancel) { }
        } message: {
            Text("Hvis du avbryter nå vil ikke økten bli lagret.")
        }
        .alert("Fullføre og lagre?", isPresented: $showFinishConfirm) {
            Button("Avbryt", role: .cancel) { }
            Button("Fullfør") {
                vm.finish()
                LiveSessionCoordinator.shared.isActive = false
                dismiss()
            }
        } message: {
            Text("Økten er veldig kort eller uten øvelser. Vil du likevel lagre?")
        }
        .sheet(isPresented: $vm.showExerciseSheet) {
            let exercisesBinding = Binding<[Exercise]>(
                get: { vm.draft.exercises },
                set: { vm.draft.exercises = $0 }
            )
            NewExerciseSheet(exercises: exercisesBinding)
        }
        .onAppear {
            let s = LiveSessionCoordinator.shared
            s.isActive = true
            s.type = vm.draft.type.trimmingCharacters(in: .whitespacesAndNewlines)
            s.category = vm.draft.category
            s.elapsed = vm.elapsed
            s.isLiveViewVisible = true
        }
        .onChange(of: vm.elapsed) { newValue in
            LiveSessionCoordinator.shared.elapsed = newValue
        }
        .onChange(of: vm.draft.type) { newValue in
            LiveSessionCoordinator.shared.type = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .onChange(of: vm.draft.category) { newValue in
            LiveSessionCoordinator.shared.category = newValue
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background { vm.saveSnapshot() }
        }
        .onDisappear {
            if LiveSessionCoordinator.shared.isActive {
                LiveSessionCoordinator.shared.isLiveViewVisible = false
            }
        }
    }

    // MARK: – Subviews

    private var principalToolbar: some View {
        VStack(spacing: 2) {
            Text("Pågående økt").font(.headline)
            HStack(spacing: 5) {
                Image(systemName: vm.draft.category.iconName)
                    .foregroundStyle(vm.draft.category.color)
                Text(
                    vm.draft.type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? vm.draft.category.rawValue
                        : vm.draft.type
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var exerciseList: some View {
        VStack(spacing: 16) {
            ForEach(vm.draft.exercises.indices, id: \.self) { i in
                let exerciseBinding = Binding<Exercise>(
                    get: { vm.draft.exercises[i] },
                    set: { vm.draft.exercises[i] = $0 }
                )
                ExerciseCard(
                    exercise: exerciseBinding,
                    index: i,
                    onDelete: {
                        withAnimation {
                            var updated = vm.draft.exercises
                            if updated.indices.contains(i) {
                                updated.remove(at: i)
                                vm.draft.exercises = updated
                            }
                        }
                    },
                    isPR: { weight, reps in
                        vm.isPR(exerciseName: vm.draft.exercises[i].name, weight: weight, reps: reps)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: – Timer bar

    private var timerBar: some View {
        HStack(spacing: 12) {
            // Pause / Resume
            Button {
                vm.isRunning ? vm.pause() : vm.resume()
            } label: {
                Image(systemName: vm.isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(vm.isRunning ? Color.accentColor : .orange)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(timeString(vm.elapsed))
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                Text(vm.isRunning ? "Pågår" : "Pauset")
                    .font(.caption2).bold()
                    .foregroundStyle(vm.isRunning ? .green : .orange)
            }

            Spacer()

            // Finish
            Button {
                Task { await handleFinishTapped() }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: – Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "dumbbell")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
                .padding(.top, 52)

            Text("Ingen øvelser enda")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Trykk «Legg til øvelse» for å starte.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }

    // MARK: – Add exercise

    private var addExerciseButton: some View {
        Button {
            vm.showExerciseSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Legg til øvelse")
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: – Notes

    private var notesToggle: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showNotes.toggle() }
            } label: {
                HStack {
                    Label("Notater", systemImage: "note.text")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showNotes ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if showNotes {
                let notesBinding = Binding<String>(
                    get: { vm.draft.notes },
                    set: { vm.draft.notes = $0 }
                )
                ZStack(alignment: .topLeading) {
                    if vm.draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Hvordan gikk det? Hva var bra?")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: notesBinding)
                        .frame(minHeight: 100)
                        .padding(4)
                }
                .padding(.horizontal, 4)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: – Helpers

    @MainActor
    private func handleFinishTapped() async {
        if vm.elapsed < 60 || vm.draft.exercises.isEmpty {
            showFinishConfirm = true
        } else {
            vm.finish()
            LiveSessionCoordinator.shared.isActive = false
            dismiss()
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%02d:%02d", m, sec)
    }
}

// MARK: – Exercise card

private struct ExerciseCard: View {
    @Binding var exercise: Exercise
    let index: Int
    let onDelete: () -> Void
    let isPR: (Double, Int) -> Bool

    @State private var showRename = false
    @State private var pendingName = ""

    private static let palette: [Color] = [
        .blue, .orange, .purple, .green, .red, .pink, .teal, .yellow
    ]
    private var accentColor: Color { Self.palette[index % Self.palette.count] }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 5)

            VStack(spacing: 0) {
                headerRow
                Divider()
                columnHeader
                setRows
                addSetButton
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        .alert("Gi øvelsen nytt navn", isPresented: $showRename) {
            TextField("Navn", text: $pendingName)
                .textInputAutocapitalization(.sentences)
            Button("Avbryt", role: .cancel) { }
            Button("Lagre") {
                let t = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { exercise.name = t }
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text("\(index + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accentColor)
            }

            Text(exercise.name)
                .font(.headline)

            Button {
                pendingName = exercise.name
                showRename = true
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            if exercise.totalVolume > 0 {
                Text("\(Int(exercise.totalVolume)) kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(.systemGray4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var columnHeader: some View {
        HStack(spacing: 0) {
            Text("SETT")
                .frame(width: 48, alignment: .leading)
            Spacer()
            Text("KG")
                .frame(width: 90, alignment: .center)
            Spacer()
            Text("REPS")
                .frame(width: 90, alignment: .center)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color(.tertiarySystemBackground))
    }

    private var setRows: some View {
        ForEach(exercise.sets.indices, id: \.self) { i in
            let setBinding = Binding<WorkingSet>(
                get: { exercise.sets[i] },
                set: { exercise.sets[i] = $0 }
            )
            let showPR = isPR(exercise.sets[i].weight, exercise.sets[i].reps)
            LiveSetRow(setNumber: i + 1, set: setBinding, showPR: showPR) {
                withAnimation {
                    var updated = exercise.sets
                    updated.remove(at: i)
                    exercise.sets = updated
                }
            }
            if i < exercise.sets.count - 1 {
                Divider().padding(.leading, 14)
            }
        }
    }

    private var addSetButton: some View {
        Button {
            let last = exercise.sets.last ?? WorkingSet(reps: 10, weight: 0)
            withAnimation(.easeInOut(duration: 0.15)) {
                exercise.sets.append(WorkingSet(reps: last.reps, weight: last.weight))
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                Text("Legg til sett")
            }
            .font(.subheadline)
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: – Set row

private struct LiveSetRow: View {
    let setNumber: Int
    @Binding var set: WorkingSet
    let showPR: Bool
    let onDelete: () -> Void

    @State private var showPicker = false

    var body: some View {
        HStack(spacing: 0) {
            Text("\(setNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)

            Spacer()

            Button { showPicker = true } label: {
                HStack(spacing: 0) {
                    // Weight pill
                    HStack(spacing: 4) {
                        Text(weightLabel(set.weight))
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 54, alignment: .center)
                            .padding(.vertical, 7)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 86)

                    Spacer()

                    // Reps pill
                    HStack(spacing: 4) {
                        Text("\(set.reps)")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 44, alignment: .center)
                            .padding(.vertical, 7)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 86)
                }
            }
            .buttonStyle(.plain)

            Image(systemName: "trophy.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
                .opacity(showPR ? 1 : 0)
                .frame(width: 20)
                .padding(.leading, 4)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.7))
                    .font(.body)
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .sheet(isPresented: $showPicker) {
            SetPickerSheet(weight: $set.weight, reps: $set.reps)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }

    private func weightLabel(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }
}

// MARK: – Set picker sheet

private struct SetPickerSheet: View {
    @Binding var weight: Double
    @Binding var reps: Int
    @Environment(\.dismiss) private var dismiss

    @State private var selectedWeight: Double
    @State private var selectedReps: Int

    private static let weights: [Double] = Array(stride(from: 0.0, through: 300.0, by: 0.5))
    private static let repValues: [Int]  = Array(1...50)

    init(weight: Binding<Double>, reps: Binding<Int>) {
        _weight = weight
        _reps   = reps
        let snapped = max(0, min(300, (weight.wrappedValue * 2).rounded() / 2))
        _selectedWeight = State(initialValue: snapped)
        _selectedReps   = State(initialValue: max(1, min(50, reps.wrappedValue)))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle + header
            HStack {
                Text("Vekt og reps")
                    .font(.headline)
                Spacer()
                Button("Ferdig") {
                    weight = selectedWeight
                    reps   = selectedReps
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // Column labels
            HStack(spacing: 0) {
                Text("KG")
                    .frame(maxWidth: .infinity)
                Text("REPS")
                    .frame(maxWidth: .infinity)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 8)

            // Wheels
            HStack(spacing: 0) {
                Picker("Vekt", selection: $selectedWeight) {
                    ForEach(Self.weights, id: \.self) { w in
                        Text(w.truncatingRemainder(dividingBy: 1) == 0
                             ? "\(Int(w))"
                             : String(format: "%.1f", w))
                            .tag(w)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Picker("Reps", selection: $selectedReps) {
                    ForEach(Self.repValues, id: \.self) { r in
                        Text("\(r)").tag(r)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: selectedWeight) { weight = $0 }
            .onChange(of: selectedReps)   { reps   = $0 }
        }
        .background(Color(.systemBackground))
    }
}
