import Foundation
import Combine
import UIKit
import UserNotifications

@MainActor
final class LiveWorkoutViewModel: ObservableObject {
    @Published var draft = LiveWorkout()
    @Published private(set) var elapsed: TimeInterval = 0
    @Published var isRunning: Bool = true
    @Published var showExerciseSheet = false

    // Rest timer
    @Published private(set) var restSecondsRemaining: Int = 0
    @Published private(set) var restTimerActive: Bool = false
    var restDuration: Int = 90

    private var timerCancellable: AnyCancellable?
    private var saveCancellable: AnyCancellable?
    private var restCancellable: AnyCancellable?
    private var restEndsAt: Date?
    private let repository: WorkoutRepository
    private var pauseBeganAt: Date?
    private var totalPaused: TimeInterval = 0
    private var historicalPRs: [String: ExercisePR] = [:]
    private var snapshotWorkouts: [Workout] = []

    private static let snapshotKey = "liveSessionSnapshot"
    private static let restNotificationID = "restTimerFinished"

    // MARK: - Init

    init(
        store: WorkoutStore,
        initialType: String = "",
        initialCategory: WorkoutCategory = .strength,
        initialExercises: [Exercise] = [],
        restoreIfAvailable: Bool = false
    ) {
        self.repository = store
        self.snapshotWorkouts = store.workouts

        historicalPRs = PRService.computePRs(from: store.workouts)

        if restoreIfAvailable, let snapshot = Self.loadSnapshot() {
            draft = snapshot.draft
            totalPaused = snapshot.totalPaused
            isRunning = snapshot.wasRunning
            // A paused session stays paused: the pause continues from when the snapshot was saved
            pauseBeganAt = snapshot.wasRunning ? nil : snapshot.savedAt
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
            LiveActivityManager.shared.reattach()
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
            exercises: draft.completedExercises,
            notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            duration: elapsed
        )
        repository.add(workout)
        skipRest()
        LiveActivityManager.shared.end(elapsed: elapsed, exerciseCount: draft.exercises.count)
        Self.clearSnapshot()
    }

    func markAllCompleted() {
        draft.markAllCompleted()
    }

    func abort() {
        skipRest()
        LiveActivityManager.shared.end(elapsed: elapsed, exerciseCount: draft.exercises.count)
        Self.clearSnapshot()
    }

    // MARK: - Rest timer

    func startRestTimer() {
        let endsAt = Date().addingTimeInterval(TimeInterval(restDuration))
        restEndsAt = endsAt
        restSecondsRemaining = restDuration
        restTimerActive = true
        scheduleRestNotification(at: endsAt)

        // Remaining time is derived from the end date, so the timer stays correct after backgrounding
        restCancellable?.cancel()
        restCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tickRest() }
    }

    func skipRest() {
        restTimerActive = false
        restSecondsRemaining = 0
        restEndsAt = nil
        restCancellable?.cancel()
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.restNotificationID])
    }

    private func tickRest() {
        guard let restEndsAt else { return }
        restSecondsRemaining = max(0, Int(restEndsAt.timeIntervalSinceNow.rounded(.up)))
        if restSecondsRemaining == 0 {
            restTimerActive = false
            self.restEndsAt = nil
            restCancellable?.cancel()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func scheduleRestNotification(at date: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.restNotificationID])
        let seconds = date.timeIntervalSinceNow
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Hvilen er over"
        content.body = "Klar for neste sett?"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: Self.restNotificationID,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        )
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            center.add(request)
        }
    }

    // MARK: - Exercise history

    func lastSession(for exerciseName: String) -> ExerciseDataPoint? {
        ProgressionService.lastSession(for: exerciseName, in: snapshotWorkouts)
    }

    func plannedSets(for exerciseName: String) -> [WorkingSet]? {
        ProgressionService.plannedSets(for: exerciseName, in: snapshotWorkouts)
    }

    // MARK: - PR check

    func isPR(exerciseName: String, weight: Double, reps: Int) -> Bool {
        guard let best = historicalPRs[exerciseName.exerciseKey] else { return false }
        return PRService.isRecord(weight: weight, reps: reps, comparedTo: best)
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
