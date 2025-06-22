import SwiftUI

struct CalendarWorkoutView: View {
    @Binding var workouts: [Workout]
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()

    private var daysInMonth: [Date] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        return Calendar.current.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
    }

    var body: some View {
        VStack {
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

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach([ "M", "TI", "O", "TO", "F", "L", "S"], id: \.self) { day in
                    Text(day).fontWeight(.bold)
                }

                ForEach(daysInMonth, id: \.self) { date in
                    VStack {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .foregroundColor(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .background(
                                Circle()
                                    .fill(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear)
                            )
                            .onTapGesture {
                                selectedDate = date
                            }

                        if hasWorkout(on: date) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 5, height: 5)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .padding(4)
                }
            }

            Divider().padding(.top)

            List {
                ForEach(workouts.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
                }) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        Text(workout.type)
                    }
                }
            }
        }
        .padding()
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

// Extension to generate all days in a given month
extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        var current = interval.start

        while current < interval.end {
            if let next = self.nextDate(after: current, matching: components, matchingPolicy: .nextTime) {
                dates.append(next)
                current = next
            } else {
                break
            }
        }

        return dates
    }
}
