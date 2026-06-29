import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit

enum QRCodeService {
    private static let ciContext = CIContext()

    static func generate(string: String, size: CGFloat = 1024) -> NSImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "H"
        guard let outputImage = filter.outputImage else { return nil }

        let extent = outputImage.extent
        guard extent.width > 0 else { return nil }
        let scale = size / extent.width
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = ciContext.createCGImage(scaled, from: scaled.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
    }
}
