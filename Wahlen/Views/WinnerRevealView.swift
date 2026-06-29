import SwiftUI

struct WinnerRevealView: View {
    let result: ResultData
    var onCompleted: (() -> Void)? = nil

    @State private var phase: Phase = .confirmed
    @State private var orchestrationTask: Task<Void, Never>?

    enum Phase: Equatable { case confirmed, finalists, celebration }

    private let confirmedDuration: TimeInterval = 1.9
    private let finalistsDuration: TimeInterval = 11
    private let celebrationDuration: TimeInterval = 30

    private var winner: CandidateResult? {
        result.candidates.max { $0.votes < $1.votes }
    }

    var body: some View {
        ZStack {
            backdrop

            switch phase {
            case .confirmed:
                ConfirmedCheckView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                        removal: .opacity.combined(with: .scale(scale: 1.12))
                    ))
            case .finalists:
                FinalistsAnimationView(result: result)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 0.96))
                    ))
            case .celebration:
                if let winner = winner {
                    CelebrationView(winner: winner)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.94)),
                            removal: .opacity.combined(with: .scale(scale: 1.05))
                        ))
                } else {
                    Text("Keine Stimmen erfasst.")
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
        }
        .animation(.spring(response: 0.75, dampingFraction: 0.82), value: phase)
        .onAppear { start() }
        .onDisappear {
            orchestrationTask?.cancel()
            MusicService.shared.stopAll()
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [Color(hex: 0x06163A), Color(hex: 0x163C7D), Color(hex: 0x276BB0)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func start() {
        orchestrationTask?.cancel()
        phase = .confirmed
        MusicService.shared.playReveal()

        orchestrationTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(confirmedDuration))
            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.75, dampingFraction: 0.82)) {
                phase = .finalists
            }
            try? await Task.sleep(for: .seconds(finalistsDuration))
            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.85, dampingFraction: 0.8)) {
                phase = .celebration
            }
            try? await Task.sleep(for: .seconds(celebrationDuration))
            guard !Task.isCancelled else { return }
            onCompleted?()
        }
    }
}
