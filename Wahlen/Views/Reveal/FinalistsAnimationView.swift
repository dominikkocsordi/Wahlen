import SwiftUI

struct FinalistsAnimationView: View {
    let result: ResultData
    @State private var startTime: Date = .now

    private let duration: Double = 11.0
    private let columnAreaHeight: CGFloat = 480

    private var stableCandidates: [CandidateResult] {
        result.candidates.sorted { $0.id < $1.id }
    }

    private var totalActualVotes: Double {
        Double(max(stableCandidates.reduce(0) { $0 + $1.votes }, 1))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(startTime))
            content(elapsed: elapsed)
        }
        .onAppear { startTime = .now }
    }

    // MARK: - Synchronized monotonic growth

    private func progress(_ elapsed: Double) -> Double {
        min(max(elapsed / duration, 0), 1)
    }

    private func easeInOut(_ x: Double) -> Double {
        let v = min(max(x, 0), 1)
        return v < 0.5 ? 2 * v * v : 1 - pow(-2 * v + 2, 2) / 2
    }

    /// All candidates share the same growth factor → they rise simultaneously and
    /// strictly monotonically. No bar ever decreases.
    private func growthFactor(_ elapsed: Double) -> Double {
        easeInOut(progress(elapsed))
    }

    private func displayedVotes(for candidate: CandidateResult, elapsed: Double) -> Double {
        Double(candidate.votes) * growthFactor(elapsed)
    }

    private func displayedPercent(for candidate: CandidateResult, elapsed: Double) -> Double {
        Double(candidate.votes) / totalActualVotes * 100 * growthFactor(elapsed)
    }

    /// Fraction of full column area this candidate currently occupies (0–realShare).
    private func columnFraction(for candidate: CandidateResult, elapsed: Double) -> Double {
        Double(candidate.votes) / totalActualVotes * growthFactor(elapsed)
    }

    // MARK: - Layout

    private func content(elapsed: Double) -> some View {
        VStack(spacing: 40) {
            header
            chart(elapsed: elapsed)
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 60)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("Die Auszählung läuft")
                .font(.system(size: 22, weight: .semibold))
                .tracking(6)
                .foregroundStyle(Color(hex: 0xFDEFA9))

            Text(result.session.title)
                .font(.system(size: 60, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: 1500)
        }
    }

    private func chart(elapsed: Double) -> some View {
        HStack(alignment: .bottom, spacing: 26) {
            ForEach(stableCandidates) { candidate in
                column(for: candidate, elapsed: elapsed)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func column(for candidate: CandidateResult, elapsed: Double) -> some View {
        let pct = displayedPercent(for: candidate, elapsed: elapsed)
        let displayed = displayedVotes(for: candidate, elapsed: elapsed)
        let fraction = min(max(columnFraction(for: candidate, elapsed: elapsed), 0), 1)
        let color = Theme.chartColor(for: candidate.id)
        let columnHeight = columnAreaHeight * CGFloat(fraction)

        return VStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(String(format: "%.1f %%", pct))
                    .font(.system(size: 24, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.95))
                    .contentTransition(.numericText())
                Text("\(Int(displayed.rounded()))")
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
                    .contentTransition(.numericText())
            }
            .frame(height: 60)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .frame(maxWidth: .infinity)
                    .frame(height: columnAreaHeight)

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.72)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: max(columnHeight, 0))
                    .shadow(color: color.opacity(0.45), radius: 14, x: 0, y: -2)
            }
            .frame(height: columnAreaHeight)

            Text(candidate.label)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
        }
        .frame(maxWidth: .infinity)
    }
}
