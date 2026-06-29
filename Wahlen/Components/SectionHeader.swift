import SwiftUI

struct SectionHeader: View {
    let title: String
    var accent: Color = Theme.lightBlue

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(accent)
                .frame(width: 4, height: 22)
                .clipShape(Capsule())
            Text(title.uppercased())
                .font(AppFont.body(13, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(Theme.white)
            Spacer()
        }
    }
}

struct PanelCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 22

    init(padding: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.divider, lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.lightBlue
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body(14, weight: .semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(minWidth: 140)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.75 : 1.0))
            )
            .foregroundStyle(Theme.background)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.white
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body(14, weight: .semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(minWidth: 140)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.panelElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(tint.opacity(0.35), lineWidth: 1)
            )
            .foregroundStyle(tint)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body(14, weight: .semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(minWidth: 120)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.red.opacity(configuration.isPressed ? 0.75 : 1.0))
            )
            .foregroundStyle(Theme.background)
    }
}
