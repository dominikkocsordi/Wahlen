import SwiftUI

struct CandidateRowView: View {
    let index: Int
    let label: String
    let votes: Int?
    let percent: Double?
    let highlight: Bool
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.chartColor(for: index).opacity(0.18))
                Text("\(index + 1)")
                    .font(AppFont.display(compact ? 16 : 20, weight: .bold))
                    .foregroundStyle(Theme.chartColor(for: index))
            }
            .frame(width: compact ? 36 : 46, height: compact ? 36 : 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppFont.title(compact ? 18 : 22, weight: highlight ? .bold : .semibold))
                    .foregroundStyle(Theme.white)
                    .lineLimit(1)
                if let votes = votes, let percent = percent {
                    Text("\(votes) Stimmen · \(String(format: "%.1f", percent)) %")
                        .font(AppFont.body(compact ? 13 : 15))
                        .foregroundStyle(Theme.muted)
                }
            }

            Spacer(minLength: 8)

            if let votes = votes {
                Text("\(votes)")
                    .font(AppFont.mono(compact ? 20 : 26, weight: .semibold))
                    .foregroundStyle(highlight ? Theme.turquoise : Theme.white)
            }
        }
        .padding(.horizontal, compact ? 14 : 18)
        .padding(.vertical, compact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(highlight ? Theme.panelElevated : Theme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(highlight ? Theme.turquoise.opacity(0.5) : Theme.divider, lineWidth: 1)
        )
    }
}
