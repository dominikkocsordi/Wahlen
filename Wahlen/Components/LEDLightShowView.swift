import SwiftUI

struct LEDLightShowView: View {
    var intensity: Double = 1.0

    private let palette: [Color] = [
        Color(hex: 0x276BB0),
        Color(hex: 0x4ED6C5),
        Color(hex: 0xFFD75A),
        Color(hex: 0xFFFFFF),
        Color(hex: 0x5A95CC)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 0) {
                bar(time: t, sideSign: -1)
                Spacer(minLength: 0)
                bar(time: t, sideSign: 1)
            }
            .ignoresSafeArea()
            .blendMode(.plusLighter)
            .opacity(intensity)
            .allowsHitTesting(false)
        }
    }

    private func bar(time t: Double, sideSign: Double) -> some View {
        Canvas(rendersAsynchronously: true) { context, size in
            let segments = 14
            let segmentHeight = size.height / Double(segments)
            for i in 0..<segments {
                let phase = sin(t * 1.1 + Double(i) * 0.45 + sideSign * 0.6) * 0.5 + 0.5
                let glowMix = (sin(t * 0.6 + Double(i) * 0.3) * 0.5 + 0.5)
                let colorA = palette[(Int(t * 0.4) + i) % palette.count]
                let colorB = palette[(Int(t * 0.4) + i + 2) % palette.count]
                let color = colorA.mixed(with: colorB, by: glowMix)

                let inset: Double = 16
                let rect = CGRect(
                    x: inset,
                    y: Double(i) * segmentHeight + 6,
                    width: size.width - inset * 2,
                    height: max(segmentHeight - 12, 4)
                )

                var ctx = context
                ctx.opacity = 0.55 + phase * 0.45
                ctx.addFilter(.blur(radius: 12 + phase * 8))
                ctx.fill(Path(roundedRect: rect, cornerRadius: 8), with: .color(color))

                var coreContext = context
                coreContext.opacity = 0.9 * phase
                coreContext.fill(
                    Path(roundedRect: rect.insetBy(dx: 6, dy: 4), cornerRadius: 6),
                    with: .color(color)
                )
            }
        }
        .frame(width: 90)
    }
}

private extension Color {
    func mixed(with other: Color, by amount: Double) -> Color {
        let a = NSColor(self).usingColorSpace(.sRGB) ?? .white
        let b = NSColor(other).usingColorSpace(.sRGB) ?? .white
        let k = CGFloat(min(max(amount, 0), 1))
        let r = a.redComponent + (b.redComponent - a.redComponent) * k
        let g = a.greenComponent + (b.greenComponent - a.greenComponent) * k
        let bl = a.blueComponent + (b.blueComponent - a.blueComponent) * k
        return Color(.sRGB, red: r, green: g, blue: bl, opacity: 1)
    }
}
