import Foundation
import Supabase
import Realtime

@MainActor
final class RealtimeService {
    static let shared = RealtimeService()

    private var client: SupabaseClient { SupabaseService.shared.client }

    private var sessionChannel: RealtimeChannelV2?
    private var voteChannel: RealtimeChannelV2?
    private var sessionTask: Task<Void, Never>?
    private var voteTask: Task<Void, Never>?

    private init() {}

    func subscribeSessions(_ handler: @escaping @MainActor () -> Void) async {
        await unsubscribeSessions()
        let channel = client.realtimeV2.channel("public:vote_sessions")
        let changes = channel.postgresChange(AnyAction.self, schema: "public", table: "vote_sessions")
        do {
            try await channel.subscribeWithError()
        } catch {
            return
        }
        sessionChannel = channel
        sessionTask = Task { @MainActor in
            for await _ in changes {
                handler()
            }
        }
    }

    func unsubscribeSessions() async {
        sessionTask?.cancel()
        sessionTask = nil
        if let channel = sessionChannel {
            await channel.unsubscribe()
            sessionChannel = nil
        }
    }

    func subscribeVotes(sessionId: UUID, handler: @escaping @MainActor () -> Void) async {
        await unsubscribeVotes()
        let channel = client.realtimeV2.channel("public:votes:\(sessionId.uuidString)")
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "votes",
            filter: .eq("session_id", value: sessionId.uuidString)
        )
        do {
            try await channel.subscribeWithError()
        } catch {
            return
        }
        voteChannel = channel
        voteTask = Task { @MainActor in
            for await _ in changes {
                handler()
            }
        }
    }

    func unsubscribeVotes() async {
        voteTask?.cancel()
        voteTask = nil
        if let channel = voteChannel {
            await channel.unsubscribe()
            voteChannel = nil
        }
    }

    func unsubscribeAll() async {
        await unsubscribeSessions()
        await unsubscribeVotes()
    }
}
