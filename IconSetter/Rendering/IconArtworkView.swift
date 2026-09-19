import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Draws a `GeneratedIconSpec` at any size. Every measurement is relative to
/// `side`, so the same view is used for the on-screen preview and for the
/// bitmap reps that end up on disk.
struct IconArtworkView: View {
    let spec: GeneratedIconSpec
    let side: CGFloat

    @MainActor private static let folderImage: NSImage = NSWorkspace.shared.icon(for: UTType.folder)

    var body: some View {
        ZStack {
            switch spec.shape {
            case .folder: folderLayer
            case .squircle: squircleLayer
            }
            if spec.showSymbol { symbolLayer }
        }
        .frame(width: side, height: side)
    }

    // MARK: Background

    private var fill: AnyShapeStyle {
        switch spec.fillStyle {
        case .solid:
            return AnyShapeStyle(spec.primaryColor)
        case .linear:
            let radians = spec.gradientAngle * .pi / 180
            let dx = cos(radians) / 2, dy = sin(radians) / 2
            return AnyShapeStyle(LinearGradient(
                colors: [spec.primaryColor, spec.secondaryColor],
                startPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy),
                endPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy)))
        case .radial:
            return AnyShapeStyle(RadialGradient(
                colors: [spec.primaryColor, spec.secondaryColor],
                center: UnitPoint(x: 0.5, y: 0.38),
                startRadius: 0,
                endRadius: side * 0.72))
        }
    }

    /// The system folder icon, recoloured: a flat silhouette in the chosen fill,
    /// multiplied by a brightened greyscale copy so the tab and panel edges keep
    /// their shading.
    private var folderLayer: some View {
        let folder = Image(nsImage: Self.folderImage).resizable().interpolation(.high)
        return ZStack {
            Rectangle()
                .fill(fill)
                .mask { folder }
            folder
                .saturation(0)
                .contrast(1.15)
                .brightness(0.28)
                .blendMode(.multiply)
        }
        .compositingGroup()
        .frame(width: side, height: side)
    }

    /// A rounded square in the proportions Apple uses for macOS app icons
    /// (the shape fills about 80% of the canvas), with a soft shadow and an
    /// inner highlight along the top edge.
    private var squircleLayer: some View {
        let inner = side * 0.80
        let radius = inner * 0.2245
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return shape
            .fill(fill)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.0)],
                                   startPoint: .top, endPoint: .center),
                    lineWidth: max(0.5, inner * 0.012))
            }
            .shadow(color: .black.opacity(0.30), radius: side * 0.02, y: side * 0.012)
            .frame(width: inner, height: inner)
    }

    // MARK: Symbol

    private var symbolLayer: some View {
        let size = side * spec.symbolScale
        // The folder's front panel sits below centre, beneath the tab.
        let yOffset: CGFloat = spec.shape == .folder ? side * 0.07 : 0
        return Image(systemName: spec.symbolName)
            .symbolRenderingMode(.monochrome)
            .font(.system(size: size, weight: spec.symbolWeight))
            .foregroundStyle(spec.symbolColor)
            .opacity(spec.symbolOpacity)
            .shadow(color: .black.opacity(0.22), radius: side * 0.012, y: side * 0.01)
            .offset(y: yOffset)
    }
}
