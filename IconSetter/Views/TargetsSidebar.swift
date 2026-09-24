// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

/// Left column: the folders and files that will receive the icon.
struct TargetsSidebar: View {
    @Environment(AppModel.self) private var model
    @State private var selection = Set<String>()
    @State private var isDropTargeted = false

    var body: some View {
        Group {
            if model.targets.isEmpty {
                emptyState
            } else {
                targetList
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            model.addTargets(urls)
            return true
        } isTargeted: { isDropTargeted = $0 }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
                    .padding(6)
                    .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .bottom) { footer }
        .navigationTitle("Targets")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
            Text("Drop folders or files here")
                .font(.headline)
            Text("Or use the + button. You can also right-click an item in Finder and choose Services › Set Custom Icon…")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var targetList: some View {
        List(selection: $selection) {
            ForEach(model.targets) { target in
                TargetRow(target: target)
                    .tag(target.id)
                    .contextMenu {
                        Button("Show in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([target.url])
                        }
                        Button("Remove", role: .destructive) {
                            model.removeTargets(ids: [target.id])
                        }
                    }
            }
        }
        .onDeleteCommand {
            model.removeTargets(ids: selection)
            selection.removeAll()
        }
    }

    private var footer: some View {
        HStack {
            Text(model.targets.count == 1 ? "1 item" : "\(model.targets.count) items")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            if !model.targets.isEmpty {
                Button("Clear") {
                    model.clearTargets()
                    selection.removeAll()
                }
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

private struct TargetRow: View {
    @Environment(AppModel.self) private var model
    let target: TargetItem

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: model.currentIcon(for: target))
                .resizable()
                .interpolation(.high)
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(target.name)
                    .lineLimit(1)
                Text(target.locationDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
            if IconApplier.hasCustomIcon(target.url) {
                Image(systemName: "paintbrush.pointed.fill")
                    .foregroundStyle(.secondary)
                    .help("Has a custom icon")
            }
        }
        .padding(.vertical, 2)
        // Re-evaluate the custom-icon badge whenever icons change.
        .id("\(target.id)-\(model.iconVersion)")
    }
}
