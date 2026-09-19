import SwiftUI
import AppKit
import Observation
import UniformTypeIdentifiers

struct StatusMessage: Equatable {
    var text: String
    var isError = false
}

/// All app state. Lives on the main actor because it holds AppKit images.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel()

    // Targets
    var targets: [TargetItem] = []

    // Icon source
    var sourceKind: IconSourceKind = .design {
        didSet { UserDefaults.standard.set(sourceKind.rawValue, forKey: Self.sourceKindKey) }
    }
    private static let sourceKindKey = "sourceKind"
    var design = GeneratedIconSpec()
    var selectedApp: AppEntry?
    var importedImage: NSImage?
    var importedImageURL: URL?

    // Catalogs
    var apps: [AppEntry] = []
    var isLoadingApps = false
    var symbolCatalog: SFSymbolCatalog = .empty
    var isLoadingSymbols = false

    // Feedback
    var status: StatusMessage?
    var isApplying = false

    /// Bumped after icons change so views re-read cached icons.
    private(set) var iconVersion = 0
    @ObservationIgnored private var iconCache: [String: NSImage] = [:]
    @ObservationIgnored private var catalogsRequested = false

    init() {
        if let saved = UserDefaults.standard.string(forKey: Self.sourceKindKey),
           let kind = IconSourceKind(rawValue: saved) {
            sourceKind = kind
        }
    }

    // MARK: Catalogs

    func loadCatalogsIfNeeded() async {
        guard !catalogsRequested else { return }
        catalogsRequested = true
        isLoadingSymbols = true
        isLoadingApps = true
        async let symbols = SFSymbolCatalog.load()
        async let apps = AppCatalog.scan()
        symbolCatalog = await symbols
        isLoadingSymbols = false
        self.apps = await apps
        isLoadingApps = false
    }

    // MARK: Targets

    func addTargets(_ urls: [URL]) {
        var added = 0
        for url in urls where url.isFileURL {
            let item = TargetItem(url: url)
            guard FileManager.default.fileExists(atPath: item.url.path) else { continue }
            guard !targets.contains(where: { $0.id == item.id }) else { continue }
            targets.append(item)
            added += 1
        }
        if added > 0 {
            status = StatusMessage(text: added == 1 ? "Added 1 item." : "Added \(added) items.")
        }
    }

    func removeTargets(ids: Set<String>) {
        targets.removeAll { ids.contains($0.id) }
    }

    func clearTargets() {
        targets.removeAll()
    }

    func presentAddPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.message = "Choose the folders or files that should get the icon."
        panel.prompt = "Add"
        if panel.runModal() == .OK {
            addTargets(panel.urls)
        }
    }

    /// The icon Finder currently shows for a target, cached until icons change.
    func currentIcon(for target: TargetItem) -> NSImage {
        let key = "\(iconVersion):\(target.id)"
        if let cached = iconCache[key] { return cached }
        let icon = NSWorkspace.shared.icon(forFile: target.url.path)
        iconCache[key] = icon
        return icon
    }

    func icon(forApp app: AppEntry) -> NSImage {
        let key = "app:\(app.id)"
        if let cached = iconCache[key] { return cached }
        let icon = NSWorkspace.shared.icon(forFile: app.url.path)
        iconCache[key] = icon
        return icon
    }

    private func invalidateTargetIcons() {
        iconCache = iconCache.filter { $0.key.hasPrefix("app:") }
        iconVersion += 1
    }

    // MARK: Source

    /// True when the current source pane has something to apply.
    var hasSource: Bool {
        switch sourceKind {
        case .design: true
        case .app: selectedApp != nil
        case .image: importedImage != nil
        }
    }

    /// Full-size preview image for the non-design sources.
    var sourcePreviewImage: NSImage? {
        switch sourceKind {
        case .design: nil
        case .app: selectedApp.map(icon(forApp:))
        case .image: importedImage
        }
    }

    func buildIcon() -> NSImage? {
        switch sourceKind {
        case .design:
            return IconRenderer.render(design)
        case .app:
            guard let app = selectedApp else { return nil }
            return IconRenderer.icon(from: icon(forApp: app))
        case .image:
            guard let image = importedImage else { return nil }
            return IconRenderer.icon(from: image)
        }
    }

    // MARK: Images

    static let importableTypes: [UTType] = [.image, .pdf, .svg, .icns]

    @discardableResult
    func importImage(from url: URL) -> Bool {
        guard let image = NSImage(contentsOf: url), image.isValid else {
            status = StatusMessage(text: "“\(url.lastPathComponent)” isn't an image Icon Setter can read.", isError: true)
            return false
        }
        importedImage = image
        importedImageURL = url
        sourceKind = .image
        status = nil
        return true
    }

    func presentImagePanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = Self.importableTypes
        panel.message = "Choose an image to use as the icon."
        if panel.runModal() == .OK, let url = panel.url {
            importImage(from: url)
        }
    }

    func pasteImage() {
        let pasteboard = NSPasteboard.general
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
           let url = urls.first, importImage(from: url) {
            return
        }
        if let image = NSImage(pasteboard: pasteboard), image.isValid {
            importedImage = image
            importedImageURL = nil
            status = nil
            return
        }
        status = StatusMessage(text: "The clipboard doesn't contain an image.", isError: true)
    }

    func presentAppPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Choose an application whose icon you want to use."
        if panel.runModal() == .OK, let url = panel.url {
            let entry = AppEntry(url: url)
            if !apps.contains(where: { $0.id == entry.id }) {
                apps.append(entry)
                apps.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            }
            selectedApp = entry
        }
    }

    // MARK: Applying

    func applyToTargets() {
        guard !targets.isEmpty else { return }
        guard let icon = buildIcon() else {
            status = StatusMessage(text: "Choose an icon source first.", isError: true)
            return
        }
        write(icon, verb: "Set")
    }

    func resetTargets() {
        guard !targets.isEmpty else { return }
        write(nil, verb: "Reset")
    }

    private func write(_ icon: NSImage?, verb: String) {
        isApplying = true
        defer { isApplying = false }

        var failures: [String] = []
        for target in targets {
            do {
                try IconApplier.apply(icon, to: target.url)
            } catch {
                failures.append(target.name)
            }
        }
        invalidateTargetIcons()

        let count = targets.count - failures.count
        let noun = count == 1 ? "item" : "items"
        if failures.isEmpty {
            status = StatusMessage(text: "\(verb) the icon on \(count) \(noun).")
        } else {
            status = StatusMessage(
                text: "\(verb) the icon on \(count) \(noun). Failed: \(failures.joined(separator: ", ")).",
                isError: true)
        }
    }
}
