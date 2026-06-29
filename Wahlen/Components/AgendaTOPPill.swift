import SwiftUI

struct AgendaTOPPill: View {
    let item: AgendaItem
    var totalItems: Int = 0

    private let gold = Color(hex: 0xFFE066)
    private let goldDeep = Color(hex: 0xE5A91A)

    var body: some View {
        HStack(spacing: 18) {
            // TOP-Nummer-Badge mit größerem Durchmesser
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [gold, goldDeep], startPoint: .top, endPoint: .bottom)
                    )
                Text("\(item.order)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.88))
            }
            .frame(width: 44, height: 44)
            .shadow(color: gold.opacity(0.55), radius: 10)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("TOP \(item.order)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(2.8)
                        .foregroundStyle(gold)
                    if totalItems > 0 {
                        Text("· VON \(totalItems)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(2.2)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }

                Text(item.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 28)
        .padding(.vertical, 12)
        .background(
            ZStack {
                Capsule(style: .continuous).fill(.ultraThinMaterial)
                Capsule(style: .continuous).fill(Color.black.opacity(0.55))
            }
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.45), .white.opacity(0.1), gold.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.4
                )
        )
        .shadow(color: .black.opacity(0.55), radius: 20, x: 0, y: 10)
        .shadow(color: gold.opacity(0.25), radius: 28, x: 0, y: 0)
        .frame(maxWidth: 860)
    }
}
