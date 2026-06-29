import SwiftUI

struct CountdownView: View {
    var onFinished: () -> Void

    @State private var current: Int = 3
    @State private var pulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(LinearGradient(
                    colors: [Color(hex: 0xFFD75A), Color(hex: 0x4ED6C5), Color(hex: 0x5A95CC)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 4)
                .frame(width: 520, height: 520)
                .scaleEffect(pulse)
                .opacity(0.45)

            Text("\(current)")
                .font(.system(size: 340, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(
                    colors: [Color(hex: 0xFFD75A), Color(hex: 0xFFFFFF)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .shadow(color: Color(hex: 0xFFD75A).opacity(0.55), radius: 60)
                .contentTransition(.numericText(countsDown: true))
                .id("countdown-\(current)")
                .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
        .task {
            for n in (1...3).reversed() {
                withAnimation(.easeOut(duration: 0.3)) { current = n }
                withAnimation(.easeOut(duration: 0.6).repeatCount(1, autoreverses: true)) {
                    pulse = 1.18
                }
                try? await Task.sleep(for: .seconds(1))
                pulse = 1.0
            }
            onFinished()
        }
    }
}
