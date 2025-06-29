//
// HomeView.swift
// WorkoutTracker
//
// Updated by Johannes Støen on 29/06/2025.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject private var store: WorkoutStore
    @StateObject   private var vm: HomeViewModel

    @State private var showAddWorkout = false
    private let gridColumns = [
        GridItem(.flexible()), GridItem(.flexible())
    ]
    @State private var chartRange = 7    // enten 7 eller 30 dager

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
        self._vm    = StateObject(wrappedValue: HomeViewModel(store: store))
    }

    var body: some View {
        ZStack {
            // Bakgrunnsgradient for hele view
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

                    // Metrics‐kort
                    Card {
                        HStack(spacing: 32) {
                            MetricView(icon: "square.stack.3d.up.fill",
                                       title: "Totalt sett",
                                       value: "\(vm.totalSets)")
                            MetricView(icon: "repeat",
                                       title: "Totalt reps",
                                       value: "\(vm.totalReps)")
                            MetricView(icon: "scalemass",
                                       title: "Totalt vekt",
                                       value: String(format: "%.1f kg", vm.totalWeight))
                        }
                    }

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
                            QuickActionButton(icon: "plus.circle", title: "Ny økt") {
                                showAddWorkout = true
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
                                        .shadow(color: Color(.black).opacity(0.05),
                                                radius: 2, x: 0, y: 1)
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
        // Modal for å legge til økt
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView(store: store)
        }
    }
}
