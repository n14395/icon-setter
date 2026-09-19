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

/// A named preset shown as a swatch in the editor. `primary` is the colour a
/// solid fill uses, the start of a linear gradient, and the centre of a radial
/// one; `secondary` is the other end. Every preset belongs to exactly one fill
/// style, so each style offers a palette drawn for the way it paints.
struct GradientPreset: Identifiable, Equatable {
    let name: String
    let primary: Color
    let secondary: Color
    let style: IconFillStyle

    var id: String { "\(style.rawValue).\(name)" }

    init(_ style: IconFillStyle, _ name: String, _ primary: UInt32, _ secondary: UInt32) {
        self.style = style
        self.name = name
        self.primary = Color(hex: primary)
        self.secondary = Color(hex: secondary)
    }

    static func presets(for style: IconFillStyle) -> [GradientPreset] {
        switch style {
        case .solid: solids
        case .linear: linears
        case .radial: radials
        }
    }

    /// How the preset paints under a given fill style, so a swatch shows what
    /// tapping it produces rather than always showing a gradient.
    func fill(for style: IconFillStyle, side: CGFloat) -> AnyShapeStyle {
        switch style {
        case .solid:
            AnyShapeStyle(primary)
        case .linear:
            AnyShapeStyle(LinearGradient(colors: [primary, secondary], startPoint: .top, endPoint: .bottom))
        case .radial:
            AnyShapeStyle(RadialGradient(colors: [primary, secondary],
                                         center: UnitPoint(x: 0.5, y: 0.38),
                                         startRadius: 0, endRadius: side * 0.72))
        }
    }

    /// Flat colours: eleven hues, a dozen muted earth tones, then five
    /// neutrals. A solid fill paints `primary`; `secondary` is a deeper shade
    /// of the same colour, so switching such a preset to a gradient still works.
    static let solids: [GradientPreset] = [
        .init(.solid, "Blue",     0x5CA8FF, 0x0D5CEB),
        .init(.solid, "Indigo",   0x8C80FF, 0x4233D1),
        .init(.solid, "Purple",   0xCC7AFF, 0x7A29CC),
        .init(.solid, "Fuchsia",  0xD6249B, 0x8A0F63),
        .init(.solid, "Pink",     0xFF80BF, 0xE02473),
        .init(.solid, "Red",      0xFF7A6B, 0xCC1A1F),
        .init(.solid, "Orange",   0xFFB84D, 0xF2660D),
        .init(.solid, "Yellow",   0xFFE666, 0xF2AD0D),
        .init(.solid, "Lime",     0xA8D93D, 0x6E9414),
        .init(.solid, "Green",    0x73E68C, 0x1A9947),
        .init(.solid, "Teal",     0x66E6E6, 0x0D8C9E),

        .init(.solid, "Slate",    0x64748B, 0x3C4657),
        .init(.solid, "Denim",    0x4A6FA5, 0x2C4568),
        .init(.solid, "Sage",     0x9CAF88, 0x6E8460),
        .init(.solid, "Moss",     0x5F7A4F, 0x3A4C31),
        .init(.solid, "Olive",    0x8A8B4F, 0x5C5D31),
        .init(.solid, "Clay",     0xC08268, 0x8C5741),
        .init(.solid, "Rust",     0xA8503A, 0x6E3223),
        .init(.solid, "Blush",    0xE3AFB0, 0xB87E80),
        .init(.solid, "Plum",     0x7D5A7D, 0x4E354E),
        .init(.solid, "Mauve",    0xA08CAE, 0x6F5E7C),
        .init(.solid, "Espresso", 0x6B5344, 0x403026),
        .init(.solid, "Oat",      0xDCD3C0, 0xA99C82),

        .init(.solid, "Snow",     0xF2F4F8, 0xC9CEDB),
        .init(.solid, "Sand",     0xF5DBAD, 0xC2945C),
        .init(.solid, "Graphite", 0x9EA3AD, 0x40454F),
        .init(.solid, "Midnight", 0x4D577A, 0x14172E),
        .init(.solid, "Ink",      0x1B1D2A, 0x0B0C14),
    ]

