import SwiftUI

@main
struct WorkoutTrackerApp: App {
    @StateObject private var store: WorkoutStore

    init() {
        // All app-wide avhengigheter samles her slik at vi
        // enkelt kan bytte lagringslag eller injisere fakes i tester.
        let persistence = UserDefaultsPersistence()
        _store = StateObject(wrappedValue: WorkoutStore(persistence: persistence))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                
        }
    }
}
