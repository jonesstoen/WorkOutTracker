import Foundation

struct WorkingSet: Identifiable, Codable, Equatable {
    let id: UUID
    var reps: Int
    var weight: Double
    /// Haket av under en live-økt. Sett lagret før dette feltet fantes, regnes som fullført.
    var isCompleted: Bool

    init(id: UUID = UUID(), reps: Int, weight: Double, isCompleted: Bool = true) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        reps = try c.decode(Int.self, forKey: .reps)
        weight = try c.decode(Double.self, forKey: .weight)
        isCompleted = try c.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? true
    }

    /// Samme reps og vekt som et nytt, ikke fullført sett (til planlegging).
    var planned: WorkingSet {
        WorkingSet(reps: reps, weight: weight, isCompleted: false)
    }
}

struct Exercise: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var sets: [WorkingSet]

    init(id: UUID = UUID(), name: String, sets: [WorkingSet] = []) {
        self.id = id
        self.name = name
        self.sets = sets
    }

    // Migrates old flat format (sets: Int, reps: Int, weight: Double) to new nested format.
    // Old data stored sets/reps/weight as top-level integers — we expand them into WorkingSet rows.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        if let workingSets = try? c.decode([WorkingSet].self, forKey: .sets) {
            sets = workingSets
        } else {
            let n = (try? c.decode(Int.self, forKey: .sets)) ?? 1
            let reps = (try? c.decode(Int.self, forKey: .reps)) ?? 10
            let weight = (try? c.decode(Double.self, forKey: .weight)) ?? 0
            sets = (0..<max(1, n)).map { _ in WorkingSet(reps: reps, weight: weight) }
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(sets, forKey: .sets)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, sets, reps, weight
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + Double($1.reps) * $1.weight }
    }

    var summary: String {
        guard !sets.isEmpty else { return "Ingen sett" }
        let n = sets.count
        let allSameReps = sets.allSatisfy { $0.reps == sets[0].reps }
        let allSameWeight = sets.allSatisfy { $0.weight == sets[0].weight }
        let repsStr = allSameReps ? "\(sets[0].reps)" : sets.map { "\($0.reps)" }.joined(separator: "/")
        let weightStr: String
        if allSameWeight {
            weightStr = "\(sets[0].weight.kgLabel) kg"
        } else {
            let minW = sets.map(\.weight).min()!
            let maxW = sets.map(\.weight).max()!
            weightStr = "\(minW.kgLabel)–\(maxW.kgLabel) kg"
        }
        return "\(n) sett · \(repsStr) reps · \(weightStr)"
    }
}

extension Double {
    /// Vekt uten unødvendige desimaler, med lokal desimalskilletegn ("80", "82,5").
    var kgLabel: String {
        formatted(.number.precision(.fractionLength(0...1)))
    }
}

extension String {
    /// Normalisert nøkkel for å matche øvelsesnavn ("Benkpress " == "benkpress").
    var exerciseKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
