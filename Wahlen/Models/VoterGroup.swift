import Foundation

struct VoterGroup: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var sessionId: UUID?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sessionId = "session_id"
        case createdAt = "created_at"
    }
}
