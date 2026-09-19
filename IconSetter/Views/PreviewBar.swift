import SwiftUI

/// Bottom bar: the icon at Finder's common sizes, status text, and the
/// Reset / Apply buttons.
struct PreviewBar: View {
    @Environment(AppModel.self) private var model

    private let previewSizes: [CGFloat] = [128, 64, 32, 16]

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(previewSizes, id: \.self) { side in
                    preview(side: side)
                }
            }
            .frame(height: 128)

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                if let status = model.status {
                    Text(status.text)
                        .font(.callout)
                        .foregroundStyle(status.isError ? Color.red : Color.secondary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(3)
                        .frame(maxWidth: 360, alignment: .trailing)
                }
                HStack(spacing: 10) {
                    Button("Reset to Default Icon") { model.resetTargets() }
                        .disabled(model.targets.isEmpty || model.isApplying)
                        .help("Remove the custom icon from every target")
                    Button(applyTitle) { model.applyToTargets() }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .disabled(model.targets.isEmpty || !model.hasSource || model.isApplying)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.bar)
    }

    private var applyTitle: String {
        switch model.targets.count {
        case 0: "Apply Icon"
        case 1: "Apply to 1 Item"
        default: "Apply to \(model.targets.count) Items"
        }
    }

    @ViewBuilder
    private func preview(side: CGFloat) -> some View {
        switch model.sourceKind {
        case .design:
            IconArtworkView(spec: model.design, side: side)
        case .app, .image:
            if let image = model.sourcePreviewImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: side, height: side)
            } else {
                RoundedRectangle(cornerRadius: side * 0.2)
                    .strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .frame(width: side, height: side)
            }
        }
    }
}
