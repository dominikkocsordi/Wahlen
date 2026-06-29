import SwiftUI

struct CelebrationView: View {
    let winner: CandidateResult

    @State private var confettiActive: Bool = false
    @State private var burstTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x06163A), Color(hex: 0x0E2A5C), Color(hex: 0x163C7D)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            WinnerCardView(winner: winner)
                .padding(.horizontal, 60)

            ConfettiView(isFiring: confettiActive, particleCount: 520)
                .ignoresSafeArea()
        }
        .onAppear {
            confettiActive = true
            burstTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(8))
                while !Task.isCancelled {
                    confettiActive = false
                    try? await Task.sleep(for: .milliseconds(60))
                    if Task.isCancelled { return }
                    confettiActive = true
                    try? await Task.sleep(for: .seconds(8))
                }
            }
        }
        .onDisappear {
            burstTask?.cancel()
            burstTask = nil
            confettiActive = false
        }
    }
}
