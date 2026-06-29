import Foundation

struct Profile: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let role: String
    let createdAt: Date?
    let displayName: String?
    let ressort: String?

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case createdAt = "created_at"
        case displayName = "display_name"
        case ressort
    }
}
