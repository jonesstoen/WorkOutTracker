import Foundation
import Testing
@testable import WorkoutTracker

@MainActor
struct CalendarGridTests {

    private func viewModel(firstWeekday: Int) -> CalendarViewModel {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = firstWeekday
        let vm = CalendarViewModel(store: WorkoutStore(persistence: PersistenceServiceFake()), calendar: cal)
        vm.currentMonth = cal.date(from: DateComponents(year: 2026, month: 9, day: 15))!
        return vm
    }

    private func dayNumbers(_ vm: CalendarViewModel) -> [Int?] {
        vm.daysInMonth.map { $0.map { Calendar(identifier: .gregorian).component(.day, from: $0) } }
    }

    @Test
    func mondayFirst_placesSeptemberFirstOnTuesday() {
        // 1 September 2026 is a Tuesday: one empty cell before it when weeks start on Monday
        let days = dayNumbers(viewModel(firstWeekday: 2))
        #expect(days.prefix(2) == [nil, 1])
    }

    @Test
    func sundayFirst_placesSeptemberFirstOnTuesday() {
        let days = dayNumbers(viewModel(firstWeekday: 1))
        #expect(days.prefix(3) == [nil, nil, 1])
    }

    @Test
    func monthContainsOnlyItsOwnDays() {
        let days = dayNumbers(viewModel(firstWeekday: 2)).compactMap { $0 }
        #expect(days == Array(1...30))
    }
}
