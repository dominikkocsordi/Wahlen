import Foundation
import Observation
import PDFKit
import AppKit

@MainActor
@Observable
final class SlideService {
    static let shared = SlideService()

    private(set) var document: PDFDocument?
    private(set) var documentName: String?
    var currentIndex: Int = 0

    var totalSlides: Int { document?.pageCount ?? 0 }
    var currentSlideNumber: Int { currentIndex + 1 }
    var hasDocument: Bool { document != nil }

    var canGoNext: Bool { currentIndex + 1 < totalSlides }
    var canGoPrevious: Bool { currentIndex > 0 }

    /// Mögliche Dateinamen, unter denen eine PDF im App-Bundle gesucht wird.
    private let bundleCandidates = [
        "presentation",
        "Präsentation",
        "praesentation",
        "Folien",
        "slides",
        "MV_WS2627_V1"
    ]

    private init() {
        loadBundledDocument()
    }

    @discardableResult
    func loadBundledDocument() -> Bool {
        for name in bundleCandidates {
            if let url = Bundle.main.url(forResource: name, withExtension: "pdf"),
               let doc = PDFDocument(url: url) {
                self.document = doc
                self.documentName = url.lastPathComponent
                self.currentIndex = 0
                return true
            }
        }
        return false
    }

    @discardableResult
    func loadDocument(from url: URL) -> Bool {
        // Falls die Datei in einem geschützten Bereich liegt (iCloud, Sandbox),
        // Security-Scoped Resource starten.
        let didStart = url.startAccessingSecurityScopedResource()
        defer { if didStart { url.stopAccessingSecurityScopedResource() } }

        guard let doc = PDFDocument(url: url) else { return false }
        self.document = doc
        self.documentName = url.lastPathComponent
        self.currentIndex = 0
        return true
    }

    /// Öffnet einen Datei-Dialog und lädt die ausgewählte PDF.
    @discardableResult
    func presentOpenPanel() -> Bool {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Präsentation öffnen"
        panel.prompt = "Öffnen"

        guard panel.runModal() == .OK, let url = panel.url else { return false }
        return loadDocument(from: url)
    }

    func next() {
        guard canGoNext else { return }
        currentIndex += 1
    }

    func previous() {
        guard canGoPrevious else { return }
        currentIndex -= 1
    }

    func goTo(_ index: Int) {
        guard index >= 0 && index < totalSlides else { return }
        currentIndex = index
    }

    func reset() {
        currentIndex = 0
    }

    func currentPage() -> PDFPage? {
        document?.page(at: currentIndex)
    }

    func thumbnail(for index: Int, size: CGSize) -> NSImage? {
        guard let page = document?.page(at: index) else { return nil }
        return page.thumbnail(of: size, for: .mediaBox)
    }
}
