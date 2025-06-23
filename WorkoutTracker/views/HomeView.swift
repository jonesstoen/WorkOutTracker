import SwiftUI

/// A generic card view for grouping content
struct Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color(.black).opacity(0.1), radius: 4, x: 0, y: 2)
    }
}


struct HomeView: View {
    @Binding var workouts: [Workout]
    @State private var showAddWorkout = false

    // Beregn antall økter denne uken
    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        return workouts.filter {
            calendar.component(.weekOfYear, from: $0.date) == currentWeek
        }.count
    }

    // Hent de 5 siste øktene
    private var recentWorkouts: [Workout] {
        Array(workouts.sorted { $0.date > $1.date }.prefix(5))
    }

    // Grid-oppsett for hurtigvalg (2 kolonner)
    private let gridColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: Progress-kort
                Card {
                    HStack(spacing: 16) {
                        ProgressRing(progress: Double(workoutsThisWeek) / 5.0)
                            .frame(width: 60, height: 60)
                            .animation(.easeInOut, value: workoutsThisWeek)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Økter denne uke")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(workoutsThisWeek)/5")
                                .font(.title2)
                                .bold()
                        }
                        Spacer()
                    }
                }

                // MARK: Hurtigvalg som grid
                Card {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        // Ny økt
                        QuickActionButton(icon: "plus.circle", title: "Ny økt") {
                            showAddWorkout = true
                        }
                        // Historikk
                        NavigationLink {
                            WorkoutListView(workouts: $workouts)
                        } label: {
                            QuickActionLabel(icon: "clock.arrow.circlepath", title: "Historikk")
                        }
                        // Kalender
                        QuickActionButton(icon: "calendar", title: "Kalender") {
                            // TODO: Naviger til kalender
                        }
                        // Statistikk
                        QuickActionButton(icon: "chart.bar", title: "Statistikk") {
                            // TODO: Naviger til statistikk
                        }
                    }
                }

                // MARK: Siste økter
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Siste økter")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(recentWorkouts) { workout in
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
                                    .shadow(color: Color(.black).opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                    }
                }

                // MARK: Motivasjonskort
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Streak: 3 dager på rad 💪")
                            .font(.subheadline)
                        Text("“Ikke gi opp – innsatsen teller!”")
                            .font(.caption)
                            .italic()
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddWorkout = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Legg til ny økt")
            }
        }
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView(workouts: $workouts)
        }
    }
}


// MARK: Hurtigknapp-komponent
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color(.black).opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: Progress-ring-komponent
struct ProgressRing: View {
    var progress: Double // 0.0–1.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .opacity(0.3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: Hurtigvalg label-komponent for NavigationLink
struct QuickActionLabel: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color(.black).opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
