import SwiftUI

struct ReleaseReadyView: View {
    @State private var ringScale: CGFloat = 0.3
    @State private var ringGlow: Double = 0
    @State private var symbolScale: CGFloat = 0
    @State private var symbolRotation: Double = -18
    @State private var pulse: CGFloat = 1.0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var rotation: Double = 0

    private let blueLight = Color(hex: 0x7AC7FF)
    private let blueDeep = Color(hex: 0x2D8CFF)

    var body: some View {
        ZStack {
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
                    blueDeep.opacity(0.14),
                    blueDeep.opacity(0.05),
                    .clear
                ],
                center: .center,
                startRadius: 80,
                endRadius: 1200
            )
            .ignoresSafeArea()

            Circle()
                .fill(blueDeep.opacity(0.08))
                .frame(width: 1800, height: 1800)
                .blur(radius: 140)

            VStack(spacing: 40) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [blueDeep.opacity(0.45), blueDeep.opacity(0)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 260
                            )
                        )
                        .frame(width: 520, height: 520)
                        .scaleEffect(pulse)
                        .opacity(ringGlow)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [blueLight, blueDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 5
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(ringScale)
                        .shadow(color: blueDeep.opacity(0.7), radius: 30)

                    Circle()
                        .trim(from: 0, to: 0.2)
                        .stroke(
                            LinearGradient(
                                colors: [blueLight, blueDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 340, height: 340)
                        .rotationEffect(.degrees(rotation))

                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [blueLight, blueDeep],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: blueDeep.opacity(0.6), radius: 24)
                        .scaleEffect(symbolScale)
                        .rotationEffect(.degrees(symbolRotation))

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [blueLight, blueDeep],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: blueDeep.opacity(0.55), radius: 10)
                        .offset(x: 78, y: 78)
                        .scaleEffect(symbolScale)
                        .rotationEffect(.degrees(symbolRotation))
                }

                VStack(spacing: 12) {
                    Text("Stimmen ausgezählt")
                        .font(.system(size: 46, weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("BEREIT FÜR DIE FREIGABE")
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
        withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
            ringScale = 1
            ringGlow = 1
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.58).delay(0.15)) {
            symbolScale = 1
            symbolRotation = 0
        }

        withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
            rotation = 360
        }

        withAnimation(.easeInOut(duration: 1.2).delay(0.3).repeatForever(autoreverses: true)) {
            pulse = 1.06
        }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.35)) {
            textOpacity = 1
            textOffset = 0
        }
    }
}
