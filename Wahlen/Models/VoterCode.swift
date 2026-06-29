import Foundation

struct VoterCode: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var groupId: UUID
    var code: String
    var used: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case code
        case used
    }
}
