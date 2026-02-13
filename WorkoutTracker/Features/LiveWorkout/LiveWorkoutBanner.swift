import SwiftUI

struct LiveWorkoutBanner: View {
    @ObservedObject var session: LiveSessionCoordinator

    var body: some View {
        if session.isActive && !session.isLiveViewVisible {
            Button {
                session.onResumeTapped?()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: session.category.iconName)
                        .foregroundColor(session.category.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pågående økt")
                            .font(.caption).bold()
                        Text("\(session.type.isEmpty ? session.category.rawValue : session.type) · \(format(session.elapsed))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let s = Int(t), h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec)
                     : String(format: "%02d:%02d", m, sec)
    }
}
