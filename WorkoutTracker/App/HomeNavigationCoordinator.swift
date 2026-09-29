import SwiftUI

@MainActor
final class HomeNavigationCoordinator: ObservableObject {
    static let shared = HomeNavigationCoordinator()

    enum Route: Hashable {
        /// Choose type, category and planned exercises
        case setup
        /// A new live workout; replaces the setup screen so finishing returns to Home
        case live(LiveStart)
        /// The ongoing workout, restored from its snapshot
        case resume
    }

    @Published var resumeLiveRequested = false

    private init() {}
}
