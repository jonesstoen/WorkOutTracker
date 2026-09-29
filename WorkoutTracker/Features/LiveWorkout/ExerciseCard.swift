import SwiftUI

struct ExerciseCard: View {
    @Binding var exercise: Exercise
    let index: Int
    let lastSession: ExerciseDataPoint?
    let onDelete: () -> Void
    let onSetCompleted: () -> Void
    let isPR: (Double, Int) -> Bool

    @State private var showRename = false
    @State private var pendingName = ""

    private static let palette: [Color] = [
        .blue, .orange, .purple, .green, .red, .pink, .teal, .yellow
    ]
    private var accentColor: Color { Self.palette[index % Self.palette.count] }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 5)

            VStack(spacing: 0) {
                headerRow
                Divider()
                columnHeader
                setRows
                addSetButton
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        .alert("Gi øvelsen nytt navn", isPresented: $showRename) {
            TextField("Navn", text: $pendingName)
                .textInputAutocapitalization(.sentences)
            Button("Avbryt", role: .cancel) { }
            Button("Lagre") {
                let t = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { exercise.name = t }
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text("\(index + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                    Button {
                        pendingName = exercise.name
                        showRename = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                if let last = lastSession {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                        Text(last.weight > 0 ? "\(last.weight.kgLabel) kg × \(last.reps) reps" : "\(last.reps) reps")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            Spacer()

            if exercise.completedVolume > 0 {
                Text("\(Int(exercise.completedVolume)) kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(.systemGray4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var columnHeader: some View {
        // Mirrors LiveSetRow's columns: delete + number, kg, reps, trophy + checkmark
        HStack(spacing: 0) {
            Text("SETT")
                .frame(width: 44, alignment: .leading)
            Spacer()
            HStack(spacing: 0) {
                Text("KG").frame(width: 86)
                Spacer()
                Text("REPS").frame(width: 86)
            }
            Image(systemName: "checkmark")
                .frame(width: 62, alignment: .trailing)
                .padding(.trailing, 8)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color(.tertiarySystemBackground))
    }

    private var setRows: some View {
        ForEach(exercise.sets.indices, id: \.self) { i in
            let setBinding = Binding<WorkingSet>(
                get: { exercise.sets[i] },
                set: { exercise.sets[i] = $0 }
            )
            let set = exercise.sets[i]
            let showPR = set.isCompleted && isPR(set.weight, set.reps)
            LiveSetRow(
                setNumber: i + 1,
                set: setBinding,
                showPR: showPR,
                onCompleted: onSetCompleted,
                onDelete: {
                    withAnimation {
                        var updated = exercise.sets
                        updated.remove(at: i)
                        exercise.sets = updated
                    }
                }
            )
            if i < exercise.sets.count - 1 {
                Divider().padding(.leading, 14)
            }
        }
    }

    private var addSetButton: some View {
        Button {
            let last = exercise.sets.last ?? WorkingSet(reps: 10, weight: 0)
            withAnimation(.easeInOut(duration: 0.15)) {
                exercise.sets.append(last.planned)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                Text("Legg til sett")
            }
            .font(.subheadline)
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}
