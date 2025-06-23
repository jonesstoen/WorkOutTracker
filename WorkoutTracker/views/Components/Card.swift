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
        .padding(20)
        .background(.ultraThinMaterial)   // ← dynamisk, lys/mørk modus
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 4)
    }
}
