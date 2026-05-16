import SwiftUI

struct HomeView: View {
    @ObservedObject private var store: WorkoutStore
    @StateObject private var vm: HomeViewModel

    @State private var showManualAdd = false
    @State private var showSettings = false
    @State private var chartRange = 7
    @AppStorage("userName")    private var userName: String = "Johannes"
    @AppStorage("weeklyGoal") private var weeklyGoal: Int = 3

    @EnvironmentObject private var nav: HomeNavigationCoordinator
    @State private var path = NavigationPath()

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
        self._vm    = StateObject(wrappedValue: HomeViewModel(store: store))
    }

    private var hasWorkoutsInRange: Bool {
        vm.counts(forLast: chartRange).contains { $0 > 0 }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.22),
                        Color.accentColor.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 18)

                        // Header — greeting + streak
                        VStack(alignment: .leading, spacing: 8) {
                            Text(userName.isEmpty ? vm.greeting : "\(vm.greeting), \(userName)!")
                                .font(.largeTitle).bold()
                                .foregroundColor(.white)

                            HStack(spacing: 10) {
                                Text(vm.dateString)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))

                                if vm.currentStreak > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(.orange)
                                        Text(vm.currentStreak == 1
                                             ? "1 dag streak"
                                             : "\(vm.currentStreak) dager streak")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.15))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                        // Primary CTA — Start økt
                        NavigationLink {
                            LiveWorkoutSetupView(store: store)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .imageScale(.large)
                                Text("Start økt")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.95),
                                        Color.accentColor.opacity(0.65)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)

                        // Secondary CTA — Legg til manuelt
                        Button { showManualAdd = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                Text("Legg til manuelt")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                        // Chart
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Aktivitet")
                                        .font(.headline)
                                    Spacer()
                                    Picker("", selection: $chartRange) {
                                        Text("7 dager").tag(7)
                                        Text("30 dager").tag(30)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 160)
                                }

                                if hasWorkoutsInRange, let change = vm.percentChange(forLast: chartRange) {
                                    let arrow = change >= 0 ? "arrow.up" : "arrow.down"
                                    let color = change >= 0 ? Color.green : Color.red
                                    HStack(spacing: 6) {
                                        Image(systemName: arrow).foregroundColor(color)
                                        Text("\(abs(Int(change))) % fra forrige periode")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if !hasWorkoutsInRange {
                                    ContentUnavailableView(
                                        "Ingen økter denne perioden",
                                        systemImage: "chart.line.downtrend.xyaxis",
                                        description: Text("Start en økt for å komme i gang.")
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                } else {
                                    let trendColor = (vm.percentChange(forLast: chartRange) ?? 0) >= 0
                                        ? Color.green : Color.red
                                    let bgGrad = LinearGradient(
                                        gradient: Gradient(colors: [
                                            trendColor.opacity(0.28),
                                            trendColor.opacity(0.06)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    if chartRange == 7 {
                                        MiniChart(
                                            data: vm.counts(forLast: 7),
                                            labels: vm.labels(forLast: 7),
                                            lineColor: trendColor,
                                            pointColor: trendColor,
                                            backgroundGradient: bgGrad
                                        )
                                        .frame(height: 120)
                                    } else {
                                        let weekly = vm.weeklyCounts(forLast: 30)
                                        MiniChart(
                                            data: weekly.counts,
                                            labels: weekly.labels,
                                            lineColor: trendColor,
                                            pointColor: trendColor,
                                            backgroundGradient: bgGrad
                                        )
                                        .frame(height: 120)
                                    }
                                }
                            }
                        }

                        // Weekly goal
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Ukentlig mål")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(vm.workoutsThisWeek) av \(weeklyGoal)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                ProgressView(
                                    value: Double(min(vm.workoutsThisWeek, weeklyGoal)),
                                    total: Double(weeklyGoal)
                                )
                                .tint(vm.workoutsThisWeek >= weeklyGoal ? .green : .accentColor)

                                Text(vm.workoutsThisWeek >= weeklyGoal
                                     ? "Ukemålet nådd! Bra jobba."
                                     : "\(weeklyGoal - vm.workoutsThisWeek) økt\(weeklyGoal - vm.workoutsThisWeek == 1 ? "" : "er") igjen denne uken")
                                    .font(.caption)
                                    .foregroundStyle(vm.workoutsThisWeek >= weeklyGoal ? .green : .secondary)
                            }
                        }

                        // Recent workouts
                        if !vm.recentWorkouts.isEmpty {
                            Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Siste økter")
                                        .font(.headline)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(vm.recentWorkouts) { w in
                                                recentWorkoutCard(w)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Spacer().frame(height: 12)
                    }
                    .padding(.bottom, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                    } label: {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Meny")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.medium)
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showManualAdd) {
                AddWorkoutView(store: store)
            }
            .sheet(isPresented: $showSettings) {
                UserSettingsView()
            }
            .navigationDestination(for: HomeNavigationCoordinator.Route.self) { route in
                switch route {
                case .liveWorkout:
                    LiveWorkoutView(store: store, restoreIfAvailable: true)
                }
            }
        }
        .onChange(of: nav.resumeLiveRequested) { requested in
            if requested {
                nav.resumeLiveRequested = false
                path.append(HomeNavigationCoordinator.Route.liveWorkout)
            }
        }
    }

    // MARK: - Recent workout card

    private func recentWorkoutCard(_ w: Workout) -> some View {
        let title = w.type.trimmingCharacters(in: .whitespacesAndNewlines)
        let sets = w.exercises.reduce(0) { $0 + $1.sets.count }
        let volume = w.exercises.reduce(0.0) { $0 + $1.totalVolume }

        return NavigationLink(destination: WorkoutDetailView(workout: w)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(w.category.color.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: w.category.iconName)
                            .font(.system(size: 14))
                            .foregroundColor(w.category.color)
                    }
                    Text(title.isEmpty ? w.category.rawValue : title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }

                Text(w.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    if w.duration > 0 {
                        Label(durationString(w.duration), systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if sets > 0 {
                        let volumeText = volume > 0 ? " · \(Int(volume)) kg" : ""
                        Label("\(sets) sett\(volumeText)", systemImage: "dumbbell")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(14)
            .frame(width: 200, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func durationString(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600, m = (s % 3600) / 60
        if h > 0 { return "\(h)t \(m)m" }
        return "\(m) min"
    }
}
