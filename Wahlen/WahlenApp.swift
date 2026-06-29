import SwiftUI
import AppKit

@main
struct WahlenApp: App {
    @Environment(\.openWindow) private var openWindow

    init() {
        _ = SupabaseService.shared
    }

    var body: some Scene {
        Window("FSBS Wahlen · Admin", id: "admin") {
            AdminDashboardView()
                .frame(minWidth: 1280, minHeight: 800)
                .background(Theme.background)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1440, height: 900)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Beamer-Fenster öffnen") {
                    openWindow(id: "beamer")
                }
                .keyboardShortcut("B", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .help) { EmptyView() }
        }

        Window("FSBS Wahlen · Beamer", id: "beamer") {
            BeamerWindow()
                .frame(minWidth: 1280, minHeight: 720)
                .background(Theme.background)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1920, height: 1080)
    }
}
