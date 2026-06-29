import SwiftUI

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0x163C7D), location: 0.00),
                .init(color: Color(hex: 0x276BB0), location: 0.25),
                .init(color: Color(hex: 0x5A95CC), location: 0.50),
                .init(color: Color(hex: 0x9BB4CD), location: 0.75),
                .init(color: Color(hex: 0xE3DDD5), location: 0.90),
                .init(color: Color(hex: 0xFDEFA9), location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct AppBackgroundSubtle: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0x163C7D), location: 0.00),
                .init(color: Color(hex: 0x1E4F95), location: 0.55),
                .init(color: Color(hex: 0x276BB0), location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
