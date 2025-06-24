import SwiftUI

struct HomeView: View {
    // 1) ObservableObject som eier listen og tillater binding
    @ObservedObject private var store: WorkoutStore

    // 2) ViewModel for all readonly-logikk
    @StateObject private var vm: HomeViewModel

    @State private var showAddWorkout = false

    // 3) Lokalt grid-oppsett
    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    init(store: WorkoutStore) {
        // Init av ObservedObject
        self._store = ObservedObject(wrappedValue: store)
        // Init av StateObject
        self._vm = StateObject(wrappedValue: HomeViewModel(store: store))
    }

    var body: some View {
        ZStack {
            // Bakgrunnsgradient
            LinearGradient(
                colors: [Color.accentColor.opacity(0.4),
                         Color.accentColor.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 24)

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

                    // Metrics‐kort
                    Card {
                        HStack(spacing: 32) {
                            MetricView(
                                icon: "square.stack.3d.up.fill",
                                title: "Totalt sett",
                                value: "\(vm.totalSets)"
                            )
                            MetricView(
                                icon: "repeat",
                                title: "Totalt reps",
                                value: "\(vm.totalReps)"
                            )
                            MetricView(
                                icon: "scalemass",
                                title: "Totalt vekt",
                                value: String(format: "%.1f kg", vm.totalWeight)
                            )
                        }
                    }

                    // Mini‐graf
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Økter siste 7 dager")
                                .font(.headline)
                            MiniChart(
                                data: vm.last7days,
                                labels: vm.last7daysLabels
                            )
                            .frame(height: 120)
                        }
                    }

                    // Hurtigvalg‐grid
                    Card {
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            QuickActionButton(icon: "plus.circle", title: "Ny økt") {
                                showAddWorkout = true
                            }

                            NavigationLink {
                                // 4) Bruk binding mot store.workouts
                                WorkoutListView(workouts: $store.workouts)
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
                                    ForEach(vm.recentWorkouts) { workout in
                                        // Ditt kjente økt‐kort
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(workout.type)
                                                .font(.subheadline)
                                                .bold()
                                            Text(workout.date, style: .date)
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
        // 5) Modal for å legge til økt, binder også til store.workouts
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView(workouts: $store.workouts)
        }
    }
}
