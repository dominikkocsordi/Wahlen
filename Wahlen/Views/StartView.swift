import SwiftUI

struct StartView: View {
    private let logoAssetName = "logo_white"

    private let backgroundDeep = Color(hex: 0x07111F)
    private let backgroundMid = Color(hex: 0x0D1D33)
    private let panelBlue = Color(hex: 0x102844)
    private let accentBlue = Color(hex: 0x4DA8FF)
    private let accentAmber = Color(hex: 0xFFB347)
    private let accentGold = Color(hex: 0xFFD67F)
    private let softWhite = Color.white.opacity(0.92)
    private let mutedWhite = Color.white.opacity(0.62)

    @State private var orbDrift = false
    @State private var ringVisible = false
    @State private var ringPulse: CGFloat = 0.96
    @State private var ringRotation: Double = -18
    @State private var contentVisible = false
    @State private var cardFloat = false

    private var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: accentBlue, location: 0.00),
                .init(color: .white, location: 0.18),
                .init(color: accentAmber, location: 0.46),
                .init(color: .white, location: 0.78),
                .init(color: accentBlue, location: 1.00)
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    private var highlightGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: .white.opacity(0.95), location: 0.00),
                .init(color: .white, location: 0.18),
                .init(color: .white.opacity(0.8), location: 0.50),
                .init(color: .white, location: 0.82),
                .init(color: .white.opacity(0.95), location: 1.00)
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 1200

            ZStack {
                backgroundLayer

                if compact {
                    compactLayout
                        .padding(.horizontal, 28)
                        .padding(.vertical, 34)
                } else {
                    wideLayout
                        .padding(.horizontal, 72)
                        .padding(.vertical, 54)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: true)) {
                orbDrift.toggle()
            }
            withAnimation(.spring(response: 1.1, dampingFraction: 0.82)) {
                ringVisible = true
            }
            withAnimation(.easeInOut(duration: 4.8).repeatForever(autoreverses: true)) {
                ringPulse = 1.03
            }
            withAnimation(.linear(duration: 45).repeatForever(autoreverses: false)) {
                ringRotation = 342
            }
            withAnimation(.spring(response: 0.95, dampingFraction: 0.86).delay(0.12)) {
                contentVisible = true
            }
            withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true)) {
                cardFloat.toggle()
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [backgroundDeep, backgroundMid, Color(hex: 0x091728)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(accentBlue.opacity(0.22))
                .frame(width: 760, height: 760)
                .blur(radius: 170)
                .offset(
                    x: orbDrift ? 360 : -220,
                    y: orbDrift ? -260 : -60
                )

            Ellipse()
                .fill(accentAmber.opacity(0.16))
                .frame(width: 620, height: 880)
                .blur(radius: 170)
                .offset(
                    x: orbDrift ? -260 : 280,
                    y: orbDrift ? 280 : 40
                )

            RoundedRectangle(cornerRadius: 240, style: .continuous)
                .fill(panelBlue.opacity(0.34))
                .frame(width: 900, height: 540)
                .blur(radius: 160)
                .offset(x: 0, y: 190)

            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 220)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()
        }
    }

    private var wideLayout: some View {
        HStack(spacing: 54) {
            heroContent(maxWidth: 700, alignLeading: true)

            Spacer(minLength: 0)

            visualStage
                .frame(width: 720, height: 720)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var compactLayout: some View {
        VStack(spacing: 28) {
            heroContent(maxWidth: 680, alignLeading: false)
            visualStage
                .frame(height: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func heroContent(maxWidth: CGFloat, alignLeading: Bool) -> some View {
        VStack(alignment: alignLeading ? .leading : .center, spacing: 26) {
            topBadge

            VStack(alignment: alignLeading ? .leading : .center, spacing: 18) {
                Text("FSBS WAHLEN")
                    .font(AppFont.body(15, weight: .bold))
                    .tracking(4.5)
                    .foregroundStyle(accentGold)

                Text("Die Bühne ist bereit\nfür den nächsten Vorstand.")
                    .font(AppFont.display(70, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(alignLeading ? .leading : .center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Live-Präsentation für die Fachschaft Business School e.V. mit klarer, ruhiger Bühne und stärkerem Fokus auf den Moment der Wahl.")
                    .font(AppFont.body(21, weight: .medium))
                    .foregroundStyle(mutedWhite)
                    .multilineTextAlignment(alignLeading ? .leading : .center)
                    .frame(maxWidth: 620)
            }

            infoPanel(alignment: alignLeading ? .leading : .center)
        }
        .frame(maxWidth: maxWidth, alignment: alignLeading ? .leading : .center)
        .opacity(contentVisible ? 1 : 0)
        .offset(x: contentVisible ? 0 : -36, y: contentVisible ? 0 : 18)
    }

    private var topBadge: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(accentGold)

            Text("25 JAHRE")
                .font(AppFont.body(15, weight: .bold))
                .tracking(4.2)
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                Text("2001")
                Rectangle()
                    .fill(accentGold.opacity(0.7))
                    .frame(width: 16, height: 1)
                Text("2026")
            }
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.62))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05), in: Capsule())
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [accentBlue.opacity(0.65), .white.opacity(0.22), accentAmber.opacity(0.45)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: accentBlue.opacity(0.22), radius: 20)
    }

    private func infoPanel(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 20) {
            HStack(spacing: 12) {
                statChip(icon: "display", label: "Beamer Ready")
                statChip(icon: "waveform.path.ecg", label: "Live Inszenierung")
                statChip(icon: "person.3.fill", label: "Vorstandswahl")
            }

            HStack(spacing: 18) {
                detailCard(title: "Atmosphäre", value: "Klar und präsent", accent: accentBlue)
                detailCard(title: "Stil", value: "Modernes Broadcast-Look", accent: accentAmber)
            }
        }
    }

    private func statChip(icon: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(label)
                .font(AppFont.body(14, weight: .semibold))
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.05), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.08), lineWidth: 1))
    }

    private func detailCard(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.body(13, weight: .bold))
                .tracking(2)
                .foregroundStyle(accent)

            Text(value)
                .font(AppFont.title(24, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var visualStage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(.white.opacity(0.045))
                .overlay(
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.24), radius: 40, y: 20)
                .offset(y: cardFloat ? -10 : 10)

            radialSpotlight

            tubeRing
                .scaleEffect(ringVisible ? ringPulse : 0.72)
                .opacity(ringVisible ? 1 : 0)

            VStack(spacing: 24) {
                GlowLogoView(
                    imageName: logoAssetName,
                    glowColor: accentBlue,
                    secondaryGlowColor: accentAmber
                )
                .frame(width: 240, height: 140)

                VStack(spacing: 10) {
                    Text("FACHSCHAFT")
                        .font(AppFont.body(16, weight: .bold))
                        .tracking(8)
                        .foregroundStyle(accentGold)

                    Text("Business School e.V.")
                        .font(AppFont.title(44, weight: .semibold))
                        .foregroundStyle(softWhite)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 28)
        }
    }

    private var radialSpotlight: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(0.12),
                        accentBlue.opacity(0.12),
                        accentAmber.opacity(0.10),
                        .clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 290
                )
            )
            .frame(width: 560, height: 560)
            .blur(radius: 22)
            .blendMode(.screen)
    }

    private var tubeRing: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentBlue.opacity(0.32), accentAmber.opacity(0.24), .clear],
                        center: .center,
                        startRadius: 80,
                        endRadius: 310
                    )
                )
                .frame(width: 640, height: 640)
                .blur(radius: 54)

            Group {
                Circle()
                    .stroke(ringGradient, lineWidth: 54)
                    .frame(width: 430, height: 430)
                    .blur(radius: 60)
                    .opacity(0.85)

                Circle()
                    .stroke(ringGradient, lineWidth: 34)
                    .frame(width: 430, height: 430)
                    .blur(radius: 24)
                    .opacity(0.96)

                Circle()
                    .stroke(ringGradient, lineWidth: 18)
                    .frame(width: 430, height: 430)
                    .blur(radius: 7)

                Circle()
                    .stroke(ringGradient, lineWidth: 10)
                    .frame(width: 430, height: 430)
                    .blur(radius: 2)

                Circle()
                    .stroke(highlightGradient, lineWidth: 2.6)
                    .frame(width: 430, height: 430)
                    .blur(radius: 0.5)
                    .shadow(color: accentBlue.opacity(0.8), radius: 18)
                    .shadow(color: accentAmber.opacity(0.7), radius: 12)
            }
            .rotationEffect(.degrees(ringRotation))
        }
    }
}

struct GlowLogoView: View {
    let imageName: String
    let glowColor: Color
    let secondaryGlowColor: Color

    var body: some View {
        ZStack {
            Image(imageName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(glowColor.opacity(0.5))
                .blur(radius: 34)

            Image(imageName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(secondaryGlowColor.opacity(0.34))
                .blur(radius: 18)

            Image(imageName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(hex: 0xD7EBFF)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}

#Preview {
    StartView()
        .frame(width: 1920, height: 1080)
}
