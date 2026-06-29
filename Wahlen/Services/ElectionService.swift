import Foundation
import Supabase

@MainActor
final class ElectionService {
    static let shared = ElectionService()

    private var client: SupabaseClient { SupabaseService.shared.client }

    private init() {}

    func fetchSessions() async throws -> [VoteSession] {
        try await client
            .from("vote_sessions")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchSession(id: UUID) async throws -> VoteSession? {
        let rows: [VoteSession] = try await client
            .from("vote_sessions")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func fetchVotes(sessionId: UUID) async throws -> [Vote] {
        try await client
            .from("votes")
            .select()
            .eq("session_id", value: sessionId.uuidString)
            .execute()
            .value
    }

    struct NewSessionPayload: Encodable {
        let title: String
        let options: [String]
        let status: String
        let participant_limit: Int?
        let results_visible: Bool
        let allow_delegation: Bool
    }

    @discardableResult
    func createSession(title: String,
                       options: [String],
                       participantLimit: Int?,
                       allowDelegation: Bool,
                       resultsVisible: Bool) async throws -> VoteSession {
        let payload = NewSessionPayload(
            title: title,
            options: options,
            status: SessionStatus.closed,
            participant_limit: participantLimit,
            results_visible: resultsVisible,
            allow_delegation: allowDelegation
        )
        let inserted: [VoteSession] = try await client
            .from("vote_sessions")
            .insert(payload, returning: .representation)
            .select()
            .execute()
            .value
        guard let session = inserted.first else {
            throw ElectionError.creationFailed
        }
        return session
    }

    struct StatusPayload: Encodable { let status: String }
    struct ResultsVisiblePayload: Encodable { let results_visible: Bool }
    struct ValidityPayload: Encodable { let is_valid: Bool }
    struct ValidityClearPayload: Encodable { let is_valid: String? }

    func updateStatus(sessionId: UUID, status: String) async throws {
        _ = try await client
            .from("vote_sessions")
            .update(StatusPayload(status: status))
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    func setResultsVisible(sessionId: UUID, visible: Bool) async throws {
        _ = try await client
            .from("vote_sessions")
            .update(ResultsVisiblePayload(results_visible: visible))
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    func setValidity(sessionId: UUID, valid: Bool) async throws {
        _ = try await client
            .from("vote_sessions")
            .update(ValidityPayload(is_valid: valid))
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    func clearValidity(sessionId: UUID) async throws {
        _ = try await client
            .from("vote_sessions")
            .update(ValidityClearPayload(is_valid: nil))
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    func deleteSession(sessionId: UUID) async throws {
        _ = try await client
            .from("votes")
            .delete()
            .eq("session_id", value: sessionId.uuidString)
            .execute()
        _ = try await client
            .from("vote_sessions")
            .delete()
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    func archiveSession(sessionId: UUID) async throws {
        try await updateStatus(sessionId: sessionId, status: SessionStatus.archived)
    }

    func duplicateSession(_ session: VoteSession) async throws -> VoteSession {
        try await createSession(
            title: session.title + " (Kopie)",
            options: session.options,
            participantLimit: session.participantLimit,
            allowDelegation: session.allowDelegation,
            resultsVisible: false
        )
    }
}

enum ElectionError: LocalizedError {
    case creationFailed
    case notFound

    var errorDescription: String? {
        switch self {
        case .creationFailed: return "Wahl konnte nicht angelegt werden."
        case .notFound: return "Wahl nicht gefunden."
        }
    }
}
