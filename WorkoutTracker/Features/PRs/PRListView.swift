import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
final class PRListViewModel: ObservableObject {
    @Published private(set) var prs: [ExercisePR] = []
    private var cancellables = Set<AnyCancellable>()

    init(store: WorkoutStore) {
        recompute(from: store.workouts)
        store.$workouts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] workouts in self?.recompute(from: workouts) }
            .store(in: &cancellables)
    }

    private func recompute(from workouts: [Workout]) {
        prs = PRService.computePRs(from: workouts)
            .values
            .sorted { $0.exerciseName.localizedCaseInsensitiveCompare($1.exerciseName) == .orderedAscending }
    }
}

// MARK: - View

struct PRListView: View {
    @ObservedObject private var store: WorkoutStore
    @StateObject private var vm: PRListViewModel
    @State private var searchText = ""

    init(store: WorkoutStore) {
        self._store = ObservedObject(wrappedValue: store)
        self._vm    = StateObject(wrappedValue: PRListViewModel(store: store))
    }

    private var filtered: [ExercisePR] {
        searchText.isEmpty ? vm.prs : vm.prs.filter {
            $0.exerciseName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if vm.prs.isEmpty {
                ContentUnavailableView(
                    "Ingen rekorder enda",
                    systemImage: "trophy",
                    description: Text("Logg styrkeøkter for å se dine personlige rekorder her.")
                )
            } else {
                List {
                    if !filtered.isEmpty {
                        Section {
                            ForEach(filtered) { pr in
                                NavigationLink {
                                    ExerciseHistoryView(
                                        exerciseName: pr.exerciseName,
                                        history: ProgressionService.history(for: pr.exerciseName, in: store.workouts),
                                        advice: ProgressionService.overloadAdvice(for: pr.exerciseName, in: store.workouts)
                                    )
                                } label: {
                                    prRow(pr)
                                }
                            }
                        } header: {
                            Text("\(filtered.count) øvelse\(filtered.count == 1 ? "" : "r")")
                        }
                    } else {
                        ContentUnavailableView(
                            "Ingen treff",
                            systemImage: "magnifyingglass",
                            description: Text("Prøv et annet søkeord.")
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Søk etter øvelse")
            }
        }
        .navigationTitle("Rekorder")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Row

    private func prRow(_ pr: ExercisePR) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: "trophy.fill")
                    .font(.body)
                    .foregroundStyle(.yellow)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(pr.exerciseName)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(pr.weight.kgLabel) kg × \(pr.reps) reps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(pr.date.formatted(.dateTime.day().month(.abbreviated).year()))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(Int(pr.e1RM.rounded())) kg")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.accentColor)
                Text("est. 1RM")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
