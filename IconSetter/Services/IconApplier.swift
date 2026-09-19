import AppKit

enum IconApplierError: LocalizedError {
    case failed(URL)

    var errorDescription: String? {
        switch self {
        case .failed(let url): "Couldn't set the icon for “\(url.lastPathComponent)”."
        }
    }
}

/// Writes (or removes) a custom icon on a file or folder.
@MainActor
enum IconApplier {
    /// Pass `nil` to remove the custom icon and restore the default.
    static func apply(_ icon: NSImage?, to url: URL) throws {
        guard NSWorkspace.shared.setIcon(icon, forFile: url.path, options: []) else {
            throw IconApplierError.failed(url)
        }
        NSWorkspace.shared.noteFileSystemChanged(url.path)
    }

    /// Reads the Finder flags in the `com.apple.FinderInfo` attribute and checks
    /// the custom-icon bit (0x0400 in the flags word at bytes 8–9).
    nonisolated static func hasCustomIcon(_ url: URL) -> Bool {
        var buffer = [UInt8](repeating: 0, count: 32)
        let length = getxattr(url.path, "com.apple.FinderInfo", &buffer, buffer.count, 0, 0)
        guard length >= 10 else { return false }
        let flags = UInt16(buffer[8]) << 8 | UInt16(buffer[9])
        return flags & 0x0400 != 0
    }
}
