import SwiftUI

struct CalendarWorkoutView: View {
    @Binding var workouts: [Workout]
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()

    private var daysInMonth: [Date?] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentMonth) else {
            return []
        }

        let dates = Calendar.current.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )

        let firstWeekday = Calendar.current.component(.weekday, from: dates.first!)
        let paddingDays = firstWeekday - 1

        return Array(repeating: nil, count: paddingDays) + dates.map { Optional($0) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Navigasjon
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(currentMonth.formatted(.dateTime.year().month()))
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // Ukedager (med unik ID)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }

                    // Dager
                    ForEach(daysInMonth.indices, id: \.self) { index in
                        if let date = daysInMonth[index] {
                            ZStack {
                                if Calendar.current.isDate(date, inSameDayAs: selectedDate) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.blue)
                                        .frame(height: 36)
                                } else if hasWorkout(on: date) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.green.opacity(0.8))
                                        .frame(height: 36)
                                }

                                Text("\(Calendar.current.component(.day, from: date))")
                                    .foregroundColor(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                                    .frame(maxWidth: .infinity, minHeight: 36)
                                    .onTapGesture {
                                        selectedDate = date
                                    }
                            }
                        } else {
                            Color.clear.frame(height: 36)
                        }
                    }
                }
                .padding(.horizontal)

                Divider().padding(.top, 4)

                // Øktliste
                VStack(alignment: .leading) {
                    Text("Økter den \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.headline)
                        .padding(.leading)

                    ForEach(workouts.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            HStack {
                                Image(systemName: "flame")
                                Text(workout.type)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }

    func hasWorkout(on date: Date) -> Bool {
        workouts.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}

extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        var current = self.startOfDay(for: interval.start)

        while current <= interval.end {
            dates.append(current)
            guard let next = self.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return dates
    }
}
