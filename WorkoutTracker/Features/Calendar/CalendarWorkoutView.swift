import SwiftUI

struct CalendarWorkoutView: View {
    // Butikken for å kunne legge til/slette økter
    @ObservedObject private var store: WorkoutStore
    // ViewModel for all logikk
    @StateObject private var vm: CalendarViewModel

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
        self._vm    = StateObject(wrappedValue: CalendarViewModel(store: store))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Navigasjon i måned
                HStack {
                    Button { vm.changeMonth(by: -1) } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(vm.currentMonth.formatted(.dateTime.year().month()))
                        .font(.title2).bold()
                    Spacer()
                    Button { vm.changeMonth(by: 1) } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                
                let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

                // Ukedager + dager
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7)) {
                  ForEach(weekdaySymbols.indices, id: \.self) { idx in
                    Text(weekdaySymbols[idx])
                      .fontWeight(.semibold)
                      .foregroundColor(.secondary)
                      .frame(maxWidth: .infinity)  // for jevn fordeling
                  }

                    ForEach(vm.daysInMonth.indices, id: \.self) { index in
                        if let date = vm.daysInMonth[index] {
                            ZStack {
                                // Marker valgt dag
                                if Calendar.current.isDate(date, inSameDayAs: vm.selectedDate) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.blue)
                                        .frame(height: 36)
                                }
                                // Marker økt-dag
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
                                        vm.selectedDate = date
                                    }
                            }
                        } else {
                            Color.clear.frame(height: 36)
                        }
                    }
                }
                .padding(.horizontal)

                Divider().padding(.top, 4)

                // Øktene for valgt dag
                VStack(alignment: .leading) {
                    Text("Økter den \(vm.selectedDate.formatted(.dateTime.day().month()))")
                        .font(.headline)
                        .padding(.leading)

                    ForEach(vm.workoutsForSelectedDate) { workout in
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
}
