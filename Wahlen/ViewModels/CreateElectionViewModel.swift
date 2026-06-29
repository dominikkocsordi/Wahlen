import Foundation
import Observation

enum ElectionEditorMode: Equatable {
    case create
    case edit(VoteSession)

    var isEditing: Bool {
        if case .edit = self { return true } else { return false }
    }

    var existingSession: VoteSession? {
        if case .edit(let s) = self { return s } else { return nil }
    }
}

@MainActor
@Observable
final class CreateElectionViewModel {
    var mode: ElectionEditorMode
    var title: String = ""
    var description: String = ""
    var options: [String] = ["", ""]
    var participantLimit: String = ""
    var allowDelegation: Bool = false
    var resultsHidden: Bool = true
    var isSubmitting: Bool = false
    var errorMessage: String?

    init(mode: ElectionEditorMode = .create) {
        self.mode = mode
        if case .edit(let session) = mode {
            self.title = session.title
            self.options = session.options.isEmpty ? ["", ""] : session.options
            self.participantLimit = session.participantLimit.map(String.init) ?? ""
            self.allowDelegation = session.allowDelegation
            self.resultsHidden = !session.resultsVisible
        }
    }

    var canSubmit: Bool {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanOptions = options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return !cleanTitle.isEmpty && cleanOptions.count >= 2
    }

    func addOption() {
        options.append("")
    }

    func removeOption(at index: Int) {
        guard options.indices.contains(index), options.count > 2 else { return }
        options.remove(at: index)
    }

    func reset() {
        title = ""
        description = ""
        options = ["", ""]
        participantLimit = ""
        allowDelegation = false
        resultsHidden = true
        errorMessage = nil
        isSubmitting = false
    }

    func submit() async -> VoteSession? {
        guard canSubmit else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }

        let cleanOptions = options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let limit = Int(participantLimit.trimmingCharacters(in: .whitespacesAndNewlines))

        do {
            let session: VoteSession
            switch mode {
            case .create:
                session = try await ElectionService.shared.createSession(
                    title: cleanTitle,
                    options: cleanOptions,
                    participantLimit: limit,
                    allowDelegation: allowDelegation,
                    resultsVisible: !resultsHidden
                )
            case .edit(let existing):
                session = try await ElectionService.shared.updateSession(
                    id: existing.id,
                    title: cleanTitle,
                    options: cleanOptions,
                    participantLimit: limit,
                    allowDelegation: allowDelegation,
                    resultsVisible: !resultsHidden
                )
            }
            ElectionStore.shared.updateLocal(session: session)
            return session
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
