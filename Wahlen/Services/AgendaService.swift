import Foundation
import Observation

@MainActor
@Observable
final class AgendaService {
    static let shared = AgendaService()

    private(set) var items: [AgendaItem] = []
    var currentItemId: UUID? {
        didSet { saveCurrent() }
    }

    var currentItem: AgendaItem? {
        guard let id = currentItemId else { return nil }
        return items.first(where: { $0.id == id })
    }

    private static let itemsKey = "fsbs.wahlen.agenda.items"
    private static let currentKey = "fsbs.wahlen.agenda.currentId"

    private init() {
        load()
    }

    // MARK: - CRUD

    func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (items.map(\.order).max() ?? 0) + 1
        items.append(AgendaItem(title: trimmed, order: nextOrder))
        save()
    }

    func update(id: UUID, title: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items[index].title = trimmed
        save()
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        if currentItemId == id { currentItemId = nil }
        reindex()
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        reindex()
        save()
    }

    func setCurrent(_ id: UUID?) {
        currentItemId = id
    }

    func advance() {
        guard let current = currentItemId,
              let index = items.firstIndex(where: { $0.id == current }),
              index + 1 < items.count else { return }
        currentItemId = items[index + 1].id
    }

    func goBack() {
        guard let current = currentItemId,
              let index = items.firstIndex(where: { $0.id == current }),
              index > 0 else { return }
        currentItemId = items[index - 1].id
    }

    private func reindex() {
        for i in items.indices {
            items[i].order = i + 1
        }
    }

    // MARK: - Persistence (UserDefaults)

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Self.itemsKey),
           let decoded = try? JSONDecoder().decode([AgendaItem].self, from: data) {
            self.items = decoded.sorted { $0.order < $1.order }
        }
        if let idString = UserDefaults.standard.string(forKey: Self.currentKey),
           let id = UUID(uuidString: idString),
           items.contains(where: { $0.id == id }) {
            self.currentItemId = id
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: Self.itemsKey)
        }
    }

    private func saveCurrent() {
        if let id = currentItemId {
            UserDefaults.standard.set(id.uuidString, forKey: Self.currentKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.currentKey)
        }
    }
}
