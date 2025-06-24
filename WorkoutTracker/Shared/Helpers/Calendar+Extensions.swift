import Foundation

extension Calendar {
    /// Genererer alle datoer inni intervallet som matcher de angitte komponentene (f.eks. start på dagen).
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        var current = startOfDay(for: interval.start)

        while current <= interval.end {
            dates.append(current)
            guard let next = date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }

        return dates
    }
}
