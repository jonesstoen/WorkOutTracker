//
//  Card.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 23/06/2025.
//


import SwiftUI

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
