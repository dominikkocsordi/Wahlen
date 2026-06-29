import SwiftUI

struct AgendaManagementView: View {
    @State private var agenda = AgendaService.shared
    @State private var newTitle: String = ""
    @State private var deleteCandidate: AgendaItem?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                addBar
                Divider().background(Theme.divider)
                if agenda.items.isEmpty {
                    emptyState
                } else {
                    list
                }
                Divider().background(Theme.divider)
                footer
            }
        }
        .frame(minWidth: 560, minHeight: 520)
        .preferredColorScheme(.dark)
        .alert(
            "Tagesordnungspunkt löschen?",
            isPresented: Binding(
                get: { deleteCandidate != nil },
                set: { if !$0 { deleteCandidate = nil } }
            ),
            presenting: deleteCandidate
        ) { item in
            Button("Löschen", role: .destructive) {
                agenda.remove(id: item.id)
                deleteCandidate = nil
            }
            Button("Abbrechen", role: .cancel) { deleteCandidate = nil }
        } message: { item in
            Text("„\(item.title)“ wird unwiderruflich entfernt.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tagesordnung")
                .font(AppFont.display(22, weight: .bold))
                .foregroundStyle(Theme.white)
            Text("Reihenfolge per Drag & Drop · Doppelklick zum Bearbeiten")
                .font(AppFont.body(13, weight: .medium))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.panel)
    }

    private var addBar: some View {
        HStack(spacing: 10) {
            TextField("Neuen Tagesordnungspunkt …", text: $newTitle)
                .textFieldStyle(.plain)
                .font(AppFont.body(15))
                .padding(12)
                .background(Theme.panelElevated)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.divider, lineWidth: 1))
                .foregroundStyle(Theme.white)
                .onSubmit { addNew() }

            Button {
                addNew()
            } label: {
                Label("Hinzufügen", systemImage: "plus.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.turquoise))
            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(20)
    }

    private var list: some View {
        List {
            ForEach(agenda.items) { item in
                AgendaRow(
                    item: item,
                    isCurrent: agenda.currentItemId == item.id,
                    onSetCurrent: { agenda.setCurrent(item.id) },
                    onClearCurrent: { agenda.setCurrent(nil) },
                    onCommitEdit: { newTitle in agenda.update(id: item.id, title: newTitle) },
                    onDelete: { deleteCandidate = item }
                )
                .listRowBackground(Theme.background)
                .listRowSeparator(.hidden)
            }
            .onMove { source, destination in
                agenda.move(from: source, to: destination)
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
        .background(Theme.background)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.muted)
            Text("Noch keine Tagesordnungspunkte")
                .font(AppFont.body(16, weight: .semibold))
                .foregroundStyle(Theme.white)
            Text("Trage oben deinen ersten TOP ein.")
                .font(AppFont.body(13))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var footer: some View {
        HStack {
            if agenda.currentItem != nil {
                Button {
                    agenda.setCurrent(nil)
                } label: {
                    Label("Aktuellen TOP zurücksetzen", systemImage: "xmark.circle")
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Spacer()

            Button("Fertig") {
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.turquoise))
            .keyboardShortcut(.return, modifiers: [.command])
        }
        .padding(20)
        .background(Theme.panel)
    }

    private func addNew() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        agenda.add(title: title)
        newTitle = ""
    }
}

private struct AgendaRow: View {
    let item: AgendaItem
    let isCurrent: Bool
    let onSetCurrent: () -> Void
    let onClearCurrent: () -> Void
    let onCommitEdit: (String) -> Void
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var draft: String = ""
    @FocusState private var editFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.muted)
                .frame(width: 16)

            Text("\(item.order)")
                .font(AppFont.mono(14, weight: .bold))
                .foregroundStyle(isCurrent ? Theme.turquoise : Theme.muted)
                .frame(width: 24, alignment: .leading)

            if isEditing {
                TextField("Titel", text: $draft)
                    .textFieldStyle(.plain)
                    .font(AppFont.body(15, weight: .medium))
                    .padding(8)
                    .background(Theme.panelElevated)
                    .cornerRadius(6)
                    .foregroundStyle(Theme.white)
                    .focused($editFocused)
                    .onSubmit { commitEdit() }
            } else {
                Text(item.title)
                    .font(AppFont.body(15, weight: isCurrent ? .semibold : .medium))
                    .foregroundStyle(isCurrent ? Theme.white : Theme.white.opacity(0.85))
                    .lineLimit(2)
                    .onTapGesture(count: 2) { startEdit() }
            }

            Spacer(minLength: 8)

            if isCurrent {
                Label("Aktuell", systemImage: "play.fill")
                    .font(AppFont.body(11, weight: .semibold))
                    .tracking(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.turquoise.opacity(0.25)))
                    .foregroundStyle(Theme.turquoise)
            }

            Menu {
                if isEditing {
                    Button("Speichern") { commitEdit() }
                    Button("Abbrechen") { cancelEdit() }
                } else {
                    if isCurrent {
                        Button("Als aktuellen TOP abwählen") { onClearCurrent() }
                    } else {
                        Button("Als aktuellen TOP setzen") { onSetCurrent() }
                    }
                    Button("Bearbeiten") { startEdit() }
                    Divider()
                    Button("Löschen", role: .destructive) { onDelete() }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.muted)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 32)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCurrent ? Theme.panelElevated.opacity(0.7) : Theme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isCurrent ? Theme.turquoise.opacity(0.5) : Theme.divider, lineWidth: 1)
        )
        .padding(.vertical, 2)
    }

    private func startEdit() {
        draft = item.title
        isEditing = true
        DispatchQueue.main.async { editFocused = true }
    }

    private func commitEdit() {
        let cleaned = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleaned.isEmpty && cleaned != item.title {
            onCommitEdit(cleaned)
        }
        isEditing = false
    }

    private func cancelEdit() {
        isEditing = false
    }
}
