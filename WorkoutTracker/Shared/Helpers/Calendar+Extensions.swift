import Foundation

extension Calendar {
    /// Starten på hver dag i intervallet. Slutten er eksklusiv, så en måned gir ikke med dag 1 i neste måned.
    func generateDates(inside interval: DateInterval) -> [Date] {
        var dates: [Date] = []
        var current = startOfDay(for: interval.start)

        while current < interval.end {
            dates.append(current)
            guard let next = date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }
}