    /// Cross-hue blends that travel a long way round the wheel, and ramps that
    /// fall from a lit colour to a near-black one.
    static let linears: [GradientPreset] = [
        .init(.linear, "Sunset",          0xFF9F45, 0xE0367A),
        .init(.linear, "Ember",           0xFFD166, 0xC21E3A),
        .init(.linear, "Coral Reef",      0xFF7E6B, 0x0B6E7A),
        .init(.linear, "Aurora",          0x2EE6A8, 0x3B4FD9),
        .init(.linear, "Lagoon",          0x7FE9D0, 0x1B5FA8),
        .init(.linear, "Deep Sea",        0x45E0C8, 0x2D1B69),
        .init(.linear, "Nebula",          0xFF6FD8, 0x3813C2),
        .init(.linear, "Dusk",            0xFFB86B, 0x5B3FA8),
        .init(.linear, "Meadow",          0xC8E85A, 0xE86FA0),
        .init(.linear, "Fern & Rose",     0x3FA86B, 0xFF9FB5),
        .init(.linear, "Twilight",        0xF2A0C0, 0x46568F),
        .init(.linear, "Peach & Plum",    0xFFB49A, 0x7A3E8F),

        .init(.linear, "Vaporwave",       0x22D3EE, 0xE11D8F),
        .init(.linear, "Acid",            0xCCFF00, 0x00A3FF),
        .init(.linear, "Solar Flare",     0xFFE600, 0xFF1E00),
        .init(.linear, "Citrus",          0xA3E635, 0xF97316),
        .init(.linear, "Grape Soda",      0x7C3AED, 0xEC4899),
        .init(.linear, "Neon",            0x39FF6A, 0x0066FF),
        .init(.linear, "Cotton Candy",    0xFF9AE5, 0x7DD3FC),
        .init(.linear, "Peacock",         0x00D4FF, 0x7B2CBF),
        .init(.linear, "Electric Violet", 0xC026D3, 0x2563EB),
        .init(.linear, "Mango Tango",     0xFFC93C, 0xFF3366),
        .init(.linear, "Tidal",           0x00FFA3, 0x004E92),
        .init(.linear, "Inferno",         0xFDE047, 0x4A0404),
        .init(.linear, "Arctic",          0xE0F2FE, 0x0C1E5B),
        .init(.linear, "Blackcurrant",    0xF472B6, 0x1E1B4B),
        .init(.linear, "Jungle",          0xA7F432, 0x065F46),
        .init(.linear, "Nightfall",       0xFF7A00, 0x0B0B2B),
    ]

    /// Built for the way a radial fill works: a lit core falling away to a deep
    /// rim, so the icon glows from the middle.
    static let radials: [GradientPreset] = [
        .init(.radial, "Solar",       0xFFE04D, 0xE33A0F),
        .init(.radial, "Magma",       0xFFC12E, 0x7A0B1E),
        .init(.radial, "Copper",      0xFFB86B, 0x6E2E12),
        .init(.radial, "Eclipse",     0xFF9A3C, 0x14092B),
        .init(.radial, "Supernova",   0xFFE58F, 0xD6156B),
        .init(.radial, "Rose Quartz", 0xFFC2D4, 0x8A2E63),
        .init(.radial, "Jellyfish",   0xFF9AE0, 0x3B1259),
        .init(.radial, "Halo",        0xD9CCFF, 0x2D1B69),
        .init(.radial, "Ripple",      0x8FD9FF, 0x0E2A6B),
        .init(.radial, "Firefly",     0xB8FF7A, 0x06231C),
        .init(.radial, "Oasis",       0xB9F542, 0x0A5C4F),
        .init(.radial, "Moonrise",    0xEDE7D6, 0x2E3A5C),

        .init(.radial, "Quasar",      0xFFFFFF, 0x6A0DAD),
        .init(.radial, "Ice Core",    0xFFFFFF, 0x0B3D91),
        .init(.radial, "Flashbulb",   0xFFFFFF, 0x1A1A1A),
        .init(.radial, "Cherry Bomb", 0xFFFFFF, 0xB00020),
        .init(.radial, "Plasma",      0xFF4FD8, 0x14002E),
        .init(.radial, "Ion",         0x8FFFF2, 0x04184A),
        .init(.radial, "Forge",       0xFFAE42, 0x2B0A00),
        .init(.radial, "Beacon",      0xD4FF4F, 0x1A2E05),
        .init(.radial, "Anemone",     0xFFA8C8, 0x6A1B4D),
        .init(.radial, "Emerald",     0x6EFFB0, 0x00381F),
        .init(.radial, "Frost",       0xF0FBFF, 0x2C4A6B),
        .init(.radial, "Void",        0x9B8CFF, 0x05010F),
        .init(.radial, "Seaglass",    0xA8FFE8, 0x04463F),
        .init(.radial, "Blaze",       0xFFF07A, 0xD62828),
        .init(.radial, "Iris",        0xE0C3FC, 0x4A00E0),
        .init(.radial, "Rosewood",    0xFFD4D4, 0x5C0A0A),
    ]
}

extension Color {
    /// 0xRRGGBB, so a palette reads as a table.
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// Everything needed to draw a colour + SF Symbol icon. Pure value type so the
/// live preview and the final renderer draw exactly the same thing.
struct GeneratedIconSpec: Equatable {
    var shape: IconShape = .folder
    var fillStyle: IconFillStyle = .linear
    var primaryColor: Color = GradientPreset.solids[0].primary   // Blue
    var secondaryColor: Color = GradientPreset.solids[0].secondary
    /// Direction of a linear gradient in degrees. 0 runs left to right, 90 top to bottom.
    var gradientAngle: Double = 90

    var showSymbol: Bool = true
    var symbolName: String = "star.fill"
    var symbolColor: Color = .white
    /// Symbol point size as a fraction of the icon's side length.
    var symbolScale: Double = 0.40
    var symbolWeight: Font.Weight = .semibold
    var symbolOpacity: Double = 1.0

    /// Swatches are offered per fill style, so applying one changes the colours
    /// and leaves the style the user picked alone.
    mutating func apply(_ preset: GradientPreset) {
        primaryColor = preset.primary
        secondaryColor = preset.secondary
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
