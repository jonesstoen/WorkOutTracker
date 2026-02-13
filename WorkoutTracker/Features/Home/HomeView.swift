import SwiftUI

struct HomeView: View {
    @ObservedObject private var store: WorkoutStore
    @StateObject private var vm: HomeViewModel

    @State private var showManualAdd = false
    @State private var showSettings = false
    @State private var chartRange = 7
    @AppStorage("userName") private var userName: String = "Johannes"

    @EnvironmentObject private var nav: HomeNavigationCoordinator
    @State private var path = NavigationPath()

    private let gridColumns = [
        GridItem(.flexible()), GridItem(.flexible())
    ]

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
                // 1) Softere bakgrunn enn før
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

                        // Hilsen
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(vm.greeting), Johannes!")
                                .font(.largeTitle).bold()
                                .foregroundColor(.white)
                            Text(vm.dateString)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 24)

                        // 2) Stor “Start økt” som primær CTA
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

                        // Chart / “Økter siste X dager”
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Økter siste \(chartRange) dager")
                                        .font(.headline)
                                    Spacer()
                                    Picker("", selection: $chartRange) {
                                        Text("7 dager").tag(7)
                                        Text("30 dager").tag(30)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 200)
                                }

                                // %-endring (bare hvis det finnes data i perioden)
                                if hasWorkoutsInRange, let change = vm.percentChange(forLast: chartRange) {
                                    let arrow = change >= 0 ? "arrow.up" : "arrow.down"
                                    let color = change >= 0 ? Color.green : Color.red
                                    HStack(spacing: 6) {
                                        Image(systemName: arrow).foregroundColor(color)
                                        Text("\(abs(Int(change))) % fra forrige periode")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                // 3) Tom-state i stedet for flat null-graf
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

                        // Hurtigvalg-grid (uten “Start økt” her, siden den er primær CTA over)
                        Card {
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                QuickActionButton(icon: "plus.circle", title: "Legg til manuelt") {
                                    showManualAdd = true
                                }

                                NavigationLink {
                                    WorkoutListView(store: store)
                                } label: {
                                    QuickActionLabel(icon: "clock.arrow.circlepath", title: "Historikk")
                                }
                                NavigationLink {
                                    CalendarWorkoutView(store: store)
                                } label: {
                                    QuickActionLabel(icon: "calendar", title: "Kalender")
                                }
                            }
                        }

                        // Siste økter (litt mer “treningsapp”-følelse: ikon + litt ekstra info)
                        Card {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Siste økter")
                                    .font(.headline)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(vm.recentWorkouts) { w in
                                            let sets = w.exercises.reduce(0) { $0 + $1.sets }
                                            let volume = w.exercises.reduce(0.0) { acc, ex in
                                                acc + (Double(ex.sets * ex.reps) * ex.weight)
                                            }

                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: w.category.iconName)
                                                        .foregroundColor(w.category.color)
                                                    Text(w.type)
                                                        .font(.subheadline)
                                                        .bold()
                                                        .lineLimit(1)
                                                }

                                                Text(w.date, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)

                                                Text("\(sets) sett · \(String(format: "%.0f", volume)) kg")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding()
                                            .frame(width: 190, alignment: .leading)
                                            .background(Color(.systemBackground))
                                            .cornerRadius(12)
                                            .shadow(color: Color(.black).opacity(0.06), radius: 3, x: 0, y: 2)
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
                        // TODO: Åpne meny senere
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
            }
            .sheet(isPresented: $showManualAdd) {
                AddWorkoutView(store: store)
            }
            .sheet(isPresented: $showSettings) {
                UserSettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.medium)
                            .foregroundStyle(.white)
                    }
                }
            }
            .navigationDestination(for: HomeNavigationCoordinator.Route.self) { route in
                switch route {
                case .liveWorkout:
                    LiveWorkoutView(store: store)
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
}

