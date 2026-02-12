import Foundation
import Combine
@MainActor
final class ExercisesViewModel: ObservableObject {
    @Published var exercises: [String] = []

    private enum Keys {
        static let customExercises = "customExercises"
    }

    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()

        // Debounce saving to avoid excessive UserDefaults writes
        $exercises
            .dropFirst() // Avoid saving immediately after initial load
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] exercises in
                self?.save(exercises)
            }
            .store(in: &cancellables)
    }

    /// Legg til ny egendefinert øvelse
    func add(_ new: String) {
        let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Case-insensitive de-dupe for better UX
        let normalizedNew = normalize(trimmed)
        guard !exercises.contains(where: { normalize($0) == normalizedNew }) else { return }

        exercises.append(trimmed)
    }

    /// Fjern øvelser på gitt offsets
    func remove(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    /// (Valgfritt) Kan være nyttig hvis du senere lar brukeren endre navn på øvelser
    func rename(from old: String, to new: String) {
        let newTrimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newTrimmed.isEmpty else { return }

        let oldNorm = normalize(old)
        guard let idx = exercises.firstIndex(where: { normalize($0) == oldNorm }) else { return }

        let newNorm = normalize(newTrimmed)
        // Ikke tillat rename til en øvelse som allerede finnes (case-insensitive)
        guard !exercises.enumerated().contains(where: { $0.offset != idx && normalize($0.element) == newNorm }) else { return }

        exercises[idx] = newTrimmed
    }

    private func load() {
        let loaded = userDefaults.stringArray(forKey: Keys.customExercises) ?? []
        // Rydd opp: trim + case-insensitive dedupe + fjern tomme
        exercises = dedupeAndClean(loaded)
    }

    private func save(_ exercises: [String]) {
        userDefaults.set(exercises, forKey: Keys.customExercises)
        // For debug ved behov:
        print("💾 Saved exercises:", exercises.count)
    }

    private func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    private func dedupeAndClean(_ input: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        out.reserveCapacity(input.count)

        for item in input {
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = normalize(trimmed)
            guard seen.insert(key).inserted else { continue }
            out.append(trimmed)
        }
        return out
    }
}
