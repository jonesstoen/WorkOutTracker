import SwiftUI

/// Completed sets per muscle group this week, with the four-week average as a marker.
struct MuscleVolumeCard: View {
    let volumes: [MuscleVolume]

    /// Shared scale so the bars are comparable across groups
    private var scaleMax: Double {
        max(volumes.map { max(Double($0.thisWeek), $0.average) }.max() ?? 1, 1)
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Volum denne uken")
                        .font(.headline)
                    Spacer()
                    Text("sett per muskelgruppe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    ForEach(volumes) { volume in
                        row(volume)
                    }
                }

                HStack(spacing: 6) {
                    Capsule()
                        .fill(Color.primary.opacity(0.6))
                        .frame(width: 2, height: 10)
                    Text("Snitt siste 4 uker")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func row(_ volume: MuscleVolume) -> some View {
        let barColor: Color = volume.isNeglected ? .orange : .accentColor
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(volume.muscle.rawValue)
                    .font(.subheadline.weight(.medium))
                if volume.isNeglected {
                    Text("Forsømt?")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
                Spacer()
                Text("\(volume.thisWeek)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(volume.isNeglected ? .orange : .primary)
            }

            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(barColor)
                        .frame(width: width * Double(volume.thisWeek) / scaleMax)
                    if volume.average > 0 {
                        Capsule()
                            .fill(Color.primary.opacity(0.6))
                            .frame(width: 2, height: 14)
                            .offset(x: min(width * volume.average / scaleMax, width - 2))
                    }
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(volume.muscle.rawValue): \(volume.thisWeek) sett denne uken, snitt \(volume.average.kgLabel)"
            + (volume.isNeglected ? ", forsømt" : "")
        )
    }
}
