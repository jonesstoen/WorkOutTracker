// HealthOnboardingView.swift

import SwiftUI
import HealthKit
import OSLog

struct HealthOnboardingView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("La oss synkronisere med Helse-appen")
                .font(.title2).bold()
            Text("Appen trenger kun tillatelse til å lese treningsøkter. Selve importen skjer i bakgrunnen.")
                .multilineTextAlignment(.center)

            Button("Gi tilgang") {
                Task {
                    do {
                        let granted = try await HealthKitManager.shared.requestAuthorization()
                        guard granted else { return }
                        // **FJERN** alt som setter lastHealthKitImport her
                        isPresented = false
                    } catch {
                        Logger.healthKit.error("HealthKit-autorisasjon feilet: \(error.localizedDescription, privacy: .public)")
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Ikke nå") {
                isPresented = false
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
}
