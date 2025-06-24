import SwiftUI

struct EditCustomExercisesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: ExercisesViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(vm.exercises, id: \.self) { ex in
                    Text(ex)
                }
                .onDelete(perform: vm.remove)
            }
            .navigationTitle("Egendefinerte øvelser")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Ferdig") { dismiss() }
                }
            }
        }
    }
}
