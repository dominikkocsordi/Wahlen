import SwiftUI

struct CreateElectionView: View {
    @State private var viewModel = CreateElectionViewModel()
    @Environment(\.dismiss) private var dismiss
    var onCreated: (VoteSession) -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        titleSection
                        optionsSection
                        settingsSection
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(AppFont.body(13))
                                .foregroundStyle(Theme.red)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10).fill(Theme.red.opacity(0.12))
                                )
                        }
                    }
                    .padding(28)
                }

                footer
            }
        }
        .frame(width: 720, height: 720)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Neue Wahl")
                    .font(AppFont.display(28, weight: .bold))
                    .foregroundStyle(Theme.white)
                Text("Konfigurieren Sie Titel, Kandidaten und Optionen.")
                    .font(AppFont.body(14))
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            Button("Abbrechen") { dismiss() }
                .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .background(Theme.panel)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.divider).frame(height: 1)
        }
    }

    private var titleSection: some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Titel & Beschreibung")
                LabeledField(label: "Titel") {
                    TextField("z. B. Wahl zum Vorstand", text: $viewModel.title)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Theme.panelElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Theme.white)
                        .font(AppFont.body(15, weight: .medium))
                }
                LabeledField(label: "Beschreibung (optional, nur Admin-Notiz)") {
                    TextField("Kontext für die Wahl", text: $viewModel.description, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Theme.panelElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Theme.white)
                        .font(AppFont.body(14))
                }
            }
        }
    }

    private var optionsSection: some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(title: "Kandidaten · Optionen", accent: Theme.turquoise)
                    Button {
                        viewModel.addOption()
                    } label: {
                        Label("Hinzufügen", systemImage: "plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                ForEach(Array(viewModel.options.enumerated()), id: \.offset) { idx, _ in
                    HStack(spacing: 10) {
                        Text("\(idx + 1).")
                            .font(AppFont.mono(15, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                            .frame(width: 28, alignment: .leading)
                        TextField("Option \(idx + 1)", text: $viewModel.options[idx])
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Theme.panelElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Theme.white)
                        Button {
                            viewModel.removeOption(at: idx)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(viewModel.options.count > 2 ? Theme.red : Theme.muted)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.options.count <= 2)
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Einstellungen", accent: Theme.yellow)
                LabeledField(label: "Teilnehmerlimit (optional)") {
                    TextField("z. B. 80", text: $viewModel.participantLimit)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Theme.panelElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Theme.white)
                }
                Toggle(isOn: $viewModel.allowDelegation) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stimmübertragungen erlauben")
                            .font(AppFont.body(15, weight: .semibold))
                            .foregroundStyle(Theme.white)
                        Text("Teilnehmer können ihre Stimme delegieren.")
                            .font(AppFont.body(13))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .tint(Theme.turquoise)

                Toggle(isOn: $viewModel.resultsHidden) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ergebnisse zunächst verborgen")
                            .font(AppFont.body(15, weight: .semibold))
                            .foregroundStyle(Theme.white)
                        Text("Der Beamer zeigt die Ergebnisse erst nach Freigabe.")
                            .font(AppFont.body(13))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .tint(Theme.turquoise)
            }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Wahl anlegen") {
                Task {
                    if let session = await viewModel.submit() {
                        onCreated(session)
                        dismiss()
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.turquoise))
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(Theme.panel)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.divider).frame(height: 1)
        }
    }
}

private struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(AppFont.body(11, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Theme.muted)
            content()
        }
    }
}
