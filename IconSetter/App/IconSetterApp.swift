import SwiftUI

@main
struct IconSetterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel.shared

    init() {
        #if SPARKLE
        SparkleUpdater.start()
        #endif
    }

    var body: some Scene {
        Window("Icon Setter", id: "main") {
            ContentView()
                .environment(model)
                .frame(minWidth: 940, minHeight: 620)
                .task { await model.loadCatalogsIfNeeded() }
        }
        .defaultSize(width: 1080, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Folders or Files…") { model.presentAddPanel() }
                    .keyboardShortcut("o")
            }
            CommandGroup(after: .pasteboard) {
                Button("Paste Image") { model.pasteImage() }
                    .keyboardShortcut("v", modifiers: [.command, .shift])
            }
            #if SPARKLE
            SparkleCommands()
            #endif
        }
    }
}
