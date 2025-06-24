//
//  IdentifiableInt.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 23/06/2025.
//
import SwiftUI

struct IdentifiableInt: Identifiable {
    let id = UUID()
    let value: Int
}
