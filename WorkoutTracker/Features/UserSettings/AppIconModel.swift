import Foundation
import Observation
import UIKit

/// Which Home Screen icon the app uses. `automatic` is the primary icon, whose navy, dark and tinted
/// appearances follow the Home Screen setting; the others are alternate icon sets in
/// Assets.xcassets that keep one look.
enum AppIconChoice: String, CaseIterable, Identifiable, Sendable {
    case automatic, navy, black, tinted

    var id: Self { self }

    /// The icon set's name in the asset catalog (`nil` = the primary `AppIcon`).
    var alternateIconName: String? {
        switch self {
        case .automatic: nil
        case .navy: "AppIcon-Navy"
        case .black: "AppIcon-Black"
        case .tinted: "AppIcon-Tinted"
        }
    }

    /// An unknown name (an icon set from an older build) counts as the primary icon.
    init(alternateIconName: String?) {
        self = Self.allCases.first { $0.alternateIconName == alternateIconName } ?? .automatic
    }

    var title: String {
        switch self {
        case .automatic: "Automatisk"
        case .navy: "Blå"
        case .black: "Svart"
        case .tinted: "Tonet"
        }
    }
}

/// Reads and changes the app's Home Screen icon.
@MainActor
protocol AppIconSwitching: AnyObject {
    var supportsAlternateIcons: Bool { get }
    var alternateIconName: String? { get }
    func setAlternateIconName(_ name: String?) async throws
}

/// The real icon, through UIApplication.
@MainActor
final class SystemAppIconSwitcher: AppIconSwitching {
    var supportsAlternateIcons: Bool { UIApplication.shared.supportsAlternateIcons }
    var alternateIconName: String? { UIApplication.shared.alternateIconName }
    func setAlternateIconName(_ name: String?) async throws {
        try await UIApplication.shared.setAlternateIconName(name)
    }
}

/// For tests and previews: remembers every request, optionally fails.
@MainActor
final class InMemoryAppIconSwitcher: AppIconSwitching {
    private(set) var current: String?
    private(set) var requests: [String?] = []
    let supportsAlternateIcons: Bool
    var failure: (any Error)?

    init(current: String?, supported: Bool = true) {
        self.current = current
        supportsAlternateIcons = supported
    }

    var alternateIconName: String? { current }

    func setAlternateIconName(_ name: String?) async throws {
        requests.append(name)
        if let failure { throw failure }
        current = name
    }
}

/// The icon picker's state in Settings.
@MainActor
@Observable
final class AppIconModel {
    private(set) var selection: AppIconChoice
    private(set) var isChanging = false
    private(set) var error: String?
    let isSupported: Bool
    @ObservationIgnored private let switcher: any AppIconSwitching

    init(switcher: any AppIconSwitching) {
        self.switcher = switcher
        isSupported = switcher.supportsAlternateIcons
        selection = AppIconChoice(alternateIconName: switcher.alternateIconName)
    }

    func select(_ choice: AppIconChoice) async {
        guard choice != selection, !isChanging else { return }
        isChanging = true
        defer { isChanging = false }
        do {
            try await switcher.setAlternateIconName(choice.alternateIconName)
            selection = choice
        } catch {
            self.error = error.localizedDescription
        }
    }

    func dismissError() { error = nil }
}
