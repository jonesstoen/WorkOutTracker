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
                                prRow(pr)
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

            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exerciseName)
                    .font(.headline)

                HStack(spacing: 6) {
                    Text(weightRepsLabel(pr))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text("Est. 1RM: \(Int(pr.e1RM.rounded())) kg")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(pr.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func weightRepsLabel(_ pr: ExercisePR) -> String {
        let w = pr.weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(pr.weight))"
            : String(format: "%.1f", pr.weight)
        return "\(w) kg × \(pr.reps) reps"
    }
}
