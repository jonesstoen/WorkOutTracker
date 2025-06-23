//
//  MiniChart.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 23/06/2025.
//

import SwiftUI

struct MiniChart: View {
    let data: [Int]
    let labels: [String]

    private var maxVal: Int { data.max() ?? 1 }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                // Linjegraf
                Path { path in
                    for (i, val) in data.enumerated() {
                        let x = geo.size.width * CGFloat(i) / CGFloat(data.count - 1)
                        let y = geo.size.height * (1 - CGFloat(val) / CGFloat(maxVal))
                        if i == 0 { path.move(to: .init(x: x, y: y)) }
                        else     { path.addLine(to: .init(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )

                // Markørpunkter og verditekster
                ForEach(Array(data.enumerated()), id: \.offset) { index, val in
                    let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                    let y = geo.size.height * (1 - CGFloat(val) / CGFloat(maxVal))
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                    if val > 0 {
                        Text("\(val)")
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .position(x: x, y: y - 10)
                    }
                }
            }
            .frame(height: 60)

            // X-akse etiketter
            HStack {
                ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}


