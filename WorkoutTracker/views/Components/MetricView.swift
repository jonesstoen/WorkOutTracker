//
//  MetricView.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 23/06/2025.
//


import SwiftUI

struct MetricView: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.title3)
                .bold()
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
