//
//  RoundedCorner.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 23/06/2025.
//


import SwiftUI

/// Klipper et rektangel slik at bare de to nederste hjørnene rundes av.
struct RoundedCorner: Shape {
    var bottomLeft: CGFloat = 0
    var bottomRight: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start øverst til venstre
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        // Øverste kant til øverst høyre
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        // Høyre kant ned til starten av nederste høyre hjørne
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        // Bunnhøyre arc
        path.addArc(
            center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
            radius: bottomRight,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        // Nederste kant til starten av nederste venstre hjørne
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        // Bunnvenstre arc
        path.addArc(
            center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
            radius: bottomLeft,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        // Opp venstre kant tilbake til start
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))

        return path
    }
}
