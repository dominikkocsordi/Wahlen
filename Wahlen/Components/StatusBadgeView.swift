import SwiftUI

struct StatusBadgeView: View {
    let phase: AdminElectionPhase

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(phase.rawValue)
                .font(AppFont.body(13, weight: .semibold))
                .foregroundStyle(Theme.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Theme.panelElevated)
        )
        .overlay(
            Capsule().stroke(color.opacity(0.5), lineWidth: 1)
        )
    }

    private var color: Color {
        switch phase {
        case .preparation: return Theme.muted
        case .ballot: return Theme.lightBlue
        case .open: return Theme.turquoise
        case .counting: return Theme.yellow
        case .verification: return Theme.yellow
        case .result: return Theme.lightBlue
        }
    }
}
