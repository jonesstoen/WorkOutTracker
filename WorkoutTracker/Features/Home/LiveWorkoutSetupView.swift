//
//  LiveWorkoutSetupView.swift
//  WorkoutTracker
//
//  Created by Johannes Støen on 12/02/2026.
//


import SwiftUI

/// Setup screen shown before starting a live workout.
/// Keeps LiveWorkoutView focused on logging during the workout.
struct LiveWorkoutSetupView: View {
    @ObservedObject private var store: WorkoutStore

    @State private var type: String = ""
    @State private var category: WorkoutCategory = .strength

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
    }

    var body: some View {
        Form {
            Section("Type og kategori") {
                TextField("F.eks. Push / Bein / Øktnavn (valgfritt)", text: $type)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)

                Picker("Kategori", selection: $category) {
                    ForEach(WorkoutCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.iconName).tag(cat)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section {
                NavigationLink {
                    LiveWorkoutView(
                        store: store,
                        initialType: type.trimmingCharacters(in: .whitespacesAndNewlines),
                        initialCategory: category
                    )
                } label: {
                    Label("Start økt", systemImage: "play.circle.fill")
                }
            } footer: {
                Text("Du kan endre dette senere underveis, men det er ofte enklere å sette det nå.")
            }
        }
        .navigationTitle("Start økt")
        .navigationBarTitleDisplayMode(.inline)
    }
}