import SwiftUI

struct GroupManagementView: View {
    @State private var vm = GroupManagementViewModel()
    @State private var store = ElectionStore.shared
    @State private var deleteCandidate: VoterGroup?
    @State private var showingAssignSheet = false

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 360)
        } detail: {
            detail
        }
        .preferredColorScheme(.dark)
        .background(Theme.background)
        .task {
            await store.bootstrap()
            await vm.loadGroups()
        }
        .alert("Gruppe löschen?",
               isPresented: Binding(
                get: { deleteCandidate != nil },
                set: { if !$0 { deleteCandidate = nil } }
               ),
               presenting: deleteCandidate) { group in
            Button("Löschen", role: .destructive) {
                Task { await vm.deleteGroup(group) }
                deleteCandidate = nil
            }
            Button("Abbrechen", role: .cancel) { deleteCandidate = nil }
        } message: { group in
            Text("Gruppe «\(group.name)» und alle \(group.name) Codes werden unwiderruflich gelöscht.")
        }
        .alert("Fehler",
               isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
               ),
               presenting: vm.errorMessage) { _ in
            Button("OK", role: .cancel) { vm.errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
            if vm.groups.isEmpty {
                emptyGroupList
            } else {
                List(selection: Binding(
                    get: { vm.selectedGroup?.id },
                    set: { id in
                        if let id, let g = vm.groups.first(where: { $0.id == id }) {
                            Task { await vm.selectGroup(g) }
                        }
                    }
                )) {
                    Section {
                        ForEach(vm.groups) { group in
                            groupRow(group: group)
                                .tag(group.id as UUID?)
                                .contextMenu {
                                    Button("Löschen", role: .destructive) {
                                        deleteCandidate = group
                                    }
                                }
                        }
                    } header: {
                        Text("Gruppen")
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

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gruppen & Codes")
                .font(AppFont.display(20, weight: .bold))
                .foregroundStyle(Theme.white)
            Text("Wahlberechtigte")
                .font(AppFont.body(12, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            createForm
        }
        .padding(16)
        .background(Theme.panel)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.divider).frame(height: 1)
        }
    }

    private var createForm: some View {
        VStack(spacing: 8) {
            TextField("Gruppenname", text: $vm.newGroupName)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 8) {
                TextField("Anzahl Codes", text: $vm.newGroupCodeCount)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                Button {
                    Task { await vm.createGroup() }
                } label: {
                    if vm.isSubmitting {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Erstellen", systemImage: "plus.circle.fill")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.turquoise))
                .disabled(vm.isSubmitting || vm.newGroupName.isEmpty || vm.newGroupCodeCount.isEmpty)
            }
        }
    }

    private var emptyGroupList: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.muted)
            Text("Noch keine Gruppen")
                .font(AppFont.body(15))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func groupRow(group: VoterGroup) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.name)
                .font(AppFont.body(14, weight: .semibold))
                .foregroundStyle(Theme.white)
            if let sid = group.sessionId,
               let session = store.sessions.first(where: { $0.id == sid }) {
                Label(session.title.isEmpty ? "Ohne Titel" : session.title,
                      systemImage: "checkmark.seal.fill")
                    .font(AppFont.body(11))
                    .foregroundStyle(Theme.turquoise)
                    .lineLimit(1)
            } else {
                Text("Keiner Wahl zugeordnet")
                    .font(AppFont.body(11))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Detail

    private var detail: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if let group = vm.selectedGroup {
                groupDetail(group: group)
            } else {
                noSelection
            }
        }
    }

    private func groupDetail(group: VoterGroup) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.name)
                            .font(AppFont.display(30, weight: .bold))
                            .foregroundStyle(Theme.white)
                        Text("\(vm.codes.count) Codes · \(vm.codes.filter(\.used).count) verwendet")
                            .font(AppFont.body(14))
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        deleteCandidate = group
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }

                // Assignment panel
                assignmentPanel(group: group)

                // Codes panel
                codesPanel(group: group)
            }
            .padding(28)
        }
    }

    private func assignmentPanel(group: VoterGroup) -> some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Wahl zuordnen", accent: Theme.turquoise)

                if let sid = group.sessionId,
                   let session = store.sessions.first(where: { $0.id == sid }) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.turquoise)
                        Text(session.title.isEmpty ? "Ohne Titel" : session.title)
                            .font(AppFont.body(15, weight: .medium))
                            .foregroundStyle(Theme.white)
                        Spacer()
                        Button("Entfernen") {
                            Task { await vm.assignGroup(group, to: nil) }
                        }
                        .buttonStyle(SecondaryButtonStyle(tint: Theme.red))
                    }
                } else {
                    Text("Diese Gruppe ist noch keiner Wahl zugeordnet.")
                        .font(AppFont.body(14))
                        .foregroundStyle(Theme.muted)
                }

                let activeSessions = store.sessions.filter { $0.status != SessionStatus.archived }
                if !activeSessions.isEmpty {
                    Divider().background(Theme.divider)
                    Text("Wahl auswählen:")
                        .font(AppFont.body(13, weight: .medium))
                        .foregroundStyle(Theme.muted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(activeSessions) { session in
                                let isAssigned = group.sessionId == session.id
                                Button {
                                    Task { await vm.assignGroup(group, to: isAssigned ? nil : session) }
                                } label: {
                                    HStack(spacing: 6) {
                                        if isAssigned {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Theme.turquoise)
                                        }
                                        Text(session.title.isEmpty ? "Ohne Titel" : session.title)
                                            .lineLimit(1)
                                    }
                                }
                                .buttonStyle(isAssigned
                                    ? AnyButtonStyle(PrimaryButtonStyle(tint: Theme.turquoise))
                                    : AnyButtonStyle(SecondaryButtonStyle()))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func codesPanel(group: VoterGroup) -> some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(title: "Codes (\(vm.codes.count))")
                    Spacer()
                    Button {
                        vm.copyToClipboard()
                    } label: {
                        Label("Kopieren", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(vm.codes.isEmpty)
                }

                if vm.codes.isEmpty {
                    Text("Keine Codes vorhanden.")
                        .font(AppFont.body(14))
                        .foregroundStyle(Theme.muted)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(vm.codes.enumerated()), id: \.element.id) { index, code in
                            codeRow(index: index + 1, code: code)
                            if index < vm.codes.count - 1 {
                                Divider().background(Theme.divider).padding(.leading, 40)
                            }
                        }
                    }
                }
            }
        }
    }

    private func codeRow(index: Int, code: VoterCode) -> some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(AppFont.mono(12))
                .foregroundStyle(Theme.muted)
                .frame(width: 28, alignment: .trailing)
            Text(code.code)
                .font(AppFont.mono(15, weight: .semibold))
                .foregroundStyle(code.used ? Theme.muted : Theme.white)
                .tracking(2)
            Spacer()
            if code.used {
                Label("Verwendet", systemImage: "checkmark.circle.fill")
                    .font(AppFont.body(11, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .labelStyle(.titleAndIcon)
            } else {
                Circle()
                    .fill(Theme.turquoise)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var noSelection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.muted)
            Text("Keine Gruppe ausgewählt")
                .font(AppFont.display(24, weight: .semibold))
                .foregroundStyle(Theme.white)
            Text("Erstellen Sie links eine neue Gruppe oder wählen Sie eine bestehende aus.")
                .font(AppFont.body(14))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
        }
        .padding(40)
    }
}
