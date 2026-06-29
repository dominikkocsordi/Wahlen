import SwiftUI

struct WinnerCardView: View {
    let winner: CandidateResult
    var rotationDuration: Double = 10.0

    @State private var rotation: Double = 0

    private let rainbow: [Color] = [
        Color(hex: 0xFF3B5C),
        Color(hex: 0xFF7A3B),
        Color(hex: 0xFFB347),
        Color(hex: 0xFFE03B),
        Color(hex: 0x9FE34B),
        Color(hex: 0x3BD68A),
        Color(hex: 0x3BD6D2),
        Color(hex: 0x4DA8FF),
        Color(hex: 0x5A66FF),
        Color(hex: 0xA66BFF),
        Color(hex: 0xE34BD2),
        Color(hex: 0xFF4B8A),
        Color(hex: 0xFF3B5C)
    ]

    var body: some View {
        VStack(spacing: 36) {
            Text("GEWONNEN HAT")
                .font(.system(size: 32, weight: .semibold))
                .tracking(10)
                .foregroundStyle(Color.white.opacity(0.85))

            Text(winner.label)
                .font(.system(size: 150, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.35)
                .frame(maxWidth: 1500)

            HStack(spacing: 40) {
                statBlock(label: "Stimmen", value: "\(winner.votes)")
                Rectangle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 1, height: 70)
                statBlock(label: "Anteil", value: String(format: "%.1f %%", winner.percent))
            }
        }
        .padding(.horizontal, 100)
        .padding(.vertical, 80)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(hex: 0x0E2A5C).opacity(0.94))
        )
        .overlay {
            ZStack {
                // Soft outer glow that follows the gradient
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: rainbow,
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: 14
                    )
                    .blur(radius: 22)
                    .opacity(0.55)
                    .padding(-4)

                // Crisp inner border
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        AngularGradient(
                            colors: rainbow,
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: 5
                    )
            }
        }
        .shadow(color: Color.black.opacity(0.55), radius: 40, x: 0, y: 18)
        .onAppear {
            withAnimation(.linear(duration: rotationDuration).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }

    private func statBlock(label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 15, weight: .medium))
                .tracking(4)
                .foregroundStyle(Color.white.opacity(0.6))
            Text(value)
                .font(.system(size: 56, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }
}
