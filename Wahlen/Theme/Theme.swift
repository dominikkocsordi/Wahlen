import SwiftUI

enum Theme {
    static let background = Color(hex: 0x102B5C)
    static let panel = Color(hex: 0x173A73)
    static let panelElevated = Color(hex: 0x1F4A8A)
    static let lightBlue = Color(hex: 0x4DB5FF)
    static let turquoise = Color(hex: 0x4ED6C5)
    static let yellow = Color(hex: 0xE6DD59)
    static let red = Color(hex: 0xFF7A7A)
    static let white = Color(hex: 0xF5F7FA)
    static let muted = Color(hex: 0xF5F7FA).opacity(0.65)
    static let divider = Color(hex: 0xF5F7FA).opacity(0.12)

    static let chartPalette: [Color] = [
        Color(hex: 0x4DB5FF),
        Color(hex: 0x4ED6C5),
        Color(hex: 0xE6DD59),
        Color(hex: 0xFF7A7A),
        Color(hex: 0x9D8DF1),
        Color(hex: 0x6CE5B5),
        Color(hex: 0xFFB05C),
        Color(hex: 0xFF9CC6),
        Color(hex: 0x6FB1FF),
        Color(hex: 0xC4F06D)
    ]

    static func chartColor(for index: Int) -> Color {
        chartPalette[index % chartPalette.count]
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

enum AppFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func title(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
