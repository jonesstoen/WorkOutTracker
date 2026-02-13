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

    @AppStorage("lastLiveWorkoutType") private var lastType: String = ""
    @AppStorage("lastLiveWorkoutCategory") private var lastCategoryRaw: String = WorkoutCategory.strength.rawValue

    @State private var type: String = ""
    @State private var category: WorkoutCategory = .strength

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
        // Sett startverdier basert på forrige økt
        _type = State(initialValue: lastType)
        _category = State(initialValue: WorkoutCategory(rawValue: lastCategoryRaw) ?? .strength)
    }

    var body: some View {
        Form {
            Section("Type og kategori") {
                TextField("F.eks. Push / Bein / Øktnavn (valgfritt)", text: $type)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)

                // Hurtigvalg for vanlige øktnavn
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["Push", "Pull", "Bein", "Helkropp"], id: \.self) { preset in
                            Button {
                                type = preset
                            } label: {
                                Text(preset)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

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
        .onDisappear {
            // Husk sist brukte verdier til neste gang brukeren starter en live‑økt.
            let trimmed = type.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                lastType = trimmed
            }
            lastCategoryRaw = category.rawValue
        }
    }
}