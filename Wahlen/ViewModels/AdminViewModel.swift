import Foundation
import Observation

@MainActor
@Observable
final class AdminViewModel {
    var selectedSessionId: UUID?
    var isPresentingCreate = false
    var errorMessage: String?
    var transitionTask: Task<Void, Never>?

    var store: ElectionStore { .shared }

    var selectedSession: VoteSession? {
        guard let id = selectedSessionId else { return nil }
        return store.session(id: id)
    }

    func selectFirstIfNeeded() {
        if selectedSessionId == nil, let first = store.sessions.first {
            selectedSessionId = first.id
        }
    }

    func ensureSelectionValid() {
        if let id = selectedSessionId, store.session(id: id) == nil {
            selectedSessionId = store.sessions.first?.id
        }
    }

    func currentPhase(for session: VoteSession) -> AdminElectionPhase {
        switch store.presentationState {
        case .ballotPreview(let id) where id == session.id: return .ballot
        case .open(let id) where id == session.id: return .open
        case .decrypting(let id) where id == session.id: return .counting
        case .verifying(let id) where id == session.id: return .verification
        case .results(let id) where id == session.id: return .result
        default:
            if session.status == SessionStatus.archived { return .preparation }
            if session.resultsVisible { return .result }
            if session.status == SessionStatus.open { return .open }
            return .preparation
        }
    }

    func showBallotPreview(session: VoteSession) {
        store.presentationState = .ballotPreview(sessionId: session.id)
    }

    func openVoting(session: VoteSession) async {
        do {
            try await ElectionService.shared.updateStatus(sessionId: session.id, status: SessionStatus.open)
            try await ElectionService.shared.setResultsVisible(sessionId: session.id, visible: false)
            try await ElectionService.shared.clearValidity(sessionId: session.id)
            await store.loadSessions()
            await store.attachVotesRealtime(for: session.id)
            store.presentationState = .open(sessionId: session.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func closeVoting(session: VoteSession) async {
        do {
            try await ElectionService.shared.updateStatus(sessionId: session.id, status: SessionStatus.closed)
            await store.loadSessions()
            await runDecryptVerifyAnimation(sessionId: session.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func showResults(session: VoteSession) async {
        do {
            try await ElectionService.shared.setResultsVisible(sessionId: session.id, visible: true)
            await store.reloadVotes(for: session.id)
            await store.loadSessions()
            store.presentationState = .results(sessionId: session.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setValidity(session: VoteSession, valid: Bool) async {
        do {
            try await ElectionService.shared.setValidity(sessionId: session.id, valid: valid)
            await store.loadSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archive(session: VoteSession) async {
        do {
            try await ElectionService.shared.archiveSession(sessionId: session.id)
            await store.loadSessions()
            ensureSelectionValid()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(session: VoteSession) async {
        do {
            try await ElectionService.shared.deleteSession(sessionId: session.id)
            store.removeLocal(sessionId: session.id)
            ensureSelectionValid()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func duplicate(session: VoteSession) async {
        do {
            let new = try await ElectionService.shared.duplicateSession(session)
            store.updateLocal(session: new)
            selectedSessionId = new.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func returnToIdle() {
        transitionTask?.cancel()
        store.presentationState = .idle
        Task { await store.detachVotesRealtime() }
    }

    private func runDecryptVerifyAnimation(sessionId: UUID) async {
        transitionTask?.cancel()
        store.presentationState = .decrypting(sessionId: sessionId)
        transitionTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self.store.presentationState = .verifying(sessionId: sessionId)
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self.store.presentationState = .results(sessionId: sessionId)
        }
        await transitionTask?.value
    }
}
