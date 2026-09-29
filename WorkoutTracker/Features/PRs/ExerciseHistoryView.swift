import SwiftUI
import Charts

struct ExerciseHistoryView: View {
    let exerciseName: String
    let history: [ExerciseDataPoint]
    let advice: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if history.count >= 2 {
                    chartCard
                }
                if let advice {
                    adviceCard(advice)
                }
                historyCard
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Chart

    /// Only bodyweight sets logged: track reps instead of estimated 1RM
    private var isBodyweight: Bool { history.allSatisfy { $0.weight == 0 } }

    private func chartValue(_ point: ExerciseDataPoint) -> Double {
        isBodyweight ? Double(point.reps) : point.e1RM
    }

    private func valueLabel(_ value: Double) -> String {
        isBodyweight ? "\(Int(value)) reps" : "\(Int(value.rounded())) kg"
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Utvikling")
                        .font(.headline)
                    Text(isBodyweight ? "Flest reps per økt" : "Estimert 1RM over tid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let best = history.max(by: { chartValue($0) < chartValue($1) }) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(isBodyweight ? "Rekord" : "Beste 1RM")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(valueLabel(chartValue(best)))
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }

            Chart(history) { point in
                AreaMark(
                    x: .value("Dato", point.date),
                    y: .value("Verdi", chartValue(point))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.25), Color.accentColor.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                LineMark(
                    x: .value("Dato", point.date),
                    y: .value("Verdi", chartValue(point))
                )
                .foregroundStyle(Color.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                PointMark(
                    x: .value("Dato", point.date),
                    y: .value("Verdi", chartValue(point))
                )
                .foregroundStyle(Color.accentColor)
                .symbolSize(40)
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine().foregroundStyle(Color(.separator).opacity(0.4))
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Color(.separator).opacity(0.4))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(valueLabel(v)).font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Progression advice

    private func adviceCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.up.forward.circle.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tid for progressiv overbelastning")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Session history

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Historikk")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            if history.isEmpty {
                Text("Ingen logger enda.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                ForEach(Array(history.reversed().enumerated()), id: \.element.id) { idx, point in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(point.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline.weight(.medium))
                            Text(point.weight > 0 ? "\(point.weight.kgLabel) kg × \(point.reps) reps" : "Kroppsvekt × \(point.reps) reps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(isBodyweight ? "Reps" : "Est. 1RM")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(valueLabel(chartValue(point)))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(idx == 0 ? Color.accentColor : .primary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if idx < history.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
