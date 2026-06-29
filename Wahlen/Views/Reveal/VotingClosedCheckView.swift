import SwiftUI

struct VotingClosedCheckView: View {

    // Main event (rotes Mail-X + Ring)
    @State private var ringScale: CGFloat = 0.3
    @State private var ringGlow: Double = 0
    @State private var iconScale: CGFloat = 0
    @State private var iconRotation: Double = -25
    @State private var pulse: CGFloat = 1.0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 30

    // Anticipation (0 – 3 s Buildup)
    @State private var dotScale: CGFloat = 0
    @State private var dotPulse: CGFloat = 1.0
    @State private var dotOpacity: Double = 0
    @State private var buildupRingTrim: CGFloat = 0
    @State private var buildupRingOpacity: Double = 0
    @State private var buildupRotation: Double = 0

    @State private var orchestrationTask: Task<Void, Never>?

    private let mainEventDelay: TimeInterval = 3.0

    private let redLight = Color(hex: 0xFF8A8A)
    private let redDeep = Color(hex: 0xFF4D4D)

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
                    redDeep.opacity(0.14),
                    redDeep.opacity(0.05),
                    .clear
                ],
                center: .center,
                startRadius: 80,
                endRadius: 1200
            )
            .ignoresSafeArea()

            Circle()
                .fill(redDeep.opacity(0.08))
                .frame(width: 1800, height: 1800)
                .blur(radius: 140)

            // MARK: Content

            VStack(spacing: 40) {

                ZStack {

                    // MARK: Anticipation Layer (0 – 3 s)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    redLight.opacity(0.95),
                                    redDeep.opacity(0.55),
                                    redDeep.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(dotScale * dotPulse)
                        .opacity(dotOpacity)
                        .blur(radius: 4)

                    Circle()
                        .trim(from: 0, to: buildupRingTrim)
                        .stroke(
                            LinearGradient(
                                colors: [redLight, redDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(
                                lineWidth: 6,
                                lineCap: .round
                            )
                        )
                        .frame(width: 260, height: 260)
                        .rotationEffect(.degrees(-90 + buildupRotation))
                        .opacity(buildupRingOpacity)
                        .shadow(
                            color: redDeep.opacity(0.5),
                            radius: 18
                        )

                    // MARK: Main Event Layer (ab 3 s)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    redDeep.opacity(0.45),
                                    redDeep.opacity(0)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 260
                            )
                        )
                        .frame(width: 480, height: 480)
                        .scaleEffect(pulse)
                        .opacity(ringGlow)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [redLight, redDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 5
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(ringScale)
                        .shadow(color: redDeep.opacity(0.7), radius: 30)

                    Image(systemName: "xmark.seal.fill")
                        .font(.system(size: 150, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [redLight, redDeep],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: redDeep.opacity(0.6), radius: 24)
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                }

                VStack(spacing: 12) {
                    Text("Wahl geschlossen")
                        .font(.system(size: 46, weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("KEINE WEITEREN STIMMEN MÖGLICH")
                        .font(.system(size: 22, weight: .medium))
                        .tracking(4)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
            }
        }
        .onAppear { start() }
        .onDisappear {
            orchestrationTask?.cancel()
            orchestrationTask = nil
        }
        .transition(.opacity)
    }

    private func start() {

        orchestrationTask?.cancel()

        // --- Phase 1: Anticipation (0 – 3 s) ---

        withAnimation(.easeOut(duration: 0.5)) {
            dotOpacity = 1
            dotScale = 1
            buildupRingOpacity = 1
        }

        withAnimation(.easeInOut(duration: mainEventDelay - 0.1)) {
            buildupRingTrim = 1.0
        }

        withAnimation(
            .linear(duration: 2.4).repeatForever(autoreverses: false)
        ) {
            buildupRotation = 360
        }

        withAnimation(
            .easeInOut(duration: 0.7).repeatForever(autoreverses: true)
        ) {
            dotPulse = 1.18
        }

        // --- Phase 2: Main Event (nach 3 s) ---

        orchestrationTask = Task { @MainActor in

            try? await Task.sleep(for: .seconds(mainEventDelay))
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.35)) {
                dotOpacity = 0
                buildupRingOpacity = 0
                dotScale = 1.6
            }

            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                ringScale = 1.0
                ringGlow = 1.0
            }
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.55).delay(0.18)
            ) {
                iconScale = 1.0
                iconRotation = 0
            }
            withAnimation(
                .easeInOut(duration: 1.3).delay(0.4).repeatForever(autoreverses: true)
            ) {
                pulse = 1.08
            }
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.85).delay(0.45)
            ) {
                textOpacity = 1.0
                textOffset = 0
            }
        }
    }
}
