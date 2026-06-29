import Foundation

struct Vote: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let sessionId: UUID
    let optionIndex: Int
    let voterToken: String?
    let createdAt: Date?
    let weight: Int
    let delegationNames: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case optionIndex = "option_index"
        case voterToken = "voter_token"
        case createdAt = "created_at"
        case weight
        case delegationNames = "delegation_names"
    }

    init(id: UUID,
         sessionId: UUID,
         optionIndex: Int,
         voterToken: String?,
         createdAt: Date?,
         weight: Int,
         delegationNames: [String]) {
        self.id = id
        self.sessionId = sessionId
        self.optionIndex = optionIndex
        self.voterToken = voterToken
        self.createdAt = createdAt
        self.weight = weight
        self.delegationNames = delegationNames
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.sessionId = try c.decode(UUID.self, forKey: .sessionId)
        self.optionIndex = try c.decode(Int.self, forKey: .optionIndex)
        self.voterToken = try c.decodeIfPresent(String.self, forKey: .voterToken)
        self.createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        self.weight = try c.decodeIfPresent(Int.self, forKey: .weight) ?? 1
        if let names = try? c.decodeIfPresent([String].self, forKey: .delegationNames) {
            self.delegationNames = names
        } else {
            self.delegationNames = []
        }
    }

    var isInvalid: Bool { optionIndex < 0 }
}
