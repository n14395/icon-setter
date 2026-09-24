// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationSplitView {
            TargetsSidebar()
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 420)
        } detail: {
            SourceEditor()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Folders or Files…", systemImage: "plus") {
                    model.presentAddPanel()
                }
                .help("Add folders or files to give an icon (⌘O)")
            }
        }
    }
}

/// The right-hand pane: source picker, the editor for that source, and the
/// preview / apply bar along the bottom.
struct SourceEditor: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            Picker("Source", selection: $model.sourceKind) {
                ForEach(IconSourceKind.allCases) { kind in
                    Label(kind.label, systemImage: kind.systemImage).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 420)
            .padding(.vertical, 12)

            Divider()

            Group {
                switch model.sourceKind {
                case .design: DesignEditorView()
                case .app: AppIconPickerView()
                case .image: ImageSourceView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            PreviewBar()
        }
    }
}
