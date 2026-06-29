import SwiftUI

struct ResultsView: View {
    let result: ResultData

    private var winner: CandidateResult? { result.candidates.first(where: { $0.votes > 0 }) }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                header

                HStack(alignment: .top, spacing: 32) {
                    leftTable
                    rightChart
                }

                bottomStats
            }
            .padding(.horizontal, 64)
            .padding(.vertical, 48)
        }
        .transition(.opacity)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ergebnis")
                    .font(AppFont.body(18, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(Theme.turquoise)
                Text(result.session.title)
                    .font(AppFont.display(64, weight: .heavy))
                    .foregroundStyle(Theme.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)
            }
            Spacer()
            validityBadge
        }
    }

    @ViewBuilder
    private var validityBadge: some View {
        if let valid = result.session.isValid {
            HStack(spacing: 12) {
                Image(systemName: valid ? "checkmark.seal.fill" : "exclamationmark.octagon.fill")
                    .font(.system(size: 28, weight: .bold))
                Text(valid ? "GÜLTIG" : "UNGÜLTIG")
                    .font(AppFont.display(28, weight: .heavy))
                    .tracking(3)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .foregroundStyle(valid ? Theme.background : Theme.white)
            .background(
                Capsule().fill(valid ? Theme.turquoise : Theme.red)
            )
        }
    }

    private var leftTable: some View {
        PanelCard(padding: 24) {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Kandidat · Stimmen · Prozent", accent: Theme.turquoise)

                HStack {
                    Text("Kandidat").font(AppFont.body(13, weight: .semibold)).tracking(1.2)
                    Spacer()
                    Text("Stimmen").font(AppFont.body(13, weight: .semibold)).tracking(1.2)
                        .frame(width: 100, alignment: .trailing)
                    Text("Prozent").font(AppFont.body(13, weight: .semibold)).tracking(1.2)
                        .frame(width: 100, alignment: .trailing)
                }
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 8)

                Divider().background(Theme.divider)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(result.candidates) { candidate in
                            resultRow(candidate)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func resultRow(_ candidate: CandidateResult) -> some View {
        let isWinner = candidate.id == winner?.id
        return HStack(spacing: 14) {
            Circle()
                .fill(Theme.chartColor(for: candidate.id))
                .frame(width: 14, height: 14)
            Text(candidate.label)
                .font(AppFont.title(20, weight: isWinner ? .bold : .semibold))
                .foregroundStyle(Theme.white)
                .lineLimit(1)
            Spacer()
            Text("\(candidate.votes)")
                .font(AppFont.mono(22, weight: .semibold))
                .foregroundStyle(isWinner ? Theme.turquoise : Theme.white)
                .frame(width: 100, alignment: .trailing)
            Text(String(format: "%.1f %%", candidate.percent))
                .font(AppFont.mono(22, weight: .medium))
                .foregroundStyle(Theme.muted)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isWinner ? Theme.panelElevated : Color.clear)
        )
    }

    private var rightChart: some View {
        PanelCard(padding: 24) {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Verteilung", accent: Theme.lightBlue)
                DonutChartView(candidates: result.candidates)
                    .frame(height: 360)
                VStack(spacing: 10) {
                    ForEach(result.candidates.prefix(6)) { c in
                        HStack(spacing: 10) {
                            Circle().fill(Theme.chartColor(for: c.id)).frame(width: 10, height: 10)
                            Text(c.label)
                                .font(AppFont.body(14, weight: .medium))
                                .foregroundStyle(Theme.white)
                                .lineLimit(1)
                            Spacer()
                            Text(String(format: "%.1f %%", c.percent))
                                .font(AppFont.mono(14, weight: .semibold))
                                .foregroundStyle(Theme.muted)
                        }
                    }
                }
            }
        }
        .frame(width: 460)
    }

    private var bottomStats: some View {
        HStack(spacing: 16) {
            StatCardView(title: "Abgegebene Stimmen",
                         value: "\(result.totalVotes)",
                         tint: Theme.lightBlue, compact: true)
            StatCardView(title: "Gültige Stimmen",
                         value: "\(result.validVotes)",
                         tint: Theme.turquoise, compact: true)
            StatCardView(title: "Ungültige Stimmen",
                         value: "\(result.invalidVotes)",
                         tint: Theme.red, compact: true)
            if let limit = result.participantLimit {
                StatCardView(title: "Teilnehmerlimit",
                             value: "\(limit)",
                             tint: Theme.lightBlue, compact: true)
            }
            if let nonVoters = result.nonVoters {
                StatCardView(title: "Nicht abgestimmt",
                             value: "\(nonVoters)",
                             tint: Theme.yellow, compact: true)
            }
            StatCardView(title: "Übertragungen",
                         value: "\(result.delegationCount)",
                         tint: Theme.turquoise, compact: true)
        }
    }
}
