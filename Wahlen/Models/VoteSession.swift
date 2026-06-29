import Foundation

struct VoteSession: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var token: String
    var title: String
    var options: [String]
    var status: String
    var createdAt: Date?
    var participantLimit: Int?
    var resultsVisible: Bool
    var allowDelegation: Bool
    var isValid: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case token
        case title
        case options
        case status
        case createdAt = "created_at"
        case participantLimit = "participant_limit"
        case resultsVisible = "results_visible"
        case allowDelegation = "allow_delegation"
        case isValid = "is_valid"
    }

    init(id: UUID,
         token: String,
         title: String,
         options: [String],
         status: String,
         createdAt: Date? = nil,
         participantLimit: Int? = nil,
         resultsVisible: Bool = false,
         allowDelegation: Bool = false,
         isValid: Bool? = nil) {
        self.id = id
        self.token = token
        self.title = title
        self.options = options
        self.status = status
        self.createdAt = createdAt
        self.participantLimit = participantLimit
        self.resultsVisible = resultsVisible
        self.allowDelegation = allowDelegation
        self.isValid = isValid
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.token = try container.decode(String.self, forKey: .token)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.options = Self.decodeOptions(container: container)
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "open"
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.participantLimit = try container.decodeIfPresent(Int.self, forKey: .participantLimit)
        self.resultsVisible = try container.decodeIfPresent(Bool.self, forKey: .resultsVisible) ?? false
        self.allowDelegation = try container.decodeIfPresent(Bool.self, forKey: .allowDelegation) ?? false
        self.isValid = try container.decodeIfPresent(Bool.self, forKey: .isValid)
    }

    private static func decodeOptions(container: KeyedDecodingContainer<CodingKeys>) -> [String] {
        if let strings = try? container.decodeIfPresent([String].self, forKey: .options) {
            return strings
        }
        if let dicts = try? container.decodeIfPresent([[String: AnyCodable]].self, forKey: .options) {
            return dicts.compactMap { dict in
                if let v = dict["label"]?.value as? String { return v }
                if let v = dict["name"]?.value as? String { return v }
                if let v = dict["title"]?.value as? String { return v }
                if let v = dict["text"]?.value as? String { return v }
                return nil
            }
        }
        return []
    }
}

enum SessionStatus {
    static let open = "open"
    static let closed = "closed"
    static let archived = "archived"
}

struct AnyCodable: Codable, Hashable, Sendable {
    let value: AnyHashable

    init(_ value: AnyHashable) { self.value = value }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self) { self.value = v; return }
        if let v = try? c.decode(Int.self) { self.value = v; return }
        if let v = try? c.decode(Double.self) { self.value = v; return }
        if let v = try? c.decode(String.self) { self.value = v; return }
        if c.decodeNil() { self.value = "" as AnyHashable; return }
        if let v = try? c.decode([AnyCodable].self) { self.value = v; return }
        if let v = try? c.decode([String: AnyCodable].self) { self.value = v; return }
        self.value = "" as AnyHashable
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try c.encode(v)
        case let v as Int: try c.encode(v)
        case let v as Double: try c.encode(v)
        case let v as String: try c.encode(v)
        case let v as [AnyCodable]: try c.encode(v)
        case let v as [String: AnyCodable]: try c.encode(v)
        default: try c.encodeNil()
        }
    }
}
