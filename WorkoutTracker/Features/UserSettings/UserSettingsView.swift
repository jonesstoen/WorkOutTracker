import SwiftUI

/// Enkel innstillingsskjerm for brukerprofil / preferanser.
struct UserSettingsView: View {
    @AppStorage("userName") private var userName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Profil") {
                    TextField("Navn", text: $userName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
            }
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

