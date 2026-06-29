import SwiftUI

struct VotingOpenView: View {

    let session: VoteSession
    let votes: [Vote]

    @State private var rotation: Double = 0

    @State private var ringScale: CGFloat = 0.3
    @State private var ringGlow: Double = 0

    @State private var iconScale: CGFloat = 0
    @State private var iconRotation: Double = -20

    @State private var pulse: CGFloat = 1.0
    @State private var fullPulse: CGFloat = 1.0

    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 30

    @State private var qrOpacity: Double = 0
    @State private var qrOffset: CGFloat = 40

    private let blueLight = Color(hex: 0x7EC6FF)
    private let blueDeep = Color(hex: 0x4A9BFF)

    private var ballotURL: URL {
        AppConfig.ballotURL(for: session.token)
    }

    private var totalVotes: Int {
        votes.reduce(0) { $0 + max($1.weight, 1) }
    }

    private var participationFraction: Double {
        guard let limit = session.participantLimit, limit > 0 else { return 0 }
        return min(Double(totalVotes) / Double(limit), 1.0)
    }

    private var isFull: Bool {
        participationFraction >= 1.0
    }

    private var participationText: String {
        guard session.participantLimit ?? 0 > 0 else { return "—" }
        let percent = Int(participationFraction * 100)
        return "\(percent) %"
    }

    var body: some View {
        ZStack {

            // MARK: - Background

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
                    blueDeep.opacity(0.15),
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

            // MARK: - Center Stack (matches DecryptingView/VerifyingView structure)

            VStack(spacing: 40) {
                envelopeArea
                titleArea
                    .opacity(textOpacity)
                    .offset(y: textOffset)
            }

            // MARK: - QR + Link rechts mittig

            HStack(spacing: 0) {
                Spacer(minLength: 0)
                qrArea
                    .opacity(qrOpacity)
                    .offset(x: qrOffset)
                    .padding(.trailing, 60)
            }
        }
        .onAppear { startAnimations() }
        .transition(.opacity)
    }

    // MARK: - Envelope area

    private var envelopeArea: some View {
        ZStack {

            // Outer soft glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            blueDeep.opacity(isFull ? 0.65 : 0.42),
                            blueDeep.opacity(0)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 280
                    )
                )
                .frame(width: 520, height: 520)
                .scaleEffect(isFull ? fullPulse : pulse)
                .opacity(ringGlow)

            // Static track (faint full circle)
            Circle()
                .strokeBorder(
                    blueDeep.opacity(0.18),
                    lineWidth: 10
                )
                .frame(width: 340, height: 340)
                .scaleEffect(ringScale)

            // Soft inner ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            blueLight.opacity(0.7),
                            blueDeep.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 300, height: 300)
                .scaleEffect(ringScale)
                .shadow(
                    color: blueDeep.opacity(0.6),
                    radius: 24
                )

            // Progress arc (grows with participation, rotates)
            Circle()
                .trim(
                    from: 0,
                    to: max(0.001, participationFraction)
                )
                .stroke(
                    LinearGradient(
                        colors: isFull
                            ? [blueLight, Color(hex: 0xFFFFFF), blueLight]
                            : [blueLight, blueDeep],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 14,
                        lineCap: .round
                    )
                )
                .frame(width: 340, height: 340)
                .rotationEffect(.degrees(-90 + rotation))
                .scaleEffect(ringScale)
                .shadow(
                    color: blueLight.opacity(isFull ? 1.0 : 0.55),
                    radius: isFull ? 38 : 18
                )
                .animation(
                    .spring(response: 0.9, dampingFraction: 0.85),
                    value: participationFraction
                )

            // Envelope icon
            Image(systemName: "envelope.fill")
                .font(
                    .system(
                        size: 130,
                        weight: .heavy,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [blueLight, blueDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: blueDeep.opacity(0.7),
                    radius: 28
                )
                .scaleEffect(iconScale)
                .rotationEffect(.degrees(iconRotation))
        }
    }

    // MARK: - Title + Badges (unter dem Briefumschlag, wie Text in DecryptingView)

    private var titleArea: some View {
        VStack(spacing: 14) {

            Text(session.title)
                .font(.system(size: 46, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: 1100)

            HStack(spacing: 10) {
                infoBadge(
                    icon: "person.3.fill",
                    text: "\(totalVotes) Stimmen"
                )
                infoBadge(
                    icon: "chart.bar.fill",
                    text: participationText
                )
                if session.requiresAbsoluteMajority {
                    infoBadge(
                        icon: "scalemass.fill",
                        text: "Absolute Mehrheit"
                    )
                }
            }
        }
    }

    private func infoBadge(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(blueLight)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(blueDeep.opacity(0.18))
        )
        .overlay(
            Capsule().stroke(blueDeep.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - QR + Link

    private var qrArea: some View {
        VStack(spacing: 14) {

            QRCodeView(
                content: ballotURL.absoluteString,
                size: 300
            )

            Text(ballotURL.absoluteString)
                .font(
                    .system(
                        size: 16,
                        weight: .medium,
                        design: .monospaced
                    )
                )
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color.white.opacity(0.06))
                )
                .overlay(
                    Capsule().stroke(blueDeep.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: - Animations

    private func startAnimations() {

        withAnimation(
            .spring(response: 0.55, dampingFraction: 0.7)
        ) {
            ringScale = 1
            ringGlow = 1
        }

        withAnimation(
            .spring(response: 0.5, dampingFraction: 0.55).delay(0.18)
        ) {
            iconScale = 1
            iconRotation = 0
        }

        withAnimation(
            .linear(duration: 6.0).repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }

        withAnimation(
            .easeInOut(duration: 1.3).delay(0.4).repeatForever(autoreverses: true)
        ) {
            pulse = 1.08
        }

        withAnimation(
            .easeInOut(duration: 1.1).repeatForever(autoreverses: true)
        ) {
            fullPulse = 1.18
        }

        withAnimation(
            .spring(response: 0.6, dampingFraction: 0.85).delay(0.45)
        ) {
            textOpacity = 1
            textOffset = 0
        }

        withAnimation(
            .spring(response: 0.7, dampingFraction: 0.85).delay(0.55)
        ) {
            qrOpacity = 1
            qrOffset = 0
        }
    }
}
