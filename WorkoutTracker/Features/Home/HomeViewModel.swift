//
// HomeViewModel.swift
// WorkoutTracker
//
// Updated by Johannes Støen on 29/06/2025.
//

import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published private(set) var workouts: [Workout] = []
    private var cancellables = Set<AnyCancellable>()

    init(store: WorkoutStore) {
        self.workouts = store.workouts
        store.$workouts
            .receive(on: DispatchQueue.main)
            .assign(to: \.workouts, on: self)
            .store(in: &cancellables)
    }

    // MARK: – Computed properties

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:   return "God morgen"
        case 12..<17:  return "God dag"
        case 17..<22:  return "God kveld"
        default:       return "God natt"
        }
    }

    var dateString: String {
        Date().formatted(.dateTime.day().month().year())
    }

    var totalSets: Int {
        workouts.reduce(0) { sum, w in
            sum + w.exercises.reduce(0) { $0 + $1.sets }
        }
    }

    var totalReps: Int {
        workouts.reduce(0) { sum, w in
            sum + w.exercises.reduce(0) { $0 + ($1.sets * $1.reps) }
        }
    }

    var totalWeight: Double {
        workouts.reduce(0) { sum, w in
            sum + w.exercises.reduce(0) {
                $0 + (Double($1.sets * $1.reps) * $1.weight)
            }
        }
    }

    /// Antall økter per dag for de siste `days` dagene
    func counts(forLast days: Int) -> [Int] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            return workouts.filter {
                cal.isDate($0.date, inSameDayAs: day)
            }.count
        }
        .reversed()
    }

    /// Datoetiketter for de siste `days` dagene (f.eks. "1 Jul", "2 Jul", ...)
    func labels(forLast days: Int) -> [String] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "nb_NO")
        fmt.dateFormat = "d MMM"
        let today = cal.startOfDay(for: Date())
        return (0..<days).map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            return fmt.string(from: day)
        }
        .reversed()
    }

    /// Summerer antall økter per uke for de siste `days` dagene.
    func weeklyCounts(forLast days: Int) -> (counts: [Int], labels: [String]) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weeks = Int(ceil(Double(days) / 7.0))

        // Finn én dato per uke, fra eldste til nyeste
        let weekDates: [Date] = (0..<weeks).map { offset in
            cal.date(byAdding: .weekOfYear, value: -offset, to: today)!
        }.reversed()

        // Tell økter i hver uke
        let counts: [Int] = weekDates.map { wkDate in
            workouts.filter {
                cal.isDate($0.date,
                           equalTo: wkDate,
                           toGranularity: .weekOfYear)
            }.count
        }

        // Etiketter som "Uke 23" osv.
        let labels: [String] = weekDates.map { wkDate in
            let w = cal.component(.weekOfYear, from: wkDate)
            return "Uke \(w)"
        }

        return (counts, labels)
    }

    /// Prosentvis endring i antall økter siste `days` dager vs. de forrige `days` dagene.
    /// Returnerer 0 hvis begge perioder er 0, 100 hvis tidligere periode var 0 men nå >0.
    func percentChange(forLast days: Int) -> Double? {
        let all = counts(forLast: days * 2)
        guard all.count == days * 2 else { return nil }

        let prev = all.prefix(days).reduce(0, +)
        let curr = all.suffix(days).reduce(0, +)

        // Ingen endring om begge er 0
        if prev == 0 && curr == 0 { return 0 }

        // Hvis ingen i forrige periode men noen nå → 100%
        if prev == 0 && curr > 0 { return 100 }

        // Standard %–formel
        return prev > 0
            ? (Double(curr - prev) / Double(prev)) * 100
            : nil
    }

    /// De seneste 5 øktene, sortert synkende på dato
    var recentWorkouts: [Workout] {
        Array(workouts.sorted { $0.date > $1.date }.prefix(5))
    }
}
