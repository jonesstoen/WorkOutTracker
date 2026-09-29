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
    private let store: WorkoutStore
    private let calendar: Calendar

    init(store: WorkoutStore, calendar: Calendar = .current) {
        self.store = store
        self.calendar = calendar
        // Abonner på butikken
        workouts = store.workouts
        store.$workouts
            .receive(on: DispatchQueue.main)
            .assign(to: &$workouts)
    }

    // Alle dagene i måneden, med tomme celler før dag 1 slik at den havner under riktig ukedag
    var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }

        let dates = calendar.generateDates(inside: monthInterval)
        guard let firstDate = dates.first else { return [] }

        // Kolonne 0 er kalenderens første ukedag (mandag i Norge, søndag i USA)
        let weekday = calendar.component(.weekday, from: firstDate)
        let paddingDays = (weekday - calendar.firstWeekday + 7) % 7

        return Array(repeating: nil, count: paddingDays) + dates.map { Optional($0) }
    }

    // Flytt måneden frem og tilbake
    func changeMonth(by value: Int) {
        if let newDate = calendar.date(
            byAdding: .month,
            value: value,
            to: currentMonth
        ) {
            currentMonth = newDate
        }
    }

    // Økter for den valgte dagen
    var workoutsForSelectedDate: [Workout] {
        workouts.filter {
            calendar.isDate($0.date, inSameDayAs: selectedDate)
        }
    }

    /// Hopp tilbake til dagens dato og måned
    func goToToday() {
        currentMonth = Date()
        selectedDate = Date()
    }

    /// Kategorifarger for alle økter på en gitt dag (maks 3)
    func workoutColors(on date: Date) -> [Color] {
        Array(
            workouts
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .prefix(3)
                .map { $0.category.color }
        )
    }

    /// Sletter én økt fra butikken
    func delete(_ workout: Workout) {
        store.delete(workout)
    }
}

