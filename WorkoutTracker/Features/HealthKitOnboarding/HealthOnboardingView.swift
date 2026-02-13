// HealthOnboardingView.swift

import SwiftUI
import HealthKit

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
                        print("HealthKit-autorisasjon feilet:", error)
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
