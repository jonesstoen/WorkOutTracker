import SwiftUI

struct HomeView: View {
    @ObservedObject private var store: WorkoutStore
    @StateObject private var vm: HomeViewModel

    // @State private var showLiveWorkout = false
    @State private var showManualAdd = false

    private let gridColumns = [
        GridItem(.flexible()), GridItem(.flexible())
    ]

    @State private var chartRange = 7    // enten 7 eller 30 dager

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
        self._vm    = StateObject(wrappedValue: HomeViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            ZStack {
            // Bakgrunnsgradient for hele view
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.4),
                    Color.accentColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 24)

                    // Logo øverst
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                        .padding(.top, 16)

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

                    

                    // Graf‐kort med %-indikator og gradient‐bakgrunn
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            // Tittel + segment‐picker
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

                            // %-endring
                            if let change = vm.percentChange(forLast: chartRange) {
                                let arrow = change >= 0 ? "arrow.up" : "arrow.down"
                                let color = change >= 0 ? Color.green : Color.red
                                HStack(spacing: 4) {
                                    Image(systemName: arrow)
                                        .foregroundColor(color)
                                    Text("\(abs(Int(change))) % fra forrige periode")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Beregn gradient‐bakgrunn basert på trend
                            let trendColor = (vm.percentChange(forLast: chartRange) ?? 0) >= 0
                            ? Color.green : Color.red

                            let bgGrad = LinearGradient(
                                gradient: Gradient(colors: [
                                    trendColor.opacity(0.3),
                                    trendColor.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )

                            // Tegn graf
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

                    // Hurtigvalg‐grid
                    Card {
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            // Primær: Live økt (egen skjerm)
                            NavigationLink {
                                LiveWorkoutSetupView(store: store)
                            } label: {
                                QuickActionLabel(icon: "play.circle.fill", title: "Start økt")
                            }

                            // Sekundær: Manuell logging
                            QuickActionButton(icon: "plus.circle", title: "Legg til manuelt") {
                                showManualAdd = true
                            }

                            NavigationLink {
                                WorkoutListView(store: store)
                            } label: {
                                QuickActionLabel(
                                    icon: "clock.arrow.circlepath",
                                    title: "Historikk"
                                )
                            }

                            QuickActionButton(icon: "calendar", title: "Kalender") { }
                            QuickActionButton(icon: "chart.bar", title: "Statistikk") { }
                        }
                    }

                    // Siste økter‐kort
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Siste økter")
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(vm.recentWorkouts) { w in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(w.type)
                                                .font(.subheadline)
                                                .bold()
                                            Text(w.date, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(10)
                                        .shadow(
                                            color: Color(.black).opacity(0.05),
                                            radius: 2, x: 0, y: 1
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
            }
            // Manual add flow (existing form)
            .sheet(isPresented: $showManualAdd) {
                AddWorkoutView(store: store)
            }
        }
    }



/// Setup screen shown before starting a live workout.
/// Keeps LiveWorkoutView focused on logging during the workout.
struct LiveWorkoutSetupView: View {
    @ObservedObject private var store: WorkoutStore

    @State private var type: String = ""
    @State private var category: WorkoutCategory = .strength

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
    }

    var body: some View {
        Form {
            Section("Type og kategori") {
                TextField("F.eks. Push / Bein / Øktnavn (valgfritt)", text: $type)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)

                Picker("Kategori", selection: $category) {
                    ForEach(WorkoutCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.iconName).tag(cat)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section {
                NavigationLink {
                    LiveWorkoutView(
                        store: store,
                        initialType: type.trimmingCharacters(in: .whitespacesAndNewlines),
                        initialCategory: category
                    )
                } label: {
                    Label("Start økt", systemImage: "play.circle.fill")
                }
            } footer: {
                Text("Du kan endre dette senere underveis, men det er ofte enklere å sette det nå.")
            }
        }
        .navigationTitle("Start økt")
        .navigationBarTitleDisplayMode(.inline)
    }
}
