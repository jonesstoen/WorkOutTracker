//
// MiniChart.swift
// WorkoutTracker
//
// Updated by Johannes Støen on 29/06/2025.
//

import SwiftUI
import Charts

struct MiniChart: View {
    let data: [Int]
    let labels: [String]
    var lineColor: Color = .accentColor
    var pointColor: Color = .accentColor
    var backgroundGradient: LinearGradient? = nil

    @State private var selectedIndex: Int? = nil

    private var maxVal: Int { max(data.max() ?? 1, 1) }

    var body: some View {
        ZStack {
            // 1) Valgfri gradient bak grafen
            if let bg = backgroundGradient {
                bg
            }

            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { idx, val in
                    // Linja
                    LineMark(
                        x: .value("Dag", labels[idx]),
                        y: .value("Økter", val)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    // Punktet + annotation
                    PointMark(
                        x: .value("Dag", labels[idx]),
                        y: .value("Økter", val)
                    )
                    .symbolSize(60)
                    .foregroundStyle(pointColor)
                    .annotation(position: .top) {
                        if selectedIndex == idx {
                            Text("\(val)")
                                .font(.caption)
                                .padding(6)
                                .background(.regularMaterial)
                                .cornerRadius(8)
                                .shadow(radius: 3)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...Double(maxVal))
            .chartXAxis {
                AxisMarks(values: labels) { _ in
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, maxVal]) { _ in
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.2))
                    AxisValueLabel()
                }
            }
            // 2) Overlay for å fange berøring/drag i plot-området
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let origin = geo[proxy.plotAreaFrame].origin.x
                                    let xPos = value.location.x - origin
                                    if xPos >= 0 {
                                        if let dayLabel: String = proxy.value(atX: xPos) {
                                            if let i = labels.firstIndex(of: dayLabel) {
                                                selectedIndex = i
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    // fjern bobla etter en liten forsinkelse
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        selectedIndex = nil
                                    }
                                }
                        )
                }
            }
        }
    }
}
