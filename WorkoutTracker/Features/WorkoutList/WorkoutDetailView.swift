import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout

    private var totalSets: Int {
        workout.exercises.reduce(0) { $0 + $1.sets.count }
    }
    private var totalVolume: Double {
        workout.exercises.reduce(0.0) { $0 + $1.totalVolume }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !workout.exercises.isEmpty {
                    statsCard
                }
                exercisesCard
                if !workout.notes.isEmpty {
                    notesCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(
            workout.type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? workout.category.rawValue
                : workout.type.capitalized
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: – Stats

    private var statsCard: some View {
        HStack(spacing: 0) {
            statCell(value: "\(workout.exercises.count)", label: "Øvelser")
            Divider().frame(height: 36)
            statCell(value: "\(totalSets)", label: "Sett")
            if totalVolume > 0 {
                Divider().frame(height: 36)
                statCell(value: "\(Int(totalVolume)) kg", label: "Volum")
            }
            if workout.duration > 0 {
                Divider().frame(height: 36)
                statCell(value: durationString(workout.duration), label: "Tid")
            }
        }
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: – Exercises

    private var exercisesCard: some View {
        VStack(spacing: 0) {
            if workout.exercises.isEmpty {
                Text("Ingen øvelser")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                ForEach(workout.exercises.indices, id: \.self) { ei in
                    let ex = workout.exercises[ei]
                    exerciseBlock(ex: ex)
                    if ei < workout.exercises.count - 1 {
                        Divider().padding(.leading, 14)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func exerciseBlock(ex: Exercise) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(ex.name).font(.headline)
                Spacer()
                if ex.totalVolume > 0 {
                    Text("\(Int(ex.totalVolume)) kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            HStack(spacing: 0) {
                Text("SETT").frame(width: 48, alignment: .leading)
                Spacer()
                Text("KG").frame(width: 80, alignment: .center)
                Spacer()
                Text("REPS").frame(width: 80, alignment: .center)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemBackground))

            ForEach(ex.sets.indices, id: \.self) { i in
                let s = ex.sets[i]
                HStack(spacing: 0) {
                    Text("\(i + 1)")
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .leading)
                    Spacer()
                    Text(String(format: "%.1f kg", s.weight))
                        .frame(width: 80, alignment: .center)
                    Spacer()
                    Text("\(s.reps) reps")
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .center)
                }
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                if i < ex.sets.count - 1 {
                    Divider().padding(.leading, 14)
                }
            }

            Spacer().frame(height: 8)
        }
    }

    // MARK: – Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notater", systemImage: "note.text")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(workout.notes)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: – Helpers

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.title3).bold()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func durationString(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600, m = (s % 3600) / 60
        if h > 0 { return "\(h)t \(m)m" }
        return "\(m) min"
    }
}
