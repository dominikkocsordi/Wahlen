import SwiftUI

struct AdminDashboardView: View {
    @State private var viewModel = AdminViewModel()
    @State private var store = ElectionStore.shared
    @State private var deleteCandidate: VoteSession?
    @State private var groups: [VoterGroup] = []
    @State private var slides = SlideService.shared
    @State private var showAgendaSheet = false

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 300, ideal: 340, max: 420)
        } detail: {
            detail
        }
        .preferredColorScheme(.dark)
        .background(Theme.background)
        .task {
            await store.bootstrap()
            viewModel.selectFirstIfNeeded()
            groups = (try? await ElectionService.shared.fetchGroups()) ?? []
        }
        .onChange(of: store.sessions.count) { _, _ in
            viewModel.ensureSelectionValid()
            viewModel.selectFirstIfNeeded()
        }
        .sheet(isPresented: $viewModel.isPresentingCreate) {
            CreateElectionView { session in
                viewModel.selectedSessionId = session.id
            }
        }
        .sheet(isPresented: $showAgendaSheet) {
            AgendaManagementView()
        }
        .alert("Wahl löschen?",
               isPresented: Binding(
                get: { deleteCandidate != nil },
                set: { if !$0 { deleteCandidate = nil } }
               ),
               presenting: deleteCandidate) { session in
            Button("Löschen", role: .destructive) {
                Task { await viewModel.delete(session: session) }
                deleteCandidate = nil
            }
            Button("Abbrechen", role: .cancel) { deleteCandidate = nil }
        } message: { session in
            Text("«\(session.title)» und alle abgegebenen Stimmen werden unwiderruflich gelöscht.")
        }
        .alert("Fehler",
               isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
               ),
               presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
            programSection
            Divider().background(Theme.divider)

            if store.isLoading && store.sessions.isEmpty {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.loadError != nil && store.sessions.isEmpty {
                connectionErrorView
            } else {
                List(selection: $viewModel.selectedSessionId) {
                    Section {
                        ForEach(store.sessions) { session in
                            sidebarRow(session: session)
                                .tag(session.id as UUID?)
                        }
                    } header: {
                        Text("Wahlen")
                            .font(AppFont.body(12, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.muted)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Theme.background)
            }
        }
        .background(Theme.background)
    }

    private var programSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("PROGRAMM")
                    .font(AppFont.body(11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.muted)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 8)

            VStack(spacing: 3) {
                programRow(icon: "film", title: "Intro abspielen",
                           active: store.presentationState == .intro) {
                    store.presentationState = .intro
                }

                programRow(icon: "rectangle.on.rectangle.angled",
                           title: slides.hasDocument ? "Folien steuern" : "Keine Folien geladen",
                           active: store.presentationState == .slides) {
                    if slides.hasDocument {
                        store.presentationState = .slides
                    } else {
                        slides.presentOpenPanel()
                        if slides.hasDocument { store.presentationState = .slides }
                    }
                }

                if store.presentationState == .slides && slides.hasDocument {
                    slidesNavRow
                }

                programRow(icon: "list.number", title: "Tagesordnung verwalten",
                           active: false) {
                    showAgendaSheet = true
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
    }

    private var slidesNavRow: some View {
        HStack(spacing: 8) {
            Button { slides.previous() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(slides.canGoPrevious ? Theme.white : Theme.muted)
            .disabled(!slides.canGoPrevious)

            Spacer()

            Text("\(slides.currentSlideNumber) / \(slides.totalSlides)")
                .font(AppFont.mono(12))
                .foregroundStyle(Theme.muted)

            Spacer()

            Button { slides.next() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(slides.canGoNext ? Theme.white : Theme.muted)
            .disabled(!slides.canGoNext)

            Button { slides.presentOpenPanel() } label: {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.muted)
            .help("Andere PDF öffnen")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.panelElevated)
        )
        .padding(.horizontal, 2)
    }

    private func programRow(icon: String, title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(active ? Theme.turquoise : Theme.white.opacity(0.65))
                    .frame(width: 22)
                Text(title)
                    .font(AppFont.body(13, weight: active ? .semibold : .regular))
                    .foregroundStyle(active ? Theme.white : Theme.white.opacity(0.8))
                    .lineLimit(1)
                Spacer()
                if active {
                    Circle()
                        .fill(Theme.turquoise)
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(active ? Theme.panelElevated : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var connectionErrorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.red)
            Text("Verbindungsfehler")
                .font(AppFont.body(14, weight: .semibold))
                .foregroundStyle(Theme.white)
            Text(store.loadError ?? "")
                .font(AppFont.body(11))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .lineLimit(5)
                .frame(maxWidth: 260)
            Button {
                Task { await store.loadSessions() }
            } label: {
                Label("Erneut laden", systemImage: "arrow.clockwise")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FSBS Wahlen")
                .font(AppFont.display(22, weight: .bold))
                .foregroundStyle(Theme.white)
            Text("Wahlleitung")
                .font(AppFont.body(13, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)

            Button {
                viewModel.isPresentingCreate = true
            } label: {
                Label("Neue Wahl", systemImage: "plus.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.turquoise))
            .padding(.top, 12)

            Button {
                viewModel.returnToIdle()
            } label: {
                Label("Beamer zurücksetzen", systemImage: "tv")
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.divider).frame(height: 1)
        }
    }

    private func sidebarRow(session: VoteSession) -> some View {
        let phase = viewModel.currentPhase(for: session)
        return VStack(alignment: .leading, spacing: 6) {
            Text(session.title.isEmpty ? "Ohne Titel" : session.title)
                .font(AppFont.body(15, weight: .semibold))
                .foregroundStyle(Theme.white)
                .lineLimit(2)
            HStack {
                StatusBadgeView(phase: phase)
                Spacer()
                Text("\(session.options.count) Optionen")
                    .font(AppFont.body(11, weight: .medium))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(.vertical, 6)
    }

    private var detail: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if let session = viewModel.selectedSession {
                detailContent(for: session)
            } else {
                emptyState
            }
        }
    }

    private func detailContent(for session: VoteSession) -> some View {
        let phase = viewModel.currentPhase(for: session)
        let result = ResultData.build(session: session, votes: store.votes(for: session.id))
        return ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                detailHeader(session: session, phase: phase)
                controlPanel(session: session, phase: phase)
                metaPanel(session: session, result: result)
                groupPanel(session: session)
                validityPanel(session: session)
                if session.allowDelegation {
                    delegationsPanel(result: result)
                }
                resultPreview(session: session, result: result)
            }
            .padding(28)
        }
    }

    private func detailHeader(session: VoteSession, phase: AdminElectionPhase) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.title)
                    .font(AppFont.display(34, weight: .bold))
                    .foregroundStyle(Theme.white)
                HStack(spacing: 10) {
                    StatusBadgeView(phase: phase)
                    Text("Token: \(session.token)")
                        .font(AppFont.mono(13, weight: .medium))
                        .foregroundStyle(Theme.muted)
                }
            }
            Spacer()
            Menu {
                Button("Duplizieren") {
                    Task { await viewModel.duplicate(session: session) }
                }
                Button("Archivieren") {
                    Task { await viewModel.archive(session: session) }
                }
                Divider()
                Button("Löschen", role: .destructive) {
                    deleteCandidate = session
                }
            } label: {
                Label("Aktionen", systemImage: "ellipsis.circle")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func controlPanel(session: VoteSession, phase: AdminElectionPhase) -> some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Beamer-Steuerung")
                HStack(spacing: 12) {
                    Button {
                        viewModel.showBallotPreview(session: session)
                    } label: { Label("Wahlzettel anzeigen", systemImage: "doc.text") }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        Task { await viewModel.openVoting(session: session) }
                    } label: { Label("Wahlgang öffnen", systemImage: "play.circle.fill") }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.turquoise))

                    Button {
                        Task { await viewModel.closeVoting(session: session) }
                    } label: { Label("Wahl schließen", systemImage: "lock.fill") }
                    .buttonStyle(SecondaryButtonStyle(tint: Theme.yellow))

                    Button {
                        Task { await viewModel.showResults(session: session) }
                    } label: { Label("Ergebnisse anzeigen", systemImage: "chart.pie.fill") }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.lightBlue))
                }
            }
        }
    }

    private func metaPanel(session: VoteSession, result: ResultData) -> some View {
        HStack(spacing: 14) {
            StatCardView(title: "Optionen",
                         value: "\(session.options.count)",
                         tint: Theme.lightBlue, compact: true)
            StatCardView(title: "Stimmen",
                         value: "\(result.totalVotes)",
                         subtitle: "Aktuell",
                         tint: Theme.turquoise, compact: true)
            StatCardView(title: "Gültig",
                         value: "\(result.validVotes)",
                         tint: Theme.turquoise, compact: true)
            StatCardView(title: "Ungültig",
                         value: "\(result.invalidVotes)",
                         tint: Theme.red, compact: true)
            if let limit = session.participantLimit {
                StatCardView(title: "Limit",
                             value: "\(limit)",
                             tint: Theme.lightBlue, compact: true)
            }
            StatCardView(title: "Übertragungen",
                         value: "\(result.delegationCount)",
                         tint: Theme.yellow, compact: true)
        }
    }

    private func groupPanel(session: VoteSession) -> some View {
        let assigned = groups.filter { $0.sessionId == session.id }
        return PanelCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Wahlberechtigte Gruppen", accent: Theme.lightBlue)
                if assigned.isEmpty {
                    Text("Keine Gruppe zugeordnet. Gruppen lassen sich im Tab «Gruppen & Codes» verwalten.")
                        .font(AppFont.body(14))
                        .foregroundStyle(Theme.muted)
                } else {
                    ForEach(assigned) { group in
                        HStack(spacing: 10) {
                            Image(systemName: "person.3.fill")
                                .foregroundStyle(Theme.lightBlue)
                            Text(group.name)
                                .font(AppFont.body(15, weight: .medium))
                                .foregroundStyle(Theme.white)
                            Spacer()
                            Text("zugeordnet")
                                .font(AppFont.body(11))
                                .foregroundStyle(Theme.turquoise)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .task(id: session.id) {
            groups = (try? await ElectionService.shared.fetchGroups()) ?? []
        }
    }

    private func validityPanel(session: VoteSession) -> some View {
        PanelCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: "Gültigkeit der Wahl", accent: Theme.yellow)
                    Text(validityText(session: session))
                        .font(AppFont.body(14))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                HStack(spacing: 10) {
                    Button("Gültig") {
                        Task { await viewModel.setValidity(session: session, valid: true) }
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.turquoise))
                    Button("Ungültig") {
                        Task { await viewModel.setValidity(session: session, valid: false) }
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }
            }
        }
    }

    private func validityText(session: VoteSession) -> String {
        switch session.isValid {
        case .some(true): return "Wahl ist als gültig markiert. Beamer zeigt das Siegel."
        case .some(false): return "Wahl ist als ungültig markiert. Beamer zeigt den Hinweis."
        case .none: return "Noch nicht entschieden. Setzen Sie nach Prüfung den Status."
        }
    }

    private func delegationsPanel(result: ResultData) -> some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Stimmübertragungen", accent: Theme.turquoise)
                if result.delegations.isEmpty {
                    Text("Bisher keine Übertragungen erfasst.")
                        .font(AppFont.body(14))
                        .foregroundStyle(Theme.muted)
                } else {
                    ForEach(result.delegations) { entry in
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .foregroundStyle(Theme.turquoise)
                            Text(entry.name)
                                .font(AppFont.body(15, weight: .medium))
                                .foregroundStyle(Theme.white)
                            Spacer()
                            Text("\(entry.count)")
                                .font(AppFont.mono(15, weight: .semibold))
                                .foregroundStyle(Theme.turquoise)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func resultPreview(session: VoteSession, result: ResultData) -> some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Live-Vorschau Ergebnis")
                if result.totalVotes == 0 {
                    Text("Noch keine Stimmen erfasst.")
                        .font(AppFont.body(14))
                        .foregroundStyle(Theme.muted)
                } else {
                    ForEach(result.candidates) { candidate in
                        CandidateRowView(
                            index: candidate.id,
                            label: candidate.label,
                            votes: candidate.votes,
                            percent: candidate.percent,
                            highlight: candidate.id == result.candidates.first?.id && candidate.votes > 0,
                            compact: true
                        )
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Theme.muted)
            Text("Keine Wahl ausgewählt")
                .font(AppFont.display(26, weight: .semibold))
                .foregroundStyle(Theme.white)
            Text("Legen Sie links eine neue Wahl an oder wählen Sie eine bestehende aus.")
                .font(AppFont.body(15))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)
            Button {
                viewModel.isPresentingCreate = true
            } label: {
                Label("Wahl erstellen", systemImage: "plus")
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.turquoise))
        }
        .padding(40)
    }
}
