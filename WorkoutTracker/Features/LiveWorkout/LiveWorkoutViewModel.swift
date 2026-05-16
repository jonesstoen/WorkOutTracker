import Foundation
import Combine

@MainActor
final class LiveWorkoutViewModel: ObservableObject {
    @Published var draft = LiveWorkout()
    @Published private(set) var elapsed: TimeInterval = 0
    @Published var isRunning: Bool = true
    @Published var showExerciseSheet = false

    private var timerCancellable: AnyCancellable?
    private var saveCancellable: AnyCancellable?
    private let repository: WorkoutRepository
    private var pauseBeganAt: Date?
    private var totalPaused: TimeInterval = 0
    private var historicalPRs: [String: Double] = [:]

    private static let snapshotKey = "liveSessionSnapshot"

    // MARK: - Init

    init(
        store: WorkoutStore,
        initialType: String = "",
        initialCategory: WorkoutCategory = .strength,
        initialExercises: [Exercise] = [],
        restoreIfAvailable: Bool = false
    ) {
        self.repository = store

        let prMap = PRService.computePRs(from: store.workouts)
        historicalPRs = prMap.mapValues { $0.e1RM }

        if restoreIfAvailable, let snapshot = Self.loadSnapshot() {
            draft = snapshot.draft
            totalPaused = snapshot.wasRunning
                ? snapshot.totalPaused
                : snapshot.totalPaused + Date().timeIntervalSince(snapshot.savedAt)
            isRunning = snapshot.wasRunning
        } else {
            Self.clearSnapshot()
            draft.type = initialType
            draft.category = initialCategory
            draft.exercises = initialExercises
            isRunning = true
        }

        startTimer()
        startAutosave()

        if restoreIfAvailable, Self.hasSnapshot() {
            LiveActivityManager.shared.update(
                isRunning: isRunning,
                exerciseCount: draft.exercises.count,
                elapsed: elapsed
            )
        } else if !restoreIfAvailable {
            LiveActivityManager.shared.start(
                workoutType: initialType.isEmpty ? initialCategory.rawValue : initialType,
                categoryIcon: initialCategory.iconName,
                startDate: draft.startDate,
                exerciseCount: 0
            )
        }
    }

    // MARK: - Timer

    func startTimer() {
        timerCancellable?.cancel()
        var lastExerciseCount = -1
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let now = Date()
                let currentPause = self.pauseBeganAt.map { now.timeIntervalSince($0) } ?? 0
                self.elapsed = now.timeIntervalSince(self.draft.startDate) - (self.totalPaused + currentPause)
                let count = self.draft.exercises.count
                if count != lastExerciseCount {
                    lastExerciseCount = count
                    LiveActivityManager.shared.update(isRunning: self.isRunning, exerciseCount: count, elapsed: self.elapsed)
                }
            }
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        pauseBeganAt = Date()
        LiveActivityManager.shared.update(isRunning: false, exerciseCount: draft.exercises.count, elapsed: elapsed)
    }

    func resume() {
        guard !isRunning else { return }
        isRunning = true
        if let began = pauseBeganAt {
            totalPaused += Date().timeIntervalSince(began)
            pauseBeganAt = nil
        }
        LiveActivityManager.shared.update(isRunning: true, exerciseCount: draft.exercises.count, elapsed: elapsed)
    }

    // MARK: - Finish / Abort

    func finish() {
        let workout = Workout(
            date: draft.startDate,
            type: draft.type.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category,
            exercises: draft.exercises,
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: elapsed
        )
        repository.add(workout)
        LiveActivityManager.shared.end(elapsed: elapsed, exerciseCount: draft.exercises.count)
        Self.clearSnapshot()
    }

    func abort() {
        LiveActivityManager.shared.end(elapsed: elapsed, exerciseCount: draft.exercises.count)
        Self.clearSnapshot()
    }

    // MARK: - PR check

    func isPR(exerciseName: String, weight: Double, reps: Int) -> Bool {
        guard weight > 0, reps > 0 else { return false }
        guard let best = historicalPRs[exerciseName.lowercased()] else { return false }
        return PRService.e1RM(weight: weight, reps: reps) > best
    }

    // MARK: - Persistence

    func saveSnapshot() {
        let snapshot = LiveSessionSnapshot(
            draft: draft,
            totalPaused: totalPaused + (pauseBeganAt.map { Date().timeIntervalSince($0) } ?? 0),
            wasRunning: isRunning,
            savedAt: Date()
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.snapshotKey)
        }
    }

    static func hasSnapshot() -> Bool {
        UserDefaults.standard.data(forKey: snapshotKey) != nil
    }

    static func loadSnapshot() -> LiveSessionSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(LiveSessionSnapshot.self, from: data)
    }

    static func clearSnapshot() {
        UserDefaults.standard.removeObject(forKey: snapshotKey)
    }

    // Debounced autosave whenever the draft changes
    private func startAutosave() {
        saveCancellable = $draft
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveSnapshot() }
    }
}
