import SwiftUI

struct RootView: View {
    @State private var auth = AuthService.shared
    @State private var didBootstrap = false

    var body: some View {
        Group {
            if !didBootstrap {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .tint(Theme.turquoise)
                }
            } else if auth.isAuthenticated {
                AdminDashboardView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: didBootstrap)
        .task {
            if !didBootstrap {
                await auth.bootstrap()
                didBootstrap = true
            }
        }
    }
}
