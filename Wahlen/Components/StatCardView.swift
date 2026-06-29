import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var tint: Color = Theme.lightBlue
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            Text(title.uppercased())
                .font(AppFont.body(compact ? 11 : 12, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(AppFont.display(compact ? 30 : 40, weight: .bold))
                .foregroundStyle(Theme.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppFont.body(compact ? 11 : 13))
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 16 : 22)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Rectangle()
                .fill(tint)
                .frame(width: 4, height: compact ? 20 : 28)
                .clipShape(Capsule())
                .padding(compact ? 12 : 16)
        }
    }
}
