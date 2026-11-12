import Foundation
import SwiftUI
import Testing
@testable import WorkoutTracker

/// The Climbing W logo drawn in SwiftUI, and the app icon picker in Settings.
@MainActor
struct AppIconTests {

    // MARK: Logo geometry

    private let unit = CGRect(x: 0, y: 0, width: 256, height: 256)

    @Test func climbingStrokeRisesAboveTheWAndStandsFree() {
        let mark = WorkoutMarkGeometry(in: unit)
        let w = mark.w.boundingRect
        let climb = mark.climb.boundingRect
        // The climbing stroke reaches higher than any part of the W (smaller y is higher).
        #expect(climb.minY < w.minY - 20)
        // Drawn with their stroke width, the two parts never touch: the gap survives.
        let style = StrokeStyle(lineWidth: mark.strokeWidth, lineCap: .round, lineJoin: .round)
        let inkedW = mark.w.strokedPath(style)
        let inkedClimb = mark.climb.strokedPath(style)
        // CoreGraphics returns a degenerate (non-empty, zero-area) path for disjoint shapes, so
        // check the area of the intersection rather than `isEmpty`, and sample to be sure.
        let overlap = inkedW.intersection(inkedClimb).boundingRect
        #expect(overlap.isNull || overlap.isInfinite || overlap.width * overlap.height < 0.01, "\(overlap)")
        var shared = 0
        for x in stride(from: 0.0, through: 256, by: 1) {
            for y in stride(from: 0.0, through: 256, by: 1) {
                let point = CGPoint(x: x, y: y)
                if inkedW.contains(point) && inkedClimb.contains(point) { shared += 1 }
            }
        }
        #expect(shared == 0)
    }

    @Test func climbingStrokeStandsAtSeventyFiveDegrees() {
        let mark = WorkoutMarkGeometry(in: unit)
        let dx = mark.climbEnd.x - mark.climbStart.x
        let dy = mark.climbStart.y - mark.climbEnd.y
        #expect(abs(atan2(dy, dx) * 180 / .pi - 75) < 0.01)
    }

    @Test func markFitsAndCentresInAnyFrame() {
        let style = { (m: WorkoutMarkGeometry) in
            StrokeStyle(lineWidth: m.strokeWidth, lineCap: .round, lineJoin: .round)
        }
        for rect in [unit, CGRect(x: 0, y: 0, width: 22, height: 22), CGRect(x: 10, y: 0, width: 400, height: 100)] {
            let mark = WorkoutMarkGeometry(in: rect)
            let inked = mark.w.strokedPath(style(mark)).boundingRect
                .union(mark.climb.strokedPath(style(mark)).boundingRect)
            #expect(rect.insetBy(dx: -0.5, dy: -0.5).contains(inked), "\(rect): \(inked)")
            #expect(abs(inked.midX - rect.midX) < rect.height * 0.04)
            #expect(abs(inked.midY - rect.midY) < rect.height * 0.04)
        }
    }

    // MARK: App icon choice

    @Test func choicesMapToTheIconSetsInTheAssetCatalog() {
        #expect(AppIconChoice.allCases == [.automatic, .navy, .black, .tinted])
        #expect(AppIconChoice.automatic.alternateIconName == nil)
        #expect(AppIconChoice.navy.alternateIconName == "AppIcon-Navy")
        #expect(AppIconChoice.black.alternateIconName == "AppIcon-Black")
        #expect(AppIconChoice.tinted.alternateIconName == "AppIcon-Tinted")
        for choice in AppIconChoice.allCases {
            #expect(AppIconChoice(alternateIconName: choice.alternateIconName) == choice)
        }
        #expect(AppIconChoice(alternateIconName: "Removed") == .automatic)
        #expect(AppIconChoice.allCases.map(\.title) == ["Automatisk", "Blå", "Svart", "Tonet"])
    }

    @Test func modelStartsFromTheCurrentIconAndSwitches() async {
        let switcher = InMemoryAppIconSwitcher(current: "AppIcon-Black")
        let model = AppIconModel(switcher: switcher)
        #expect(model.isSupported)
        #expect(model.selection == .black)

        await model.select(.tinted)
        #expect(model.selection == .tinted)
        #expect(switcher.current == "AppIcon-Tinted")

        await model.select(.automatic)
        #expect(model.selection == .automatic)
        #expect(switcher.current == nil)
        #expect(switcher.requests == ["AppIcon-Tinted", nil])
    }

    @Test func choosingTheCurrentIconDoesNothing() async {
        let switcher = InMemoryAppIconSwitcher(current: nil)
        await AppIconModel(switcher: switcher).select(.automatic)
        #expect(switcher.requests.isEmpty)
    }

    @Test func failedSwitchKeepsTheOldIconAndReportsIt() async {
        let switcher = InMemoryAppIconSwitcher(current: nil)
        switcher.failure = CocoaError(.featureUnsupported)
        let model = AppIconModel(switcher: switcher)
        await model.select(.navy)
        #expect(model.selection == .automatic)
        #expect(!model.isChanging)
        #expect(model.error != nil)
        model.dismissError()
        #expect(model.error == nil)
    }

    @Test func everyAlternateIconSetExistsInTheAssetCatalog() throws {
        let assets = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("WorkoutTracker/Assets.xcassets")
        for name in AppIconChoice.allCases.compactMap(\.alternateIconName) {
            let contents = assets.appendingPathComponent("\(name).appiconset/Contents.json")
            #expect(FileManager.default.fileExists(atPath: contents.path), "\(name) is missing")
        }
    }
}
