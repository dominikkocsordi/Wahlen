import SwiftUI
import Charts

struct DonutChartView: View {
    let candidates: [CandidateResult]
    var innerRatio: Double = 0.62

    private var displayItems: [CandidateResult] {
        let nonZero = candidates.filter { $0.votes > 0 }
        return nonZero.isEmpty ? candidates : nonZero
    }

    private var topLabel: String {
        guard let top = candidates.max(by: { $0.votes < $1.votes }), top.votes > 0 else {
            return "—"
        }
        return top.label
    }

    private var topPercent: String {
        guard let top = candidates.max(by: { $0.votes < $1.votes }), top.votes > 0 else {
            return "0 %"
        }
        return String(format: "%.1f %%", top.percent)
    }

    var body: some View {
        ZStack {
            Chart(displayItems) { item in
                SectorMark(
                    angle: .value("Stimmen", max(item.votes, 0)),
                    innerRadius: .ratio(innerRatio),
                    angularInset: 2.0
                )
                .cornerRadius(6)
                .foregroundStyle(Theme.chartColor(for: item.id))
            }
            .chartLegend(.hidden)

            VStack(spacing: 4) {
                Text("Vorne")
                    .font(AppFont.body(13, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(Theme.muted)
                Text(topLabel)
                    .font(AppFont.display(22, weight: .bold))
                    .foregroundStyle(Theme.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
                Text(topPercent)
                    .font(AppFont.mono(28, weight: .semibold))
                    .foregroundStyle(Theme.turquoise)
            }
            .padding(.horizontal, 12)
        }
    }
}

struct BarChartView: View {
    let candidates: [CandidateResult]

    var body: some View {
        Chart(candidates) { item in
            BarMark(
                x: .value("Stimmen", item.votes),
                y: .value("Kandidat", item.label)
            )
            .cornerRadius(6)
            .foregroundStyle(Theme.chartColor(for: item.id))
        }
        .chartXAxis {
            AxisMarks(values: .automatic) {
                AxisGridLine().foregroundStyle(Theme.divider)
                AxisTick().foregroundStyle(Theme.muted)
                AxisValueLabel().foregroundStyle(Theme.muted)
            }
        }
        .chartYAxis {
            AxisMarks(preset: .extended, position: .leading) { _ in
                AxisValueLabel().foregroundStyle(Theme.white)
            }
        }
    }
}

struct ResultChartView: View {
    let candidates: [CandidateResult]

    var body: some View {
        VStack(spacing: 24) {
            DonutChartView(candidates: candidates)
                .frame(height: 320)
            BarChartView(candidates: candidates)
                .frame(height: 220)
        }
    }
}
