import Foundation

/// An application bundle found on this Mac.
struct AppEntry: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String

    var id: String { url.path }

    init(url: URL) {
        self.url = url
        var name = FileManager.default.displayName(atPath: url.path)
        if name.lowercased().hasSuffix(".app") { name.removeLast(4) }
        self.name = name
    }
}

/// Finds app bundles in the usual places so their icons can be browsed.
enum AppCatalog {
    private static let roots: [(url: URL, depth: Int, requireIcon: Bool)] = [
        (URL(fileURLWithPath: "/Applications"), 2, false),
        (URL(fileURLWithPath: "/System/Applications"), 2, false),
        (URL(fileURLWithPath: "/System/Library/CoreServices"), 1, true),
        (URL(fileURLWithPath: "/System/Library/CoreServices/Applications"), 1, false),
        (FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications"), 2, false),
    ]

    static func scan() async -> [AppEntry] {
        await Task.detached(priority: .userInitiated) { scanSync() }.value
    }

    nonisolated static func scanSync() -> [AppEntry] {
        var seen = Set<String>()
        var entries: [AppEntry] = []

        func visit(_ directory: URL, depth: Int, requireIcon: Bool) {
            guard depth >= 0 else { return }
            let keys: [URLResourceKey] = [.isDirectoryKey, .isApplicationKey, .isSymbolicLinkKey]
            guard let children = try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]
            ) else { return }

            for child in children {
                let values = try? child.resourceValues(forKeys: Set(keys))
                let isApp = child.pathExtension == "app" || values?.isApplication == true
                if isApp {
                    let path = child.standardizedFileURL.path
                    guard !seen.contains(path) else { continue }
                    if requireIcon && !looksLikeRealApp(child) { continue }
                    seen.insert(path)
                    entries.append(AppEntry(url: child))
                } else if values?.isDirectory == true, values?.isSymbolicLink != true {
                    visit(child, depth: depth - 1, requireIcon: requireIcon)
                }
            }
        }

        for root in roots {
            visit(root.url, depth: root.depth, requireIcon: root.requireIcon)
        }
        return entries.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// CoreServices is full of faceless helper apps; only keep ones that ship
    /// an icon and present a user interface.
    private nonisolated static func looksLikeRealApp(_ url: URL) -> Bool {
        guard let info = Bundle(url: url)?.infoDictionary else { return false }
        let hasIcon = info["CFBundleIconFile"] != nil || info["CFBundleIconName"] != nil
        let isAgent = (info["LSUIElement"] as? Bool) == true
            || (info["LSUIElement"] as? String) == "1"
            || (info["LSBackgroundOnly"] as? Bool) == true
            || (info["LSBackgroundOnly"] as? String) == "1"
        return hasIcon && !isAgent
    }
}
