import SwiftUI

/// The overall silhouette of a generated icon.
enum IconShape: String, CaseIterable, Identifiable {
    /// The system folder icon, recoloured, with the symbol on its front panel.
    case folder
    /// A macOS app-icon style rounded square.
    case squircle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .folder: "Folder"
        case .squircle: "Squircle"
        }
    }

    var systemImage: String {
        switch self {
        case .folder: "folder.fill"
        case .squircle: "app.fill"
        }
    }
}

/// How the background of a generated icon is painted.
enum IconFillStyle: String, CaseIterable, Identifiable {
    case solid
    case linear
    case radial

    var id: String { rawValue }

    var label: String {
        switch self {
        case .solid: "Solid"
        case .linear: "Linear"
        case .radial: "Radial"
        }
    }
}

/// A named two-colour preset shown as a swatch in the editor.
struct GradientPreset: Identifiable, Equatable {
    let name: String
    let primary: Color
    let secondary: Color
    var id: String { name }

    static let all: [GradientPreset] = [
        .init(name: "Blue", primary: Color(red: 0.36, green: 0.66, blue: 1.00), secondary: Color(red: 0.05, green: 0.36, blue: 0.92)),
        .init(name: "Indigo", primary: Color(red: 0.55, green: 0.50, blue: 1.00), secondary: Color(red: 0.26, green: 0.20, blue: 0.82)),
        .init(name: "Purple", primary: Color(red: 0.80, green: 0.48, blue: 1.00), secondary: Color(red: 0.48, green: 0.16, blue: 0.80)),
        .init(name: "Pink", primary: Color(red: 1.00, green: 0.50, blue: 0.75), secondary: Color(red: 0.88, green: 0.14, blue: 0.45)),
        .init(name: "Red", primary: Color(red: 1.00, green: 0.48, blue: 0.42), secondary: Color(red: 0.80, green: 0.10, blue: 0.12)),
        .init(name: "Orange", primary: Color(red: 1.00, green: 0.72, blue: 0.30), secondary: Color(red: 0.95, green: 0.40, blue: 0.05)),
        .init(name: "Yellow", primary: Color(red: 1.00, green: 0.90, blue: 0.40), secondary: Color(red: 0.95, green: 0.68, blue: 0.05)),
        .init(name: "Green", primary: Color(red: 0.45, green: 0.90, blue: 0.55), secondary: Color(red: 0.10, green: 0.60, blue: 0.28)),
        .init(name: "Teal", primary: Color(red: 0.40, green: 0.90, blue: 0.90), secondary: Color(red: 0.05, green: 0.55, blue: 0.62)),
        .init(name: "Graphite", primary: Color(red: 0.62, green: 0.64, blue: 0.68), secondary: Color(red: 0.25, green: 0.27, blue: 0.31)),
        .init(name: "Midnight", primary: Color(red: 0.30, green: 0.34, blue: 0.48), secondary: Color(red: 0.08, green: 0.09, blue: 0.18)),
        .init(name: "Sand", primary: Color(red: 0.96, green: 0.86, blue: 0.68), secondary: Color(red: 0.76, green: 0.58, blue: 0.36)),
    ]
}

/// Everything needed to draw a colour + SF Symbol icon. Pure value type so the
/// live preview and the final renderer draw exactly the same thing.
struct GeneratedIconSpec: Equatable {
    var shape: IconShape = .folder
    var fillStyle: IconFillStyle = .linear
    var primaryColor: Color = GradientPreset.all[0].primary
    var secondaryColor: Color = GradientPreset.all[0].secondary
    /// Direction of a linear gradient in degrees. 0 runs left to right, 90 top to bottom.
    var gradientAngle: Double = 90

    var showSymbol: Bool = true
    var symbolName: String = "star.fill"
    var symbolColor: Color = .white
    /// Symbol point size as a fraction of the icon's side length.
    var symbolScale: Double = 0.40
    var symbolWeight: Font.Weight = .semibold
    var symbolOpacity: Double = 1.0

    mutating func apply(_ preset: GradientPreset) {
        primaryColor = preset.primary
        secondaryColor = preset.secondary
        if fillStyle == .solid { fillStyle = .linear }
    }
}

extension Font.Weight: @retroactive CaseIterable, @retroactive Identifiable {
    public static var allCases: [Font.Weight] { [.light, .regular, .medium, .semibold, .bold, .heavy, .black] }
    public var id: String { label }

    var label: String {
        switch self {
        case .ultraLight: "Ultra Light"
        case .thin: "Thin"
        case .light: "Light"
        case .regular: "Regular"
        case .medium: "Medium"
        case .semibold: "Semibold"
        case .bold: "Bold"
        case .heavy: "Heavy"
        case .black: "Black"
        default: "Regular"
        }
    }
}
