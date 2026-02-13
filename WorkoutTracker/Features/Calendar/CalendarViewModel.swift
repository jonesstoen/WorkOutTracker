//
//  CalendarViewModel.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 24/06/2025.
//


import SwiftUI
import Combine

@MainActor
class CalendarViewModel: ObservableObject {
    // Publiserer økter fra butikken
    @Published var workouts: [Workout] = []
    // Hvilken dag er valgt
    @Published var selectedDate: Date = Date()
    // Hvilken måned vises
    @Published var currentMonth: Date = Date()

    private var cancellables = Set<AnyCancellable>()

    init(store: WorkoutStore) {
        // Abonner på butikken
        workouts = store.workouts
        store.$workouts
            .receive(on: DispatchQueue.main)
            .assign(to: \.workouts, on: self)
            .store(in: &cancellables)
    }

    // Alle dagene i måneden, med padding for uken start
    var daysInMonth: [Date?] {
        guard let monthInterval = Calendar.current.dateInterval(
                of: .month,
                for: currentMonth
        ) else { return [] }

        let dates = Calendar.current.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )

        guard let firstDate = dates.first else {
            return []
        }
        let firstWeekday = Calendar.current.component(.weekday, from: firstDate)
        let paddingDays = firstWeekday - 1

        return Array(repeating: nil, count: paddingDays)
             + dates.map { Optional($0) }
    }

    // Flytt måneden frem og tilbake
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(
            byAdding: .month,
            value: value,
            to: currentMonth
        ) {
            currentMonth = newDate
        }
    }

    // Har det vært en økt på denne datoen?
    func hasWorkout(on date: Date) -> Bool {
        workouts.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    // Økter for den valgte dagen
    var workoutsForSelectedDate: [Workout] {
        workouts.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
}
