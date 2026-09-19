import Foundation

/// A folder or file that will receive the icon.
struct TargetItem: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    let isDirectory: Bool

    var id: String { url.path }

    /// A shortened parent path for display, e.g. "~/Documents".
    var locationDescription: String {
        let parent = url.deletingLastPathComponent().path
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if parent == home { return "~" }
        if parent.hasPrefix(home + "/") { return "~" + parent.dropFirst(home.count) }
        return parent
    }

    init(url: URL) {
        let standardized = url.standardizedFileURL
        self.url = standardized
        self.name = FileManager.default.displayName(atPath: standardized.path)
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: standardized.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue
    }
}

/// Which of the three source panes provides the icon.
enum IconSourceKind: String, CaseIterable, Identifiable {
    case design
    case app
    case image

    var id: String { rawValue }

    var label: String {
        switch self {
        case .design: "Design"
        case .app: "App Icons"
        case .image: "Image File"
        }
    }

    var systemImage: String {
        switch self {
        case .design: "paintpalette"
        case .app: "app.badge"
        case .image: "photo"
        }
    }
}
