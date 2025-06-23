import SwiftUI



struct HomeView: View {
    @Binding var workouts: [Workout]
    @State private var showAddWorkout = false
    
    // Totalt antall sett
        private var totalSets: Int {
            workouts.reduce(0) { sum, workout in
                sum + workout.exercises.reduce(0) { $0 + $1.sets }
            }
        }
    // Totalt antall reps (sets * reps)
        private var totalReps: Int {
            workouts.reduce(0) { sum, workout in
                sum + workout.exercises.reduce(0) { $0 + ($1.sets * $1.reps) }
            }
        }
    // Total vekt løftet (sets * reps * weight)
        private var totalWeight: Double {
            workouts.reduce(0) { sum, workout in
                sum + workout.exercises.reduce(0) {
                    $0 + (Double($1.sets * $1.reps) * $1.weight)
                }
            }
        }
    private var greeting: String {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 5..<12:   return "God morgen"
            case 12..<17:  return "God dag"
            case 17..<22:  return "God kveld"
            default:       return "God natt"
            }
        }

    // Beregn antall økter denne uken
    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        return workouts.filter {
            calendar.component(.weekOfYear, from: $0.date) == currentWeek
        }.count
    }

    // Data for mini-graf: antall økter de siste 7 dagene
    private var last7days: [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return workouts.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
        }
        .reversed()
    }

    // Etiketter for x-aksen (kort ukedag, NB-format)
    private var last7daysLabels: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nb_NO")
        formatter.dateFormat = "E"
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return formatter.string(from: day)
        }
        .reversed()
    }

    // Hent de 5 siste øktene
    private var recentWorkouts: [Workout] {
        Array(workouts.sorted { $0.date > $1.date }.prefix(5))
    }

    // Grid-oppsett for hurtigvalg (2 kolonner)
    private let gridColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                                           Text("\(greeting), Johannes!")
                                               .font(.largeTitle)
                                               .bold()
                                           Text(Date(), style: .date)
                                               .font(.subheadline)
                                               .foregroundColor(.secondary)
                                       }
                                       .frame(maxWidth: .infinity, alignment: .leading)
                                       .padding(.horizontal, 16)
                                       .padding(.top, 16)
                    
                    
                    Card {
                        HStack(spacing: 32) {
                            MetricView(
                                icon: "square.stack.3d.up.fill",
                                title: "Totalt sett",
                                value: "\(totalSets)")
                            MetricView(
                                icon: "repeat",
                                title: "Totalt reps",
                                value: "\(totalReps)")
                            MetricView(
                                icon: "scalemass",
                                title: "Totalt vekt",
                                value: String(format: "%.1f kg", totalWeight))
                        }
                    }

                

                    // Mini-graf over siste 7 dager
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Økter siste 7 dager")
                                .font(.headline)
                            MiniChart(data: last7days, labels: last7daysLabels)
                                .frame(height: 80)
                        }
                    }

                    // Hurtigvalg som grid
                    Card {
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            QuickActionButton(icon: "plus.circle", title: "Ny økt") {
                                showAddWorkout = true
                            }
                            NavigationLink {
                                WorkoutListView(workouts: $workouts)
                            } label: {
                                QuickActionLabel(icon: "clock.arrow.circlepath", title: "Historikk")
                            }
                            QuickActionButton(icon: "calendar", title: "Kalender") {
                                // TODO: Naviger til kalender
                            }
                            QuickActionButton(icon: "chart.bar", title: "Statistikk") {
                                // TODO: Naviger til statistikk
                            }
                        }
                    }

                    // Siste økter
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

                }
                .padding(.horizontal, 16)    
                .padding(.top, 16)
            }
        
            
            
            .sheet(isPresented: $showAddWorkout) {
                AddWorkoutView(workouts: $workouts)
            }
        }
    }
}


