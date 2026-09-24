// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let servicesProvider = ServicesProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = servicesProvider
        NSUpdateDynamicServices()
    }

    /// Items dropped on the Dock icon or opened with "Open With".
    func application(_ application: NSApplication, open urls: [URL]) {
        AppModel.shared.addTargets(urls)
        Self.showMainWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    static func showMainWindow() {
        NSApp.activate()
        NSApp.windows.first { $0.canBecomeMain }?.makeKeyAndOrderFront(nil)
    }
}

/// Handles the "Set Custom Icon…" entry in Finder's Services menu.
final class ServicesProvider: NSObject {
    @objc func setCustomIcon(_ pasteboard: NSPasteboard, userData: String,
                             error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL],
              !urls.isEmpty else {
            error.pointee = "No files or folders were provided."
            return
        }
        MainActor.assumeIsolated {
            AppModel.shared.addTargets(urls)
            AppDelegate.showMainWindow()
        }
    }
}
