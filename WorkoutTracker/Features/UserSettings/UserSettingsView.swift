import SwiftUI

struct UserSettingsView: View {
    @AppStorage("userName")    private var userName: String = ""
    @AppStorage("weeklyGoal") private var weeklyGoal: Int  = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Profil") {
                    TextField("Navn", text: $userName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }

                Section {
                    Stepper(
                        weeklyGoal == 1 ? "1 økt per uke" : "\(weeklyGoal) økter per uke",
                        value: $weeklyGoal,
                        in: 1...7
                    )
                } header: {
                    Text("Ukentlig mål")
                } footer: {
                    Text("Brukes til å vise fremgang på oversikten.")
                }
            }
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
