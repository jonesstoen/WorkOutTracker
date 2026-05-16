import SwiftUI

struct CalendarWorkoutView: View {
    @ObservedObject private var store: WorkoutStore
    @StateObject private var vm: CalendarViewModel

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
        self._vm    = StateObject(wrappedValue: CalendarViewModel(store: store))
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(vm.currentMonth, equalTo: Date(), toGranularity: .month)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                monthHeader
                calendarGrid
                Divider().padding(.top, 4)
                dayPanel
            }
            .padding(.bottom, 24)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isCurrentMonth {
                    Button("I dag") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            vm.goToToday()
                        }
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
        }
    }

    // MARK: - Month header

    private var monthHeader: some View {
        HStack {
            navButton(direction: -1)
            Spacer()
            Text(vm.currentMonth.formatted(.dateTime.year().month()))
                .font(.title2).bold()
            Spacer()
            navButton(direction: 1)
        }
        .padding(.horizontal)
    }

    private func navButton(direction: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                vm.changeMonth(by: direction)
            }
        } label: {
            Image(systemName: direction < 0 ? "chevron.left" : "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 34, height: 34)
                .background(Color(.secondarySystemBackground))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calendar grid

    private var calendarGrid: some View {
        let calendar = Calendar.current
        let weekdaySymbols: [String] = {
            var symbols = calendar.shortStandaloneWeekdaySymbols
            let shift = calendar.firstWeekday - 1
            if shift > 0 {
                symbols = Array(symbols[shift...] + symbols[..<shift])
            }
            return symbols
        }()

        return LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7), spacing: 4) {
            ForEach(weekdaySymbols.indices, id: \.self) { idx in
                Text(weekdaySymbols[idx])
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }

            ForEach(vm.daysInMonth.indices, id: \.self) { index in
                if let date = vm.daysInMonth[index] {
                    dayCell(date: date)
                } else {
                    Color.clear.frame(minHeight: 46)
                }
            }
        }
        .padding(.horizontal)
    }

    private func dayCell(date: Date) -> some View {
        let isToday    = Calendar.current.isDateInToday(date)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: vm.selectedDate)
        let colors     = vm.workoutColors(on: date)

        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(width: 34, height: 34)
                if isToday && !isSelected {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 1.5)
                        .frame(width: 34, height: 34)
                }
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 15, weight: isToday ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
            }

            // Category-colored dots (up to 3, one per workout)
            HStack(spacing: 3) {
                ForEach(colors.indices, id: \.self) { i in
                    Circle()
                        .fill(colors[i])
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.selectedDate = date
            }
        }
    }

    // MARK: - Day panel

    private var dayPanel: some View {
        let formatter: DateFormatter = {
            let df = DateFormatter()
            df.locale = Locale.current
            df.dateFormat = "d. MMM yyyy"
            return df
        }()

        return VStack(alignment: .leading, spacing: 10) {
            Text("Økter \(formatter.string(from: vm.selectedDate))")
                .font(.headline)
                .padding(.horizontal, 4)

            if vm.workoutsForSelectedDate.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.run.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Ingen økter denne dagen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 90)
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.workoutsForSelectedDate) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            workoutRow(workout)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                vm.delete(workout)
                            } label: {
                                Label("Slett", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private func workoutRow(_ workout: Workout) -> some View {
        let title = workout.type.trimmingCharacters(in: .whitespacesAndNewlines)
        let sets   = workout.exercises.reduce(0) { $0 + $1.sets.count }
        let volume = workout.exercises.reduce(0.0) { $0 + $1.totalVolume }

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(workout.category.color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: workout.category.iconName)
                    .font(.body)
                    .foregroundColor(workout.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title.isEmpty ? workout.category.rawValue : title.capitalized)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(statsText(sets: sets, volume: volume, duration: workout.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
    }

    // MARK: - Helpers

    private func statsText(sets: Int, volume: Double, duration: TimeInterval) -> String {
        var parts: [String] = []
        if duration > 0 { parts.append(durationString(duration)) }
        if sets > 0     { parts.append("\(sets) sett") }
        if volume > 0   { parts.append("\(Int(volume)) kg") }
        return parts.isEmpty ? "Ingen øvelser" : parts.joined(separator: " · ")
    }

    private func durationString(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600, m = (s % 3600) / 60
        return h > 0 ? "\(h)t \(m)m" : "\(m) min"
    }
}
