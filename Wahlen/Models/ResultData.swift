import Foundation

struct CandidateResult: Identifiable, Hashable, Sendable {
    let id: Int
    let label: String
    let votes: Int
    let percent: Double

    var voteLabel: String {
        votes == 1 ? "1 Stimme" : "\(votes) Stimmen"
    }
}

struct DelegationEntry: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let count: Int
}

struct ResultData: Sendable, Equatable {
    let session: VoteSession
    let totalVotes: Int
    let validVotes: Int
    let invalidVotes: Int
    let participantLimit: Int?
    let nonVoters: Int?
    let delegationCount: Int
    let delegations: [DelegationEntry]
    let candidates: [CandidateResult]

    static let empty = ResultData(
        session: VoteSession(id: UUID(), token: "", title: "", options: [], status: "open"),
        totalVotes: 0,
        validVotes: 0,
        invalidVotes: 0,
        participantLimit: nil,
        nonVoters: nil,
        delegationCount: 0,
        delegations: [],
        candidates: []
    )

    static func build(session: VoteSession, votes: [Vote]) -> ResultData {
        var counts: [Int: Int] = [:]
        var invalid = 0
        var total = 0
        var delegationCount = 0
        var delegationsByName: [String: Int] = [:]

        for vote in votes {
            let w = max(vote.weight, 1)
            total += w
            if vote.optionIndex < 0 || vote.optionIndex >= session.options.count {
                invalid += w
            } else {
                counts[vote.optionIndex, default: 0] += w
            }
            if !vote.delegationNames.isEmpty {
                delegationCount += vote.delegationNames.count
                for name in vote.delegationNames {
                    delegationsByName[name, default: 0] += 1
                }
            } else if w > 1 {
                delegationCount += (w - 1)
            }
        }

        let valid = total - invalid
        let candidates: [CandidateResult] = session.options.enumerated().map { idx, label in
            let v = counts[idx] ?? 0
            let pct = valid > 0 ? Double(v) / Double(valid) * 100.0 : 0.0
            return CandidateResult(id: idx, label: label, votes: v, percent: pct)
        }

        let nonVoters: Int? = {
            guard let limit = session.participantLimit else { return nil }
            let uniqueVoters = Set(votes.compactMap { $0.voterToken }).count
            let effective = max(uniqueVoters, total - delegationCount)
            return max(limit - effective, 0)
        }()

        let delegations = delegationsByName
            .map { DelegationEntry(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        return ResultData(
            session: session,
            totalVotes: total,
            validVotes: valid,
            invalidVotes: invalid,
            participantLimit: session.participantLimit,
            nonVoters: nonVoters,
            delegationCount: delegationCount,
            delegations: delegations,
            candidates: candidates.sorted { $0.votes > $1.votes }
        )
    }
}
