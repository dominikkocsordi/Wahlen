import SwiftUI

struct ConfettiView: View {
    var isFiring: Bool
    var particleCount: Int = 520

    @State private var particles: [ConfettiParticle] = []
    @State private var startTime: Date = .now

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: particles.isEmpty)) { timeline in
            Canvas(rendersAsynchronously: true) { context, size in
                guard !particles.isEmpty else { return }
                let elapsed = timeline.date.timeIntervalSince(startTime)
                let gravity = 320.0
                let drag = 0.22

                for particle in particles {
                    let t = elapsed - particle.delay
                    guard t >= 0, t <= particle.lifetime else { continue }

                    let dragFactor = exp(-drag * t)
                    let dx = particle.velocity.dx * (1 - dragFactor) / drag
                    let dy = particle.velocity.dy * (1 - dragFactor) / drag
                    let fall = 0.5 * gravity * t * t

                    let x = size.width * particle.startX + dx
                    let y = -40 + dy + fall
                    if y > size.height + 60 { continue }

                    let rotation = particle.rotationSpeed * t
                    let life = min(1.0, t / particle.lifetime)
                    let fade: Double = life > 0.85 ? max(0, 1 - (life - 0.85) / 0.15) : 1.0

                    var localContext = context
                    localContext.opacity = fade
                    localContext.translateBy(x: x, y: y)
                    localContext.rotate(by: .degrees(rotation))

                    let w = particle.size.width
                    let h = particle.size.height
                    let rect = CGRect(x: -w/2, y: -h/2, width: w, height: h)
                    let path: Path
                    switch particle.shape {
                    case .rectangle:
                        path = Path(roundedRect: rect, cornerRadius: 2)
                    case .circle:
                        path = Path(ellipseIn: rect)
                    case .triangle:
                        var p = Path()
                        p.move(to: CGPoint(x: 0, y: -h/2))
                        p.addLine(to: CGPoint(x: w/2, y: h/2))
                        p.addLine(to: CGPoint(x: -w/2, y: h/2))
                        p.closeSubpath()
                        path = p
                    case .ribbon:
                        let phase = sin(t * 6 + particle.delay) * 6
                        var p = Path()
                        p.move(to: CGPoint(x: -w/2, y: -h/2 + phase))
                        p.addQuadCurve(to: CGPoint(x: w/2, y: h/2 - phase),
                                       control: CGPoint(x: 0, y: 0))
                        path = p.strokedPath(.init(lineWidth: 3, lineCap: .round))
                    }
                    localContext.fill(path, with: .color(particle.color))
                }
            }
        }
        .onChange(of: isFiring) { _, new in
            if new { ignite() } else { particles = [] }
        }
        .onAppear { if isFiring { ignite() } }
        .allowsHitTesting(false)
    }

    private func ignite() {
        startTime = .now
        let palette: [Color] = [
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
            Color.white
        ]
        particles = (0..<particleCount).map { _ in
            ConfettiParticle.random(palette: palette)
        }
    }
}

struct ConfettiParticle: Identifiable, Sendable {
    enum Shape: CaseIterable, Sendable { case rectangle, circle, triangle, ribbon }
    let id = UUID()
    let color: Color
    let startX: Double
    let velocity: CGVector
    let rotationSpeed: Double
    let shape: Shape
    let size: CGSize
    let delay: TimeInterval
    let lifetime: TimeInterval

    static func random(palette: [Color]) -> ConfettiParticle {
        let originBias = Double.random(in: -0.05...1.05)
        let burstAngle = Double.random(in: -.pi / 2 ... .pi / 2)
        let speed = Double.random(in: 220...640)
        let vx = cos(burstAngle) * speed * (Bool.random() ? 1 : -1) * 0.35
        let vy = -abs(sin(burstAngle)) * speed * 0.55 - Double.random(in: 60...260)
        let baseSize = CGFloat.random(in: 8...18)
        let aspect = CGFloat.random(in: 0.55...1.6)
        return ConfettiParticle(
            color: palette.randomElement() ?? .white,
            startX: max(0, min(1, originBias)),
            velocity: CGVector(dx: vx, dy: vy),
            rotationSpeed: Double.random(in: 220...780) * (Bool.random() ? 1 : -1),
            shape: Shape.allCases.randomElement() ?? .rectangle,
            size: CGSize(width: baseSize * aspect, height: baseSize),
            delay: Double.random(in: 0...1.8),
            lifetime: Double.random(in: 4.5...7.5)
        )
    }
}
