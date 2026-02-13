import SwiftUI

@MainActor
final class HomeNavigationCoordinator: ObservableObject {
    static let shared = HomeNavigationCoordinator()

    enum Route: Hashable {
        case liveWorkout
    }

    @Published var resumeLiveRequested = false

    private init() {}
}
