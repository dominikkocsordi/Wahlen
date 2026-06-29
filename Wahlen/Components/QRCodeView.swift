import SwiftUI
import AppKit

struct QRCodeView: View {
    let content: String
    var size: CGFloat = 360

    var body: some View {
        Group {
            if let image = QRCodeService.generate(string: content, size: size * 2) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle().fill(Theme.muted)
            }
        }
        .frame(width: size, height: size)
        .padding(size * 0.04)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: .black.opacity(0.4), radius: 22, x: 0, y: 14)
    }
}
