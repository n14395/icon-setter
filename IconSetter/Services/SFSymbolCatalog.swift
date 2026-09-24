// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import Foundation

struct SFSymbol: Identifiable, Hashable, Sendable {
    let name: String
    let categories: [String]
    /// The name with dots as spaces, so "star fill" matches "star.fill".
    let nameText: String
    /// `nameText` plus the system's search keywords, lower-cased.
    let searchText: String

    var id: String { name }
}

struct SFSymbolCategory: Identifiable, Hashable, Sendable {
    let key: String
    let label: String
    let systemImage: String

    var id: String { key }
}

/// The SF Symbols shipped with this copy of macOS, read from the system's own
/// glyph catalog so the list always matches what the OS can actually draw.
struct SFSymbolCatalog: Sendable {
    let symbols: [SFSymbol]
    let categories: [SFSymbolCategory]

    static let empty = SFSymbolCatalog(symbols: [], categories: [])

    private static let resourcesURL = URL(fileURLWithPath:
        "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources")

    /// Localised variants of symbols (Arabic, Hindi, Japanese…) are hidden; the
    /// base symbol is what people expect to find.
    private static let localeSuffixes: Set<String> = [
        "ar", "hi", "he", "zh", "th", "ja", "ko", "ml", "kn", "bn", "gu", "or", "mr",
        "te", "pa", "ta", "si", "el", "ru", "my", "km", "rtl", "ltr", "traditional",
    ]

    private static let categoryLabels: [String: String] = [
        "communication": "Communication", "weather": "Weather", "maps": "Maps",
        "objectsandtools": "Objects & Tools", "devices": "Devices",
        "cameraandphotos": "Camera & Photos", "gaming": "Gaming",
        "connectivity": "Connectivity", "transportation": "Transportation",
        "automotive": "Automotive", "accessibility": "Accessibility",
        "privacyandsecurity": "Privacy & Security", "human": "Human", "home": "Home",
        "fitness": "Fitness", "nature": "Nature", "editing": "Editing",
        "textformatting": "Text Formatting", "media": "Media", "keyboard": "Keyboard",
        "commerce": "Commerce", "time": "Time", "health": "Health", "shapes": "Shapes",
        "arrows": "Arrows", "indices": "Indices", "math": "Math",
    ]

    /// Pseudo-categories in the system list that are not useful as filters.
    private static let hiddenCategories: Set<String> = ["all", "whatsnew", "draw", "variable", "multicolor"]

    static func load() async -> SFSymbolCatalog {
        await Task.detached(priority: .userInitiated) { loadSync() }.value
    }

    nonisolated static func loadSync() -> SFSymbolCatalog {
        func plist(_ name: String) -> Any? {
            guard let data = try? Data(contentsOf: resourcesURL.appending(path: name)) else { return nil }
            return try? PropertyListSerialization.propertyList(from: data, format: nil)
        }

        guard let availability = plist("name_availability.plist") as? [String: Any],
              let names = availability["symbols"] as? [String: Any] else {
            return .empty
        }
        let keywords = plist("symbol_search.plist") as? [String: [String]] ?? [:]
        let categoryMembership = plist("symbol_categories.plist") as? [String: [String]] ?? [:]

        var order: [String: Int] = [:]
        if let ordered = plist("symbol_order.plist") as? [String] {
            for (index, name) in ordered.enumerated() { order[name] = index }
        }

        var symbols: [SFSymbol] = []
        symbols.reserveCapacity(names.count)
        for name in names.keys {
            let parts = name.split(separator: ".")
            if parts.count > 1, let last = parts.last, localeSuffixes.contains(String(last)) { continue }
            let nameText = name.replacingOccurrences(of: ".", with: " ")
            let searchText = ([nameText] + (keywords[name] ?? [])).joined(separator: " ").lowercased()
            symbols.append(SFSymbol(name: name, categories: categoryMembership[name] ?? [],
                                    nameText: nameText, searchText: searchText))
        }
        // Alphabetical, but with the numeric symbols ("0.circle", "1.square"…)
        // after everything else so the grid opens on recognisable glyphs.
        symbols.sort { a, b in
            let aDigit = a.name.first?.isNumber == true
            let bDigit = b.name.first?.isNumber == true
            if aDigit != bDigit { return !aDigit }
            switch (order[a.name], order[b.name]) {
            case let (x?, y?): return x < y
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return a.name < b.name
            }
        }

        var categories: [SFSymbolCategory] = []
        if let list = plist("categories.plist") as? [[String: String]] {
            for item in list {
                guard let key = item["key"], !hiddenCategories.contains(key) else { continue }
                categories.append(SFSymbolCategory(
                    key: key,
                    label: categoryLabels[key] ?? key.capitalized,
                    systemImage: item["icon"] ?? "square.grid.2x2"))
            }
        }
        return SFSymbolCatalog(symbols: symbols, categories: categories)
    }

    /// Filters by category and ranks matches: exact name, then name prefix,
    /// then name substring, then every word in the name, then keyword matches.
    /// Ties go to shorter (more specific) names, then catalog order.
    func search(_ rawQuery: String, category: String?) -> [SFSymbol] {
        var pool = symbols
        if let category { pool = pool.filter { $0.categories.contains(category) } }

        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return pool }
        let spaced = query.replacingOccurrences(of: ".", with: " ")
        let tokens = spaced.split(separator: " ").map(String.init)

        var scored: [(score: Int, length: Int, index: Int, symbol: SFSymbol)] = []
        for (index, symbol) in pool.enumerated() {
            let name = symbol.nameText
            let score: Int
            if name == spaced {
                score = 0
            } else if name.hasPrefix(spaced) {
                score = 1
            } else if name.contains(spaced) {
                score = 2
            } else if tokens.allSatisfy({ name.contains($0) }) {
                score = 3
            } else if tokens.allSatisfy({ symbol.searchText.contains($0) }) {
                score = 4
            } else {
                continue
            }
            scored.append((score, name.count, index, symbol))
        }
        return scored
            .sorted { ($0.score, $0.length, $0.index) < ($1.score, $1.length, $1.index) }
            .map(\.symbol)
    }
}
