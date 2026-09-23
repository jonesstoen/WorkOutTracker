import SwiftUI

struct SetPickerSheet: View {
    @Binding var weight: Double
    @Binding var reps: Int
    @Environment(\.dismiss) private var dismiss

    @State private var selectedWeight: Double
    @State private var selectedReps: Int

    private static let weights: [Double] = Array(stride(from: 0.0, through: 300.0, by: 0.5))
    private static let repValues: [Int]  = Array(1...50)

    init(weight: Binding<Double>, reps: Binding<Int>) {
        _weight = weight
        _reps   = reps
        let snapped = max(0, min(300, (weight.wrappedValue * 2).rounded() / 2))
        _selectedWeight = State(initialValue: snapped)
        _selectedReps   = State(initialValue: max(1, min(50, reps.wrappedValue)))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle + header
            HStack {
                Text("Vekt og reps")
                    .font(.headline)
                Spacer()
                Button("Ferdig") {
                    weight = selectedWeight
                    reps   = selectedReps
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // Column labels
            HStack(spacing: 0) {
                Text("KG")
                    .frame(maxWidth: .infinity)
                Text("REPS")
                    .frame(maxWidth: .infinity)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 8)

            // Wheels
            HStack(spacing: 0) {
                Picker("Vekt", selection: $selectedWeight) {
                    ForEach(Self.weights, id: \.self) { w in
                        Text(w.kgLabel)
                            .tag(w)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Picker("Reps", selection: $selectedReps) {
                    ForEach(Self.repValues, id: \.self) { r in
                        Text("\(r)").tag(r)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: selectedWeight) { weight = $0 }
            .onChange(of: selectedReps)   { reps   = $0 }
        }
        .background(Color(.systemBackground))
    }
}
