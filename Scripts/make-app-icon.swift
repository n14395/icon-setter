// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

// Rasterises the app's own icon from Design/AppIcon.svg at every size the
// asset catalog needs. AppKit renders the SVG natively (gradients, clips and
// drop-shadow filters included), so this needs nothing beyond the toolchain.
// Build and run with:
//   swiftc -swift-version 6 -O -parse-as-library -o /tmp/make-app-icon Scripts/make-app-icon.swift
//   /tmp/make-app-icon Design/AppIcon.svg IconSetter/Resources/Assets.xcassets/AppIcon.appiconset
import AppKit

@main
struct MakeAppIcon {
    @MainActor
    static func main() throws {
        let arguments = CommandLine.arguments
        let svgPath = arguments.count > 1 ? arguments[1] : "Design/AppIcon.svg"
        let outputDirectory = arguments.count > 2 ? arguments[2] : "."

        guard let artwork = NSImage(contentsOf: URL(fileURLWithPath: svgPath)) else {
            fatalError("Couldn't load \(svgPath)")
        }

        let files: [(name: String, side: Int)] = [
            ("icon_16x16", 16), ("icon_16x16@2x", 32),
            ("icon_32x32", 32), ("icon_32x32@2x", 64),
            ("icon_128x128", 128), ("icon_128x128@2x", 256),
            ("icon_256x256", 256), ("icon_256x256@2x", 512),
            ("icon_512x512", 512), ("icon_512x512@2x", 1024),
        ]

        for file in files {
            guard let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: file.side, pixelsHigh: file.side,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
                fatalError("Couldn't make a bitmap for \(file.name)")
            }
            rep.size = NSSize(width: file.side, height: file.side)

            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
            NSGraphicsContext.current?.imageInterpolation = .high
            artwork.draw(in: NSRect(x: 0, y: 0, width: file.side, height: file.side),
                         from: .zero, operation: .sourceOver, fraction: 1)
            NSGraphicsContext.restoreGraphicsState()

            guard let png = rep.representation(using: .png, properties: [:]) else {
                fatalError("Couldn't encode \(file.name)")
            }
            try png.write(to: URL(fileURLWithPath: outputDirectory).appending(path: "\(file.name).png"))
        }
        print("Wrote \(files.count) icon files to \(outputDirectory)")
    }
}
