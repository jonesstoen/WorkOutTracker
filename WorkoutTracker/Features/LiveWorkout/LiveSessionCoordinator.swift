import SwiftUI
import Combine

@MainActor
final class LiveSessionCoordinator: ObservableObject {
    static let shared = LiveSessionCoordinator()

    @Published var isActive = false
    @Published var type: String = ""
    @Published var category: WorkoutCategory = .strength
    @Published var elapsed: TimeInterval = 0
    @Published var isLiveViewVisible = false

    // Callback invoked when the banner is tapped to resume the live view
    var onResumeTapped: (() -> Void)?

    private init() {}
}
