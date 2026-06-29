import SwiftUI
import AppKit

struct BeamerWindow: View {
    @State private var store = ElectionStore.shared
    @State private var isHovering: Bool = false
    @State private var isFullScreen: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
                .background(Theme.background.ignoresSafeArea())
                .frame(minWidth: 1280, minHeight: 720)
                .preferredColorScheme(.dark)

            overlayControls
                .padding(20)
                .opacity(isHovering ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .onContinuousHover { phase in
            switch phase {
            case .active: isHovering = true
            case .ended: isHovering = false
            }
        }
        .background(WindowAccessor { window in
            configureWindow(window)
        })
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch store.presentationState {
            case .idle:
                StartView()
            case .intro:
                IntroView()
            case .slides:
                SlidesBeamerView()
            case .ballotPreview(let id):
                if let session = store.session(id: id) {
                    BallotPreviewView(session: session)
                } else {
                    StartView()
                }
            case .open(let id):
                if let session = store.session(id: id) {
                    VotingOpenView(session: session, votes: store.votes(for: id))
                } else {
                    StartView()
                }
            case .decrypting:
                DecryptingView()
            case .counting(let id):
                VotingProcessingView(state: .counting(sessionId: id))
            case .verifying:
                VerifyingView()
            case .results(let id):
                if let result = store.result(for: id) {
                    ResultsView(result: result)
                } else {
                    StartView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.45), value: store.presentationState)
    }

    private var overlayControls: some View {
        HStack(spacing: 10) {
            Button {
                toggleFullScreen()
            } label: {
                Image(systemName: isFullScreen
                      ? "arrow.down.right.and.arrow.up.left"
                      : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.white)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle().fill(Theme.panelElevated.opacity(0.85))
                    )
                    .overlay(
                        Circle().stroke(Theme.divider, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help(isFullScreen ? "Vollbild verlassen (⌃⌘F)" : "Vollbild (⌃⌘F)")
            .keyboardShortcut("f", modifiers: [.control, .command])
        }
    }

    private func configureWindow(_ window: NSWindow) {
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.collectionBehavior.insert(.fullScreenAllowsTiling)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.black

        NotificationCenter.default.removeObserver(WindowObserver.shared,
                                                  name: NSWindow.didEnterFullScreenNotification,
                                                  object: window)
        NotificationCenter.default.removeObserver(WindowObserver.shared,
                                                  name: NSWindow.didExitFullScreenNotification,
                                                  object: window)

        WindowObserver.shared.onEnter = { isFullScreen = true }
        WindowObserver.shared.onExit = { isFullScreen = false }

        NotificationCenter.default.addObserver(forName: NSWindow.didEnterFullScreenNotification,
                                               object: window, queue: .main) { _ in
            WindowObserver.shared.onEnter?()
        }
        NotificationCenter.default.addObserver(forName: NSWindow.didExitFullScreenNotification,
                                               object: window, queue: .main) { _ in
            WindowObserver.shared.onExit?()
        }

        isFullScreen = window.styleMask.contains(.fullScreen)
    }

    private func toggleFullScreen() {
        guard let window = currentBeamerWindow() else { return }
        window.toggleFullScreen(nil)
    }

    private func currentBeamerWindow() -> NSWindow? {
        NSApplication.shared.windows.first { $0.title.contains("Beamer") }
            ?? NSApplication.shared.keyWindow
    }
}

private final class WindowObserver {
    static let shared = WindowObserver()
    var onEnter: (() -> Void)?
    var onExit: (() -> Void)?
}

private struct WindowAccessor: NSViewRepresentable {
    var configure: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                configure(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                configure(window)
            }
        }
    }
}
