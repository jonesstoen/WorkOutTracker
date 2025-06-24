// MiniChart.swift
// WorkoutTracker
//
// Bruker SwiftUI Charts for et mer native og rikt diagram
// Krever iOS 16+

import SwiftUI
import Charts

struct MiniChart: View {
    let data: [Int]
    let labels: [String]

    private var maxVal: Int { max(data.max() ?? 1, 1) }

    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, val in
                LineMark(
                    x: .value("Dag", labels[index]),
                    y: .value("Økter", val)
                )
                .interpolationMethod(.catmullRom)       // glatt kurve
                .foregroundStyle(Gradient(colors: [.green, .blue]))
                .lineStyle(StrokeStyle(lineWidth: 2))
                PointMark(
                    x: .value("Dag", labels[index]),
                    y: .value("Økter", val)
                )
                .symbolSize(60)
                .foregroundStyle(.blue)
            }
        }
        .chartYScale(domain: 0...Double(maxVal))
        .chartXAxis {
            AxisMarks(values: labels) { value in
                AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                AxisTick()
                AxisValueLabel()               // bruker labels fra x-verdiene
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, maxVal]) { value in
                AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                AxisValueLabel()
            }
        }
        .frame(height: 120)
    }
}
