import SwiftUI

struct LiveWorkoutSetupView: View {
    @ObservedObject private var store: WorkoutStore

    @AppStorage("lastLiveWorkoutType") private var lastType: String = ""
    @AppStorage("lastLiveWorkoutCategory") private var lastCategoryRaw: String = WorkoutCategory.strength.rawValue

    @State private var type: String = ""
    @State private var category: WorkoutCategory = .strength
    @State private var plannedExercises: [Exercise] = []
    @State private var showExerciseSheet = false

    private let categoryColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
        _type = State(initialValue: lastType)
        _category = State(initialValue: WorkoutCategory(rawValue: lastCategoryRaw) ?? .strength)
    }

    private var presetsForCategory: [String] {
        switch category {
        case .strength: return ["Push", "Pull", "Bein", "Helkropp", "Overkropp", "Skulder"]
        case .cardio:   return ["Intervall", "HIIT", "Sone 2"]
        case .running:  return ["Langtur", "Intervall", "Terskel"]
        case .cycling:  return ["Langtur", "Intervall"]
        case .yoga:     return ["Morgen", "Kveld", "Yin"]
        case .walking:  return ["Morgentur", "Kveldstur"]
        case .swimming: return ["Fri", "Crawl", "Intervall"]
        case .other:    return []
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                categoryPicker
                nameField
                exercisePlanner
                startButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Start økt")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showExerciseSheet) {
            NewExerciseSheet(exercises: $plannedExercises)
        }
        .onDisappear {
            let trimmed = type.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { lastType = trimmed }
            lastCategoryRaw = category.rawValue
        }
    }

    // MARK: - Category picker

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kategori")
                .font(.headline)

            LazyVGrid(columns: categoryColumns, spacing: 12) {
                ForEach(WorkoutCategory.allCases) { cat in
                    Button {
                        let oldPresets = presetsForCategory
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            category = cat
                        }
                        if oldPresets.contains(type) { type = "" }
                    } label: {
                        categoryCell(cat)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func categoryCell(_ cat: WorkoutCategory) -> some View {
        let selected = cat == category
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(selected ? cat.color : cat.color.opacity(0.12))
                    .frame(width: 50, height: 50)
                Image(systemName: cat.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? .white : cat.color)
            }
            Text(cat.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(selected ? cat.color : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Name field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Navn (valgfritt)")
                .font(.headline)

            TextField("F.eks. Push / Bein / Overkropp", text: $type)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            if !presetsForCategory.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presetsForCategory, id: \.self) { preset in
                            Button {
                                type = preset
                            } label: {
                                Text(preset)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        type == preset
                                            ? category.color.opacity(0.15)
                                            : Color(.secondarySystemBackground)
                                    )
                                    .foregroundStyle(type == preset ? category.color : .primary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().strokeBorder(
                                            type == preset ? category.color.opacity(0.5) : .clear,
                                            lineWidth: 1
                                        )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Exercise planner

    private var exercisePlanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Planlegg øvelser")
                    .font(.headline)
                Spacer()
                if !plannedExercises.isEmpty {
                    Text("\(plannedExercises.count)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(category.color.opacity(0.15))
                        .foregroundStyle(category.color)
                        .clipShape(Capsule())
                }
            }

            if plannedExercises.isEmpty {
                Text("Valgfritt — legg til øvelser her, eller direkte under treningen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(plannedExercises.indices, id: \.self) { i in
                        let exercise = plannedExercises[i]
                        HStack(spacing: 10) {
                            Image(systemName: "dumbbell.fill")
                                .font(.caption)
                                .foregroundStyle(category.color)
                            Text(exercise.name)
                                .font(.subheadline)
                            Spacer()
                            Button {
                                withAnimation { _ = plannedExercises.remove(at: i) }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                        if i < plannedExercises.count - 1 {
                            Divider()
                        }
                    }
                }
            }

            Button { showExerciseSheet = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text(plannedExercises.isEmpty ? "Legg til øvelse" : "Legg til flere")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(category.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(category.color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Start button

    private var startButton: some View {
        NavigationLink {
            LiveWorkoutView(
                store: store,
                initialType: type.trimmingCharacters(in: .whitespacesAndNewlines),
                initialCategory: category,
                initialExercises: plannedExercises
            )
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                Text(plannedExercises.isEmpty ? "Start økt" : "Start økt (\(plannedExercises.count) øvelser)")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [category.color, category.color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: category.color.opacity(0.3), radius: 8, y: 4)
            .animation(.spring(response: 0.3), value: category)
        }
        .buttonStyle(.plain)
    }
}

