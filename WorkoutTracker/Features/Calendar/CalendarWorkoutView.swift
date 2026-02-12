import SwiftUI

struct CalendarWorkoutView: View {
    @ObservedObject private var store: WorkoutStore
    @StateObject private var vm: CalendarViewModel

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
        self._vm    = StateObject(wrappedValue: CalendarViewModel(store: store))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Navigasjon i måned med animasjon
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            vm.changeMonth(by: -1)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(vm.currentMonth.formatted(.dateTime.year().month()))
                        .font(.title2).bold()

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            vm.changeMonth(by: 1)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                let weekdaySymbols = Calendar.current.shortStandaloneWeekdaySymbols

                // Ukedager + dager i måneden
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7)) {
                    // Ukedager
                    ForEach(weekdaySymbols.indices, id: \.self) { idx in
                        Text(weekdaySymbols[idx])
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    // Datoer
                    ForEach(vm.daysInMonth.indices, id: \.self) { index in
                        if let date = vm.daysInMonth[index] {
                            ZStack {
                                // Marker valgt dag
                                if Calendar.current.isDate(date, inSameDayAs: vm.selectedDate) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.blue)
                                        .frame(height: 36)
                                }
                                // Marker dag med økt
                                else if vm.hasWorkout(on: date) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.green.opacity(0.8))
                                        .frame(height: 36)
                                }

                                Text("\(Calendar.current.component(.day, from: date))")
                                    .frame(maxWidth: .infinity, minHeight: 36)
                                    .foregroundColor(
                                        Calendar.current.isDate(date, inSameDayAs: vm.selectedDate)
                                        ? .white
                                        : .primary
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            vm.selectedDate = date
                                        }
                                    }
                            }
                        } else {
                            Color.clear.frame(height: 36)
                        }
                    }
                }
                .padding(.horizontal)

                Divider().padding(.top, 4)

                // Økter for valgt dag i eget «kort»
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Økter den \(vm.selectedDate.formatted(.dateTime.day().month()))"))
                        .font(.headline)

                    if vm.workoutsForSelectedDate.isEmpty {
                        // Placeholder når ingen økter denne dagen
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text(LocalizedStringKey("Ingen økter denne dagen"))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                    } else {
                        ForEach(vm.workoutsForSelectedDate) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                HStack {
                                    Image(systemName: workout.category.iconName)
                                        .foregroundColor(workout.category.color)
                                    Text(workout.type)
                                        .font(.subheadline)
                                        .bold()
                                    Spacer()
                                    Text(workout.date, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)

            }
            .padding(.bottom, 24)
        }
    }
}
