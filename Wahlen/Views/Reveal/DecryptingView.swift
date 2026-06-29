import SwiftUI

struct DecryptingView: View {

    @State private var spinAngle: Double = 0
    @State private var counterSpin: Double = 0
    @State private var pulse: CGFloat = 1.0
    @State private var iconScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 30

    private let goldLight = Color(hex: 0xFFD54F)
    private let goldDeep  = Color(hex: 0xFFA000)

    var body: some View {
        ZStack {

            // MARK: Background

            LinearGradient(
                colors: [
                    Color(hex: 0x061827),
                    Color(hex: 0x0A2235),
                    Color(hex: 0x04111C)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    goldDeep.opacity(0.14),
                    goldDeep.opacity(0.05),
                    .clear
                ],
                center: .center,
                startRadius: 80,
                endRadius: 1200
            )
            .ignoresSafeArea()

            Circle()
                .fill(goldDeep.opacity(0.08))
                .frame(width: 1800, height: 1800)
                .blur(radius: 140)

            // MARK: Content

            VStack(spacing: 40) {

                ZStack {

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    goldDeep.opacity(0.35),
                                    goldDeep.opacity(0)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 260
                            )
                        )
                        .frame(width: 480, height: 480)
                        .scaleEffect(pulse)

                    Circle()
                        .trim(from: 0.05, to: 0.85)
                        .stroke(
                            LinearGradient(
                                colors: [goldLight, goldDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(spinAngle))
                        .shadow(color: goldDeep.opacity(0.6), radius: 18)

                    Circle()
                        .trim(from: 0.1, to: 0.6)
                        .stroke(
                            goldLight.opacity(0.35),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(counterSpin))

                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 110, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [goldLight, goldDeep],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: goldDeep.opacity(0.6), radius: 24)
                        .scaleEffect(iconScale)
                }

                VStack(spacing: 12) {
                    Text("Stimmen werden gezählt")
                        .font(.system(size: 46, weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("AUSZÄHLUNG LÄUFT")
                        .font(.system(size: 22, weight: .medium))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
            }
        }
        .onAppear { start() }
        .transition(.opacity)
    }

    private func start() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            iconScale = 1.0
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.2)) {
            textOpacity = 1.0
            textOffset = 0
        }
        withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
            spinAngle = 360
        }
        withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
            counterSpin = -360
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulse = 1.1
        }
    }
}
