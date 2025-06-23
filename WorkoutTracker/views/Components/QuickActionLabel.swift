//
//  QuickActionLabel.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 23/06/2025.
//


import SwiftUI

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
