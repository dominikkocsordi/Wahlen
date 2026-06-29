import Foundation
import Observation

@MainActor
@Observable
final class ElectionStore {
    static let shared = ElectionStore()

    var sessions: [VoteSession] = []
    var votesBySession: [UUID: [Vote]] = [:]
    var presentationState: PresentationState = .idle
    var loadError: String?
    var isLoading: Bool = false

    private var didInitialize = false

    private init() {}

    func bootstrap() async {
        guard !didInitialize else { return }
        didInitialize = true
        await loadSessions()
        await RealtimeService.shared.subscribeSessions { [weak self] in
            Task { @MainActor in await self?.loadSessions() }
        }
    }

    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await ElectionService.shared.fetchSessions()
            self.sessions = fetched
            self.loadError = nil
            for session in fetched {
                await reloadVotes(for: session.id)
            }
        } catch {
            self.loadError = error.localizedDescription
        }
    }

    func reloadVotes(for sessionId: UUID) async {
        do {
            let votes = try await ElectionService.shared.fetchVotes(sessionId: sessionId)
            self.votesBySession[sessionId] = votes
        } catch {
            self.loadError = error.localizedDescription
        }
    }

    func session(id: UUID) -> VoteSession? {
        sessions.first(where: { $0.id == id })
    }

    func votes(for sessionId: UUID) -> [Vote] {
        votesBySession[sessionId] ?? []
    }

    func result(for sessionId: UUID) -> ResultData? {
        guard let session = session(id: sessionId) else { return nil }
        return ResultData.build(session: session, votes: votes(for: sessionId))
    }

    func updateLocal(session: VoteSession) {
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        } else {
            sessions.insert(session, at: 0)
        }
    }

    func removeLocal(sessionId: UUID) {
        sessions.removeAll { $0.id == sessionId }
        votesBySession.removeValue(forKey: sessionId)
        if presentationState.sessionId == sessionId {
            presentationState = .idle
        }
    }

    func attachVotesRealtime(for sessionId: UUID) async {
        await RealtimeService.shared.subscribeVotes(sessionId: sessionId) { [weak self] in
            Task { @MainActor in await self?.reloadVotes(for: sessionId) }
        }
    }

    func detachVotesRealtime() async {
        await RealtimeService.shared.unsubscribeVotes()
    }
}
