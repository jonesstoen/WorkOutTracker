import SwiftUI

struct LiveSetRow: View {
    let setNumber: Int
    @Binding var set: WorkingSet
    let showPR: Bool
    let onCompleted: () -> Void
    let onDelete: () -> Void

    @State private var showPicker = false

    var body: some View {
        HStack(spacing: 0) {
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.6))
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .frame(width: 24, alignment: .leading)

            Text("\(setNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .leading)

            Spacer()

            Button { showPicker = true } label: {
                HStack(spacing: 0) {
                    valuePill(set.weight.kgLabel, unit: "kg", width: 54)
                    Spacer()
                    valuePill("\(set.reps)", unit: "reps", width: 44)
                }
            }
            .buttonStyle(.plain)

            Image(systemName: "trophy.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
                .opacity(showPR ? 1 : 0)
                .frame(width: 20)
                .padding(.leading, 4)

            completeButton
                .padding(.leading, 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(set.isCompleted ? Color.green.opacity(0.12) : .clear)
        .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
        .sheet(isPresented: $showPicker) {
            SetPickerSheet(weight: $set.weight, reps: $set.reps)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }

    private var completeButton: some View {
        Button {
            set.isCompleted.toggle()
            if set.isCompleted {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onCompleted()
            }
        } label: {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(set.isCompleted ? Color.green : Color(.systemGray3))
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .frame(width: 32)
        .accessibilityLabel(set.isCompleted ? "Sett \(setNumber) fullført" : "Fullfør sett \(setNumber)")
    }

    private func valuePill(_ value: String, unit: String, width: CGFloat) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .frame(width: width, alignment: .center)
                .padding(.vertical, 7)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 86)
    }
}
