import SwiftUI

struct BallotPreviewView: View {
    let session: VoteSession

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 36) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Wahlzettel")
                        .font(AppFont.body(18, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Theme.turquoise)

                    Text(session.title)
                        .font(AppFont.display(80, weight: .heavy))
                        .foregroundStyle(Theme.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)

                    HStack(spacing: 18) {
                        InfoChip(icon: "checkmark.circle.fill",
                                 text: "1 Stimme pro Person")
                        if session.allowDelegation {
                            InfoChip(icon: "arrow.triangle.2.circlepath",
                                     text: "Stimmübertragung erlaubt",
                                     tint: Theme.yellow)
                        }
                        if let limit = session.participantLimit {
                            InfoChip(icon: "person.2.fill",
                                     text: "Teilnehmerlimit: \(limit)",
                                     tint: Theme.lightBlue)
                        }
                    }
                }

                SectionHeader(title: "Kandidaten · Optionen", accent: Theme.turquoise)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(Array(session.options.enumerated()), id: \.offset) { idx, label in
                            CandidateRowView(
                                index: idx,
                                label: label,
                                votes: nil,
                                percent: nil,
                                highlight: false
                            )
                        }
                    }
                }

                Spacer(minLength: 0)

                Text("Bereit für die Stimmabgabe")
                    .font(AppFont.body(20, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 90)
            .padding(.vertical, 70)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}

private struct InfoChip: View {
    let icon: String
    let text: String
    var tint: Color = Theme.turquoise

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(AppFont.body(16, weight: .medium))
                .foregroundStyle(Theme.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule().fill(Theme.panel)
        )
        .overlay(
            Capsule().stroke(tint.opacity(0.4), lineWidth: 1)
        )
    }
}
