import SwiftUI
import UIKit

struct LiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var vm: LiveWorkoutViewModel
    @State private var showExitConfirm = false
    @State private var showFinishConfirm = false
    @State private var showIncompleteConfirm = false
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

                if vm.restTimerActive {
                    restTimerBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

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
        // Leaving happens only through Minimer (keeps running), Avbryt or Fullfør
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                principalToolbar
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    vm.saveSnapshot()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                }
                .accessibilityLabel("Minimer økten")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Avbryt", role: .destructive) { showExitConfirm = true }
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
            Button("Fullfør") { finishAndDismiss() }
        } message: {
            Text("Økten er veldig kort eller uten øvelser. Vil du likevel lagre?")
        }
        .confirmationDialog(
            vm.draft.incompleteSetCount == 1
                ? "1 sett er ikke haket av"
                : "\(vm.draft.incompleteSetCount) sett er ikke haket av",
            isPresented: $showIncompleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Lagre bare fullførte") { finishAndDismiss() }
            Button("Marker alle som fullført") {
                vm.markAllCompleted()
                finishAndDismiss()
            }
            Button("Fortsett økten", role: .cancel) { }
        } message: {
            Text("Sett som ikke er haket av, blir ikke lagret.")
        }
        .sheet(isPresented: $vm.showExerciseSheet) {
            let exercisesBinding = Binding<[Exercise]>(
                get: { vm.draft.exercises },
                set: { vm.draft.exercises = $0 }
            )
            NewExerciseSheet(exercises: exercisesBinding) { vm.plannedSets(for: $0) }
        }
        .onAppear {
            let s = LiveSessionCoordinator.shared
            s.isActive = true
            s.type = vm.draft.type.trimmingCharacters(in: .whitespacesAndNewlines)
            s.category = vm.draft.category
            s.updateTimer(elapsed: vm.elapsed, isRunning: vm.isRunning)
            s.isLiveViewVisible = true
        }
        .onChange(of: vm.isRunning) { isRunning in
            LiveSessionCoordinator.shared.updateTimer(elapsed: vm.elapsed, isRunning: isRunning)
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
            let s = LiveSessionCoordinator.shared
            if s.isActive {
                // Minimized: keep the latest edits and let the banner take over the clock
                vm.saveSnapshot()
                s.updateTimer(elapsed: vm.elapsed, isRunning: vm.isRunning)
                s.isLiveViewVisible = false
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
                    lastSession: vm.lastSession(for: vm.draft.exercises[i].name),
                    onDelete: {
                        withAnimation {
                            var updated = vm.draft.exercises
                            if updated.indices.contains(i) {
                                updated.remove(at: i)
                                vm.draft.exercises = updated
                            }
                        }
                    },
                    onSetCompleted: { withAnimation(.spring(response: 0.3)) { vm.startRestTimer() } },
                    isPR: { weight, reps in
                        vm.isPR(exerciseName: vm.draft.exercises[i].name, weight: weight, reps: reps)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: – Rest timer banner

    private var restTimerBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 3)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: CGFloat(vm.restSecondsRemaining) / CGFloat(vm.restDuration))
                    .stroke(vm.restSecondsRemaining <= 10 ? Color.orange : Color.accentColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: vm.restSecondsRemaining)
                Text("\(vm.restSecondsRemaining)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(vm.restSecondsRemaining <= 10 ? .orange : .primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Hviler")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(restTimeString(vm.restSecondsRemaining))
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundStyle(vm.restSecondsRemaining <= 10 ? .orange : .primary)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) { vm.skipRest() }
            } label: {
                Text("Hopp over")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) { Divider() }
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
            .accessibilityLabel(vm.isRunning ? "Pause" : "Fortsett")

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
            .accessibilityLabel("Fullfør økt")
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
        if vm.draft.incompleteSetCount > 0 {
            showIncompleteConfirm = true
        } else if vm.elapsed < 60 || vm.draft.exercises.isEmpty {
            showFinishConfirm = true
        } else {
            finishAndDismiss()
        }
    }

    private func finishAndDismiss() {
        vm.finish()
        LiveSessionCoordinator.shared.isActive = false
        dismiss()
    }

    private func restTimeString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%02d:%02d", m, sec)
    }
}
