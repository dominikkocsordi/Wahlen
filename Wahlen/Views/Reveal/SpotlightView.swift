import SwiftUI

struct SpotlightView: View {
    @State private var dim: Double = 0.0
    @State private var beamAngle: Double = -8

    var body: some View {
        ZStack {
            Color.black.opacity(dim).ignoresSafeArea()

            ConeBeam()
                .fill(RadialGradient(
                    colors: [
                        Color.white.opacity(0.16),
                        Color(hex: 0xFFD75A).opacity(0.10),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 60,
                    endRadius: 900
                ))
                .frame(width: 1200, height: 1400)
                .rotationEffect(.degrees(beamAngle))
                .offset(y: -200)
                .blendMode(.plusLighter)

            VStack(spacing: 24) {
                Text("Ergebnis wird ermittelt")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.white, Color(hex: 0xFFD75A)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .shadow(color: Color(hex: 0xFFD75A).opacity(0.45), radius: 30)
                    .multilineTextAlignment(.center)

                Text("Bitte einen Moment Geduld")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                dim = 0.82
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                beamAngle = 8
            }
        }
    }
}

private struct ConeBeam: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY * 0.78)
        )
        path.closeSubpath()
        return path
    }
}
