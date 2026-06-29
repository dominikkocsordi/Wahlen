import SwiftUI
import PDFKit

struct SlidesBeamerView: View {
    @State private var slides = SlideService.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let document = slides.document, slides.totalSlides > 0 {
                PDFSlideRenderer(document: document, pageIndex: slides.currentIndex)
                    .id(slides.currentIndex)
                    .transition(slideTransition(for: slides.lastDirection))
                    .ignoresSafeArea()
            } else {
                missingPlaceholder
            }
        }
        // Kombinierte Animation: weicher Spring für den Hauptkörper,
        // sanftes Opacity-Crossfading parallel
        .animation(
            .spring(response: 0.65, dampingFraction: 0.92, blendDuration: 0.2),
            value: slides.currentIndex
        )
    }

    /// Richtungs-abhängige Push-Transition (Keynote-Stil):
    /// Vorwärts → neue Folie kommt von rechts, alte verschwindet nach links.
    /// Rückwärts → andersrum. Plus dezenter Scale + Opacity-Crossfade.
    private func slideTransition(for direction: SlideNavigationDirection) -> AnyTransition {
        let pushDistance: CGFloat = 80

        switch direction {
        case .forward:
            return .asymmetric(
                insertion: .modifier(
                    active: SlideTransitionEffect(offsetX: pushDistance, opacity: 0, scale: 0.98),
                    identity: SlideTransitionEffect(offsetX: 0, opacity: 1, scale: 1)
                ),
                removal: .modifier(
                    active: SlideTransitionEffect(offsetX: -pushDistance, opacity: 0, scale: 0.985),
                    identity: SlideTransitionEffect(offsetX: 0, opacity: 1, scale: 1)
                )
            )
        case .backward:
            return .asymmetric(
                insertion: .modifier(
                    active: SlideTransitionEffect(offsetX: -pushDistance, opacity: 0, scale: 0.98),
                    identity: SlideTransitionEffect(offsetX: 0, opacity: 1, scale: 1)
                ),
                removal: .modifier(
                    active: SlideTransitionEffect(offsetX: pushDistance, opacity: 0, scale: 0.985),
                    identity: SlideTransitionEffect(offsetX: 0, opacity: 1, scale: 1)
                )
            )
        case .none:
            // Erstes Erscheinen oder Reset: nur sanftes Fade-In
            return .asymmetric(
                insertion: .modifier(
                    active: SlideTransitionEffect(offsetX: 0, opacity: 0, scale: 0.96),
                    identity: SlideTransitionEffect(offsetX: 0, opacity: 1, scale: 1)
                ),
                removal: .opacity
            )
        }
    }

    private var missingPlaceholder: some View {
        VStack(spacing: 18) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.white.opacity(0.55))
            Text("Keine Präsentation geladen")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
            Text("Lege presentation.pdf ins App-Bundle oder öffne eine PDF über das Admin-Dashboard.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
        }
    }
}

// MARK: - Custom Transition Effect

private struct SlideTransitionEffect: ViewModifier {
    let offsetX: CGFloat
    let opacity: Double
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .offset(x: offsetX)
            .opacity(opacity)
    }
}

// MARK: - PDFKit Wrapper (Single-Page Modus)

private struct PDFSlideRenderer: NSViewRepresentable {
    let document: PDFDocument
    let pageIndex: Int

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.displayMode = .singlePage
        view.displaysPageBreaks = false
        view.autoScales = true
        view.backgroundColor = .black
        view.maxScaleFactor = 4.0
        view.minScaleFactor = 0.1
        view.document = document
        if let page = document.page(at: pageIndex) {
            view.go(to: page)
        }
        view.acceptsDraggedFiles = false
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document !== document {
            nsView.document = document
        }
        if let page = document.page(at: pageIndex), nsView.currentPage != page {
            nsView.go(to: page)
        }
        nsView.autoScales = true
    }
}
