import SwiftUI

/// Colour / gradient + SF Symbol editor. Controls on the left, symbol browser
/// on the right.
struct DesignEditorView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        HStack(spacing: 0) {
            controls(spec: $model.design)
                .frame(width: 330)
            Divider()
            SymbolPickerView(selection: $model.design.symbolName)
        }
    }

    private func controls(spec: Binding<GeneratedIconSpec>) -> some View {
        Form {
            Section("Shape") {
                Picker("Shape", selection: spec.shape) {
                    ForEach(IconShape.allCases) { shape in
                        Label(shape.label, systemImage: shape.systemImage).tag(shape)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Background") {
                Picker("Fill", selection: spec.fillStyle) {
                    ForEach(IconFillStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                ColorPicker("Colour", selection: spec.primaryColor, supportsOpacity: false)
                if spec.wrappedValue.fillStyle != .solid {
                    ColorPicker("Second colour", selection: spec.secondaryColor, supportsOpacity: false)
                    Button("Swap Colours", systemImage: "arrow.left.arrow.right") {
                        let primary = spec.wrappedValue.primaryColor
                        spec.wrappedValue.primaryColor = spec.wrappedValue.secondaryColor
                        spec.wrappedValue.secondaryColor = primary
                    }
                    .controlSize(.small)
                }
                if spec.wrappedValue.fillStyle == .linear {
                    LabeledContent("Angle") {
                        HStack {
                            Slider(value: spec.gradientAngle, in: 0...360, step: 5)
                            Text("\(Int(spec.wrappedValue.gradientAngle))°")
                                .monospacedDigit()
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
                presetSwatches(spec: spec)
            }

            Section("Symbol") {
                Toggle("Show symbol", isOn: spec.showSymbol)
                Group {
                    ColorPicker("Colour", selection: spec.symbolColor, supportsOpacity: false)
                    LabeledContent("Size") {
                        Slider(value: spec.symbolScale, in: 0.15...0.7)
                    }
                    Picker("Weight", selection: spec.symbolWeight) {
                        ForEach(Font.Weight.allCases) { weight in
                            Text(weight.label).tag(weight)
                        }
                    }
                    LabeledContent("Opacity") {
                        Slider(value: spec.symbolOpacity, in: 0.2...1)
                    }
                }
                .disabled(!spec.wrappedValue.showSymbol)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    /// One palette per fill style, 28 swatches drawn for the way that style
    /// paints. Each swatch previews exactly what tapping it produces.
    private func presetSwatches(spec: Binding<GeneratedIconSpec>) -> some View {
        let style = spec.wrappedValue.fillStyle
        let side: CGFloat = 26
        return VStack(alignment: .leading, spacing: 6) {
            Text("\(style.label) presets")
                .font(.callout)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: side + 2), spacing: 7)],
                      alignment: .leading, spacing: 7) {
                ForEach(GradientPreset.presets(for: style)) { preset in
                    Button {
                        spec.wrappedValue.apply(preset)
                    } label: {
                        Circle()
                            .fill(preset.fill(for: style, side: side))
                            .overlay(Circle().strokeBorder(.black.opacity(0.15), lineWidth: 0.5))
                            .frame(width: side, height: side)
                    }
                    .buttonStyle(.plain)
                    .help(preset.name)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
