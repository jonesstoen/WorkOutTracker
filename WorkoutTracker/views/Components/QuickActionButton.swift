import SwiftUI
import UIKit   // nødvendig for UIImpactFeedbackGenerator

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            // 1. Haptisk tilbakemelding
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            // 2. Utfør handlingen
            action()
        } label: {
            VStack(spacing: 6) {                   // mer luft mellom ikon + tekst
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor) // bruker accentColor
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color(.black).opacity(0.05),
                    radius: 2, x: 0, y: 1)
        }
    }
}
