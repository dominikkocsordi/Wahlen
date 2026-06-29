import Foundation

struct AgendaItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var order: Int

    init(id: UUID = UUID(), title: String, order: Int) {
        self.id = id
        self.title = title
        self.order = order
    }
}
