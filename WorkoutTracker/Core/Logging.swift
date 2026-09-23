import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "WorkoutTracker"

    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let healthKit = Logger(subsystem: subsystem, category: "healthkit")
    static let liveActivity = Logger(subsystem: subsystem, category: "liveactivity")
}
