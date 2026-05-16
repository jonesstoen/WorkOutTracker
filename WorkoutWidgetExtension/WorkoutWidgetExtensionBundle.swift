//
//  WorkoutWidgetExtensionBundle.swift
//  WorkoutWidgetExtension
//
//  Created by Johannes Støen on 15/05/2026.
//

import WidgetKit
import SwiftUI

@main
struct WorkoutWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        WorkoutWidgetExtension()
        WorkoutWidgetExtensionControl()
        WorkoutWidgetExtensionLiveActivity()
    }
}
