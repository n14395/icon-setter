// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

/// Drop zone for using an image file (PNG, JPEG, SVG, PDF, ICNS…) as the icon.
struct ImageSourceView: View {
    @Environment(AppModel.self) private var model
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 16) {
            dropZone
            HStack {
                Button("Choose Image…") { model.presentImagePanel() }
                Button("Paste") { model.pasteImage() }
                    .help("Paste an image or an image file from the clipboard (⇧⌘V)")
                if model.importedImage != nil {
                    Button("Clear") {
                        model.importedImage = nil
                        model.importedImageURL = nil
                    }
                }
            }
            Text("PNG, JPEG, HEIC, TIFF, GIF, SVG, PDF and ICNS all work. Non-square images are centred on a transparent square canvas.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(.quaternary.opacity(0.4))
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                              style: StrokeStyle(lineWidth: isDropTargeted ? 3 : 1.5, dash: [8, 6]))

            if let image = model.importedImage {
                VStack(spacing: 10) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 260, maxHeight: 260)
                        .background(Checkerboard().clipShape(RoundedRectangle(cornerRadius: 8)))
                    VStack(spacing: 2) {
                        Text(model.importedImageURL?.lastPathComponent ?? "Pasted image")
                            .font(.callout)
                        let size = IconRenderer.pixelSize(of: image)
                        Text("\(Int(size.width)) × \(Int(size.height)) px")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("Drop an image here")
                        .font(.headline)
                }
            }
        }
        .frame(maxWidth: 520, maxHeight: 380)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            return model.importImage(from: url)
        } isTargeted: { isDropTargeted = $0 }
    }
}

/// Light checkerboard so transparent regions of an image are visible.
struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 8
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = 0
                var column = 0
                while x < size.width {
                    if (row + column) % 2 == 0 {
                        context.fill(Path(CGRect(x: x, y: y, width: cell, height: cell)),
                                     with: .color(.gray.opacity(0.18)))
                    }
                    x += cell
                    column += 1
                }
                y += cell
                row += 1
            }
        }
    }
}
