// Renders the app's own icon using the same artwork view the app uses for
// folder icons. Build and run with:
//   swiftc -swift-version 6 -O -o /tmp/make-app-icon \
//     IconSetter/Models/GeneratedIconSpec.swift IconSetter/Rendering/IconArtworkView.swift \
//     Scripts/make-app-icon.swift && /tmp/make-app-icon IconSetter/Resources/Assets.xcassets/AppIcon.appiconset
import SwiftUI
import AppKit

@main
struct MakeAppIcon {
    @MainActor
    static func main() throws {
        let outputDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

        var spec = GeneratedIconSpec()
        spec.shape = .squircle
        spec.apply(GradientPreset.all[1]) // Indigo
        spec.gradientAngle = 60
        spec.symbolName = "folder.fill.badge.gearshape"
        spec.symbolScale = 0.44
        spec.symbolWeight = .medium

        let files: [(name: String, side: CGFloat)] = [
            ("icon_16x16", 16), ("icon_16x16@2x", 32),
            ("icon_32x32", 32), ("icon_32x32@2x", 64),
            ("icon_128x128", 128), ("icon_128x128@2x", 256),
            ("icon_256x256", 256), ("icon_256x256@2x", 512),
            ("icon_512x512", 512), ("icon_512x512@2x", 1024),
        ]

        for file in files {
            let renderer = ImageRenderer(content: IconArtworkView(spec: spec, side: file.side))
            renderer.scale = 1
            guard let cgImage = renderer.cgImage,
                  let png = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) else {
                fatalError("Couldn't render \(file.name)")
            }
            try png.write(to: URL(fileURLWithPath: outputDirectory).appending(path: "\(file.name).png"))
        }
        print("Wrote \(files.count) icon files to \(outputDirectory)")
    }
}
