import SwiftUI
import AppKit

/// Produces multi-representation images in the sizes Finder uses for icons.
@MainActor
enum IconRenderer {
    static let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]

    /// Rasterises a design at every icon size so small sizes are drawn
    /// natively rather than downsampled.
    static func render(_ spec: GeneratedIconSpec) -> NSImage {
        let icon = NSImage(size: NSSize(width: 1024, height: 1024))
        for side in sizes {
            let renderer = ImageRenderer(content: IconArtworkView(spec: spec, side: side))
            renderer.scale = 1
            guard let cgImage = renderer.cgImage else { continue }
            let rep = NSBitmapImageRep(cgImage: cgImage)
            rep.size = NSSize(width: side, height: side)
            icon.addRepresentation(rep)
        }
        return icon
    }

    /// Re-rasterises any image (bitmap, PDF, SVG, ICNS, an app's icon…) onto
    /// square transparent canvases, aspect-fitted and centred.
    static func icon(from source: NSImage) -> NSImage {
        let icon = NSImage(size: NSSize(width: 1024, height: 1024))
        let sourceSize = pixelSize(of: source)
        guard sourceSize.width > 0, sourceSize.height > 0 else { return icon }

        for side in sizes {
            guard let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(side), pixelsHigh: Int(side),
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
            ), let context = NSGraphicsContext(bitmapImageRep: rep) else { continue }
            rep.size = NSSize(width: side, height: side)

            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            context.imageInterpolation = .high
            let scale = min(side / sourceSize.width, side / sourceSize.height)
            let drawSize = NSSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
            let origin = NSPoint(x: (side - drawSize.width) / 2, y: (side - drawSize.height) / 2)
            source.draw(in: NSRect(origin: origin, size: drawSize), from: .zero,
                        operation: .sourceOver, fraction: 1, respectFlipped: true,
                        hints: [.interpolation: NSImageInterpolation.high])
            NSGraphicsContext.restoreGraphicsState()

            icon.addRepresentation(rep)
        }
        return icon
    }

    /// The largest representation's pixel dimensions, falling back to the
    /// point size for vector images.
    static func pixelSize(of image: NSImage) -> NSSize {
        var best = NSSize.zero
        for rep in image.representations {
            let size = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
            if size.width * size.height > best.width * best.height { best = size }
        }
        return best.width > 0 ? best : image.size
    }
}
