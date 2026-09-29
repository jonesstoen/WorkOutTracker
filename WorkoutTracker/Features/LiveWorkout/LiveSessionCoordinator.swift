import SwiftUI
import Combine

/// The ongoing workout as seen from outside the live screen (banner, Home).
@MainActor
final class LiveSessionCoordinator: ObservableObject {
    static let shared = LiveSessionCoordinator()

    @Published var isActive = false
    @Published var type: String = ""
    @Published var category: WorkoutCategory = .strength
    /// Start time with pauses added: active time is `(pausedAt ?? now) - timerStart`.
    /// Dates instead of a counter keep the banner right while the live screen is closed.
    @Published var timerStart: Date = .now
    @Published var pausedAt: Date?
    @Published var isLiveViewVisible = false

    // Callback invoked when the banner is tapped to resume the live view
    var onResumeTapped: (() -> Void)?

    private init() {}

    func updateTimer(elapsed: TimeInterval, isRunning: Bool, now: Date = .now) {
        timerStart = now.addingTimeInterval(-elapsed)
        pausedAt = isRunning ? nil : now
    }
}
